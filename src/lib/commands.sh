#!/bin/bash
################################################################################
# commands.sh — Routage et dispatch des commandes
# Contient : cmd_init(), cmd_save(), cmd_log(), cmd_restore(), run_command()
#
# MODIFICATIONS (Système de description/message) :
#
#   cmd_save()    → Enregistre SNAP_MESSAGE dans le fichier .meta du snapshot
#   cmd_log()     → Affiche la description de chaque snapshot dans l'historique
#   cmd_restore() → Affiche la description du snapshot avant de restaurer
#
#   cmd_save()    → Sprint 2 (Membre 2)
#   cmd_log()     → Sprint 3 (Membre 3)
#   cmd_restore() → Sprint 3 (Membre 3)
#
# FORMAT DU FICHIER .meta (étendu) :
#   source_dir=/chemin/vers/dossier
#   description=Mon message ici
#   date=2026-05-12
#   author=safa
#   <chemin_relatif> <hash_sha256>
#   ...
################################################################################
export HOME=$HOME

# ============================================================================
# FONCTION : cmd_init()
# Initialise manuellement le dépôt SnapFile
# Usage : ./snapfile.sh init
# (non modifiée dans ce sprint)
# ============================================================================
cmd_init() {
    log_event "INFOS" "COMMAND: init"

    # Vérifier si le dépôt est complet (dossier + sous-dossiers)
    if [[ -d "$SNAPFILE_DIR" ]] && [[ -d "$OBJECTS_DIR" ]] && [[ -d "$SNAPSHOTS_DIR" ]] && [[ -d "$INDEX_DIR" ]]; then
        echo "Le dépôt SnapFile existe déjà : $SNAPFILE_DIR"
        echo ""
        echo "Structure actuelle :"
        ls -lh "$SNAPFILE_DIR"
        echo ""
        echo "Snapshots : $(ls "$SNAPSHOTS_DIR" 2>/dev/null | wc -l) fichier(s)"
        echo "Objets    : $(ls "$OBJECTS_DIR" 2>/dev/null | wc -l) fichier(s)"
        echo "Index     : $(ls "$INDEX_DIR" 2>/dev/null | wc -l) fichier(s)"
        log_event "INFOS" "Repository already exists at $SNAPFILE_DIR"
    else
        # Dépôt inexistant ou incomplet → (re)créer la structure complète
        if [[ -d "$SNAPFILE_DIR" ]]; then
            echo "Dépôt incomplet détecté. Création des dossiers manquants..."
        fi
        init_repository
        echo "Dépôt SnapFile initialisé avec succès !"
        echo ""
        echo "📁 Structure créée :"
        echo "   $SNAPFILE_DIR/"
        echo "   ├── objects/     (stockage des fichiers compressés)"
        echo "   ├── snapshots/   (métadonnées des sauvegardes)"
        echo "   └── index/       (index par projet)"
        echo ""
        echo "Vous pouvez maintenant utiliser : ./snapfile.sh save <dossier>"
    fi
}



# ============================================================================
# FONCTION : cmd_save()
# Sauvegarde un dossier sous forme de snapshot
# Variables utilisées : $TARGET_DIR, $OPT_FORK, $OPT_THREAD, $SNAP_MESSAGE
#
# MODIFICATIONS (Sprint 4) :
#   - Lecture de la variable $SNAP_MESSAGE (définie dans parse_options)
#   - Écriture de la description, date et auteur dans le fichier .meta
#   - Format ajouté au début du .meta :
#       source_dir=...
#       description=...
#       date=...
#       author=...
# ============================================================================
cmd_save() {
    log_event "INFOS" "COMMAND: save $TARGET_DIR (message: $SNAP_MESSAGE)"

    # =========================
    # Vérifier espace disque
    # =========================
    local avail_space
    avail_space=$(df -k "$TARGET_DIR" | tail -1 | awk '{print $4}')
    [ "$avail_space" -lt 51200 ] && die 104 "Espace insuffisant"

    # =========================
    # Snapshot ID (horodatage)
    # =========================
    local snap_id
    snap_id=$(date '+%Y%m%d%H%M%S')

    local meta_file="$SNAPSHOTS_DIR/${snap_id}.meta"
    local tmpfile
    tmpfile=$(mktemp) || die 107 "Impossible de créer un fichier temporaire"

    find "$TARGET_DIR" -type f > "$tmpfile"

    # -----------------------------------------------------------------------
    # NOUVEAU : En-tête du fichier .meta avec métadonnées enrichies
    # On écrit : source_dir, description, date lisible, auteur
    # -----------------------------------------------------------------------
    local snap_date
    snap_date=$(date '+%Y-%m-%d %H:%M:%S')
    local snap_author
    snap_author=$(whoami)

    {
        echo "source_dir=$TARGET_DIR"
        echo "description=${SNAP_MESSAGE}"
        echo "date=${snap_date}"
        echo "author=${snap_author}"
    } > "$meta_file"
    # -----------------------------------------------------------------------

    local files_count=0
    local total_size=0

    # =========================
    # Fonction de traitement
    # =========================
    process_file() {
        # On reçoit un lot de fichiers en arguments
        for file in "$@"; do
            [ ! -f "$file" ] && continue

            local hash
            hash=$(sha256sum "$file" | awk '{print $1}')

            local obj_path="$OBJECTS_DIR/${hash}.gz"

            local file_size
            file_size=$(stat -c%s "$file")

            # Compression si besoin (déduplication par hash)
            if [ ! -f "$obj_path" ]; then
                gzip -c "$file" > "$obj_path" || continue
            fi

            local relative_path="${file#$TARGET_DIR/}"

            # Écrire dans meta (SAFE avec lock pour le parallélisme)
            (
                flock 200
                echo "$relative_path $hash" >> "$meta_file"
            ) 200>"$meta_file.lock"

            echo "$file_size" >> "/tmp/snap_${snap_id}.size"
        done
    }

    export -f process_file
    export TARGET_DIR OBJECTS_DIR meta_file snap_id

    # =========================
    # MODE FORK (-f)
    # =========================
    if [ "$OPT_FORK" -eq 1 ]; then
        echo "🚀 Mode FORK (C-Worker par lots de 5)"

        if [ ! -f "$SCRIPT_DIR/lib/fork_worker" ]; then
            gcc -O3 "$SCRIPT_DIR/lib/fork_worker.c" -o "$SCRIPT_DIR/lib/fork_worker" \
                || die 106 "Échec de compilation du fork_worker (gcc requis)"
        fi

        export -f process_file
        export TARGET_DIR OBJECTS_DIR meta_file snap_id
        "$SCRIPT_DIR/lib/fork_worker" "$tmpfile"

    # =========================
    # MODE THREAD (-t)
    # =========================
    elif [ "$OPT_THREAD" -eq 1 ]; then
        echo "🧵 Mode THREAD (C-Worker avec pthread)"

        if [ ! -f "$SCRIPT_DIR/lib/thread_worker" ]; then
            gcc -O3 "$SCRIPT_DIR/lib/thread_worker.c" -o "$SCRIPT_DIR/lib/thread_worker" -lpthread \
                || die 106 "Échec de compilation du thread_worker (gcc requis)"
        fi

        export -f process_file
        export TARGET_DIR OBJECTS_DIR meta_file snap_id
        "$SCRIPT_DIR/lib/thread_worker" "$tmpfile"

    # =========================
    # MODE NORMAL (séquentiel)
    # =========================
    else
        while IFS= read -r file; do
            process_file "$file"
        done < "$tmpfile"
    fi

    # =========================
    # VÉRIFICATION DE CHANGEMENT
    # =========================
    local dir_name
    dir_name=$(basename "$TARGET_DIR")
    local last_meta
    last_meta=$(tail -n 1 "$INDEX_DIR/${dir_name}.list" 2>/dev/null)

    if [ -n "$last_meta" ] && [ -f "$SNAPSHOTS_DIR/$last_meta" ]; then
        # Comparer uniquement les fichiers et leurs hashs (ignorer les métadonnées)
        grep -v -E "^(source_dir|description|date|author)=" "$SNAPSHOTS_DIR/$last_meta" | sort > "/tmp/last.tmp"
        grep -v -E "^(source_dir|description|date|author)=" "$meta_file" | sort > "/tmp/curr.tmp"

        if diff "/tmp/last.tmp" "/tmp/curr.tmp" > /dev/null; then
            echo "ℹ️ Aucun changement détecté depuis le dernier snapshot ($last_meta). Annulation."
            rm -f "$meta_file" "$meta_file.lock" "$tmpfile" \
                  "/tmp/snap_${snap_id}.size" "/tmp/last.tmp" "/tmp/curr.tmp"
            return 0
        fi
        rm -f "/tmp/last.tmp" "/tmp/curr.tmp"
    fi

    # =========================
    # FINALISATION
    # =========================
    files_count=$(wc -l < "$tmpfile")

    if [ -f "/tmp/snap_${snap_id}.size" ]; then
        total_size=$(awk '{s+=$1} END {print s}' "/tmp/snap_${snap_id}.size")
        rm -f "/tmp/snap_${snap_id}.size"
    fi

    # Enregistrer dans l'index par dossier
    echo "${snap_id}.meta" >> "$INDEX_DIR/${dir_name}.list"

    rm -f "$tmpfile" "$meta_file.lock"

    local size_mb=$((total_size / 1024 / 1024))

    log_event "INFOS" "SNAPSHOT_CREATED id=$snap_id files=$files_count size=${size_mb}M desc=\"$SNAP_MESSAGE\""

    # -----------------------------------------------------------------------
    # old: echo "✅ Snapshot terminé ! ID: $snap_id ($files_count fichiers)"
    # new:
    
    echo ""
    echo "✅ Snapshot créé avec succès !"
    echo "   ID          : $snap_id"
    echo "   Date        : $snap_date"
    echo "   Auteur      : $snap_author"
    echo "   Dossier     : $TARGET_DIR"
    echo "   Fichiers    : $files_count fichier(s)"
    echo "   Description : $SNAP_MESSAGE"
    # -----------------------------------------------------------------------
}

# ============================================================================
# FONCTION : _read_meta_field()
# Fonction utilitaire interne : lit un champ du fichier .meta
# Arguments : $1 = chemin du .meta, $2 = nom du champ (ex: "description")
# Retourne  : valeur du champ, ou "" si absent (compatibilité anciens snaps)
# ============================================================================
_read_meta_field() {
    local meta_file="$1"
    local field="$2"
    grep "^${field}=" "$meta_file" 2>/dev/null | head -1 | cut -d'=' -f2-
}

# ============================================================================
# FONCTION : cmd_log()
# Affiche l'historique des snapshots d'un dossier
# Variables utilisées : $TARGET_DIR
#
#   - Lecture et affichage du champ "description" de chaque snapshot
#   - Lecture du champ "author" si présent
#   - Affichage en blocs lisibles (un bloc par snapshot)
#   - Compatibilité avec les anciens snapshots sans description
# ============================================================================
cmd_log() {
    log_event "INFOS" "COMMAND: log $TARGET_DIR"

    # 1. Nom du dossier (ex: "mon_projet")
    local dir_name
    dir_name=$(basename "$TARGET_DIR")

    # 2. Fichier index du dossier
    local index_file="$INDEX_DIR/${dir_name}.list"

    # 3. Vérifier que des snapshots existent
    if [[ ! -f "$index_file" ]] || [[ ! -s "$index_file" ]]; then
        die 102 "Aucun snapshot trouvé pour le dossier : $TARGET_DIR"
    fi

    # 4. En-tête
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          Historique des snapshots — $dir_name"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    # 5. Parcourir chaque snapshot
    local snap_count=0
    while IFS= read -r meta_filename; do
        [[ -z "$meta_filename" ]] && continue

        local meta_file="$SNAPSHOTS_DIR/$meta_filename"
        [[ ! -f "$meta_file" ]] && continue

        # Extraire l'ID (nom sans .meta)
        local snap_id="${meta_filename%.meta}"

        # -----------------------------------------------------------------------
        # NOUVEAU : Lire les champs de métadonnées depuis le fichier .meta
        # -----------------------------------------------------------------------
        local description
        description=$(_read_meta_field "$meta_file" "description")
        local snap_author
        snap_author=$(_read_meta_field "$meta_file" "author")
        local snap_date_stored
        snap_date_stored=$(_read_meta_field "$meta_file" "date")
        # -----------------------------------------------------------------------

        # Fallback : si anciens snapshots sans métadonnées → déduire depuis l'ID
        if [[ -z "$snap_date_stored" ]]; then
            local year="${snap_id:0:4}"
            local month="${snap_id:4:2}"
            local day="${snap_id:6:2}"
            local hour="${snap_id:8:2}"
            local min="${snap_id:10:2}"
            local sec="${snap_id:12:2}"
            snap_date_stored="${day}/${month}/${year} ${hour}:${min}:${sec}"
        fi
        [[ -z "$snap_author"      ]] && snap_author="inconnu"
        [[ -z "$description"      ]] && description="Aucune description"

        # Compter les fichiers (lignes de contenu uniquement)
        local files_count
        files_count=$(grep -v -E "^(source_dir|description|date|author)=" "$meta_file" | grep -c ".")

        # Calculer la taille totale des objets compressés
        local total_size=0
        while IFS= read -r line; do
            [[ "$line" =~ ^(source_dir|description|date|author)= ]] && continue
            [[ -z "$line" ]] && continue
            local hash
            hash=$(echo "$line" | awk '{print $2}')
            local obj="$OBJECTS_DIR/${hash}.gz"
            if [[ -f "$obj" ]]; then
                local sz
                sz=$(stat -c%s "$obj" 2>/dev/null || echo 0)
                total_size=$((total_size + sz))
            fi
        done < "$meta_file"
        local size_kb=$((total_size / 1024))

        ((snap_count++))

        # -----------------------------------------------------------------------
        # NOUVEAU : Affichage en bloc lisible (style git log)
        # -----------------------------------------------------------------------
        echo "  ┌─────────────────────────────────────────────────┐"
        printf  "  │ %-7s %-41s│\n" "ID     :" "$snap_id"
        printf  "  │ %-7s %-41s│\n" "Date   :" "$snap_date_stored"
        printf  "  │ %-7s %-41s│\n" "Auteur :" "$snap_author"
        printf  "  │ %-7s %-41s│\n" "Fichiers:" "$files_count fichier(s) — ${size_kb} Ko"
        printf  "  │ %-7s %-41s│\n" "Desc   :" "$description"
        echo "  └─────────────────────────────────────────────────┘"
        echo ""
        # -----------------------------------------------------------------------

    done < "$index_file"

    echo "  Total : $snap_count snapshot(s)"
    echo ""
    log_event "INFOS" "LOG_DISPLAYED dir=$dir_name count=$snap_count"
}

# ============================================================================
# FONCTION : cmd_restore()
# Restaure un snapshot par son ID
# Variables utilisées : $TARGET_DIR, $OPT_SUBSHELL, $ORIGINAL_ARGS
#   - Affichage de la description du snapshot avant la confirmation
#   - Aide l'utilisateur à identifier le bon snapshot à restaurer
#   - Compatibilité avec les anciens snapshots sans description
# ============================================================================
cmd_restore() {
    log_event "INFOS" "COMMAND: restore $TARGET_DIR (subshell=$OPT_SUBSHELL)"

    # 1. Parser --id depuis les arguments originaux
    local snap_id=""
    for ((i=0; i<${#ORIGINAL_ARGS[@]}; i++)); do
        if [[ "${ORIGINAL_ARGS[$i]}" == "--id" ]]; then
            snap_id="${ORIGINAL_ARGS[$((i+1))]}"
            break
        fi
    done

    # 2. Vérifier que l'ID est fourni
    if [[ -z "$snap_id" ]]; then
        die 103 "Paramètre manquant : --id <snapshot_id> requis pour restore"
    fi

    # 3. Vérifier que le fichier .meta existe
    local meta_file="$SNAPSHOTS_DIR/${snap_id}.meta"
    if [[ ! -f "$meta_file" ]]; then
        die 103 "Version introuvable : snapshot '$snap_id' n'existe pas"
    fi

    # -----------------------------------------------------------------------
    # NOUVEAU : Lire et afficher les métadonnées du snapshot à restaurer
    # Permet à l'utilisateur de confirmer qu'il choisit le bon snapshot
    # -----------------------------------------------------------------------
    local description
    description=$(_read_meta_field "$meta_file" "description")
    local snap_author
    snap_author=$(_read_meta_field "$meta_file" "author")
    local snap_date_stored
    snap_date_stored=$(_read_meta_field "$meta_file" "date")

    # Fallbacks pour anciens snapshots
    [[ -z "$description"     ]] && description="Aucune description"
    [[ -z "$snap_author"     ]] && snap_author="inconnu"
    [[ -z "$snap_date_stored" ]] && snap_date_stored="date inconnue"

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            Informations du snapshot à restaurer           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "   ID          : $snap_id"
    echo "   Date        : $snap_date_stored"
    echo "   Auteur      : $snap_author"
    echo "   Description : $description"
    echo ""
    # -----------------------------------------------------------------------

    # 4. Définir la destination
    local dir_name
    dir_name=$(basename "$TARGET_DIR")
    local dest_dir

    if [[ "$OPT_SUBSHELL" -eq 1 ]]; then
        dest_dir="/tmp/snapfile_preview/${dir_name}"
        echo "📂 Mode prévisualisation : restauration dans $dest_dir"
        echo ""
        
        # Supprimer le dossier de prévisualisation s'il existe déjà
        if [[ -d "$dest_dir" ]]; then
            rm -rf "$dest_dir"
        fi
    else
        dest_dir="$TARGET_DIR"
        echo "📂 Restauration dans : $dest_dir"
        echo ""
        read -rp "Ceci va écraser les fichiers actuels. Continuer ? (oui/non) : " confirm
        if [[ "$confirm" != "oui" ]]; then
            echo "Opération annulée."
            exit 0
        fi
        
        # Supprimer complètement le dossier existant avant de le recréer
        if [[ -d "$dest_dir" ]]; then
            rm -rf "$dest_dir"
        fi
    fi

    mkdir -p "$dest_dir"

    # 5. Restaurer chaque fichier
    local restored=0
    local errors=0

    while IFS= read -r line; do
        # Ignorer les lignes de métadonnées
        [[ "$line" =~ ^(source_dir|description|date|author)= ]] && continue
        [[ -z "$line" ]] && continue

        local rel_path
        rel_path=$(echo "$line" | awk '{print $1}')
        local hash
        hash=$(echo "$line" | awk '{print $2}')

        # Enlever le préfixe du nom du dossier si présent
        # Par exemple : test_final/file1.txt devient file1.txt
        if [[ "$rel_path" == "${dir_name}/"* ]]; then
            rel_path="${rel_path#${dir_name}/}"
        fi

        local obj_file="$OBJECTS_DIR/${hash}.gz"
        local dest_file="$dest_dir/$rel_path"

        # Créer les sous-dossiers si nécessaire
        mkdir -p "$(dirname "$dest_file")"

        # Décompresser le fichier
        if gunzip -c "$obj_file" > "$dest_file" 2>/dev/null; then
            ((restored++))
        else
            echo "  ❌ Erreur : impossible de restaurer $rel_path" >&2
            ((errors++))
        fi
    done < "$meta_file"

    # 6. Résultat final
    echo ""
    echo "✅ Restauration terminée !"
    echo "   Fichiers restaurés : $restored"
    [[ $errors -gt 0 ]] && echo "   Fichiers en erreur : $errors"
    echo "   Destination        : $dest_dir"
    echo "   Snapshot restauré  : $snap_id"
    echo "   Description        : $description"

    log_event "INFOS" "RESTORE_APPLIED id=$snap_id files=$restored dest=$dest_dir desc=\"$description\""
}

# ============================================================================
# FONCTION : run_command()
# Dispatch vers la bonne fonction selon $COMMAND
# (non modifiée dans ce sprint)
# ============================================================================
run_command() {
    # Exécution normale
    case "$COMMAND" in
        init)    cmd_init ;;
        save)    cmd_save "$TARGET_DIR" ;;
        log)     cmd_log "$TARGET_DIR" ;;
        restore) cmd_restore "$TARGET_DIR" ;;
        *)       die 100 "Commande inconnue : '$COMMAND'" ;;
    esac
}
