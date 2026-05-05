#!/bin/bash
################################################################################
# commands.sh — Routage et dispatch des commandes
# Contient : run_command()
#
# Les implémentations réelles de chaque commande seront ajoutées
# par les membres suivants dans leurs sprints respectifs :
#   - cmd_save()    → Sprint 2 (Membre 2)
#   - cmd_log()     → Sprint 3 (Membre 3)
#   - cmd_restore() → Sprint 3 (Membre 3)
################################################################################

# ============================================================================
# FONCTION : cmd_save()
# Sauvegarde un dossier sous forme de snapshot
# Variables utilisées : $TARGET_DIR, $OPT_FORK, $OPT_THREAD
# TODO : à implémenter dans le Sprint 2
# ============================================================================
cmd_save() {
    log_event "INFOS" "COMMAND: save $TARGET_DIR"

    # =========================
    # Vérifier espace disque
    # =========================
    local avail_space
    avail_space=$(df -k "$TARGET_DIR" | tail -1 | awk '{print $4}')
    [ "$avail_space" -lt 51200 ] && die 104 "Espace insuffisant"

    # =========================
    # Snapshot ID
    # =========================
    local snap_id
    snap_id=$(date '+%Y%m%d%H%M%S')

    local meta_file="$SNAPSHOTS_DIR/${snap_id}.meta"
    local tmpfile
    tmpfile=$(mktemp) || die 107 "Impossible de créer un fichier temporaire"

    find "$TARGET_DIR" -type f > "$tmpfile"

    echo "source_dir=$TARGET_DIR" > "$meta_file"

    local files_count=0
    local total_size=0

    # =========================
    # Fonction de traitement
    # =========================
    process_file() {
        # On reçoit un lot de fichiers (max 5) en arguments
        for file in "$@"; do
            [ ! -f "$file" ] && continue

            local hash
            hash=$(sha256sum "$file" | awk '{print $1}')

            local obj_path="$OBJECTS_DIR/${hash}.gz"

            local file_size
            file_size=$(stat -c%s "$file")

            # compression si besoin
            if [ ! -f "$obj_path" ]; then
                gzip -c "$file" > "$obj_path" || continue
            fi

            local relative_path="${file#$TARGET_DIR/}"

            # écrire dans meta (SAFE avec lock pour le parallélisme)
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

        # Compiler le worker si nécessaire
        if [ ! -f "$SCRIPT_DIR/lib/fork_worker" ]; then
            gcc -O3 "$SCRIPT_DIR/lib/fork_worker.c" -o "$SCRIPT_DIR/lib/fork_worker" || die 106 "Échec de compilation du fork_worker (gcc requis)"
        fi

        export -f process_file
        export TARGET_DIR OBJECTS_DIR meta_file snap_id

        # Lancer le worker C
        "$SCRIPT_DIR/lib/fork_worker" "$tmpfile"


       

    # =========================
    # MODE THREAD (-t)
    # =========================
    elif [ "$OPT_THREAD" -eq 1 ]; then
        echo "🧵 Mode THREAD (C-Worker avec pthread)"

        # Compiler le worker si nécessaire
        if [ ! -f "$SCRIPT_DIR/lib/thread_worker" ]; then
            gcc -O3 "$SCRIPT_DIR/lib/thread_worker.c" -o "$SCRIPT_DIR/lib/thread_worker" -lpthread || die 106 "Échec de compilation du thread_worker (gcc requis)"
        fi

        export -f process_file
        export TARGET_DIR OBJECTS_DIR meta_file snap_id

        # Lancer le worker C (pthread)
        "$SCRIPT_DIR/lib/thread_worker" "$tmpfile"

    # =========================
    # MODE NORMAL
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
        # On compare uniquement les fichiers et leurs hashs (triés pour le parallélisme)
        grep -v "source_dir=" "$SNAPSHOTS_DIR/$last_meta" | sort > "/tmp/last.tmp"
        grep -v "source_dir=" "$meta_file" | sort > "/tmp/curr.tmp"

        if diff "/tmp/last.tmp" "/tmp/curr.tmp" > /dev/null; then
            echo "ℹ️ Aucun changement détecté depuis le dernier snapshot ($last_meta). Annulation."
            rm -f "$meta_file" "$meta_file.lock" "$tmpfile" "/tmp/snap_${snap_id}.size" "/tmp/last.tmp" "/tmp/curr.tmp"
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

    # =========================
    # INDEX (par dossier)
    # =========================
    local dir_name
    dir_name=$(basename "$TARGET_DIR")

    echo "${snap_id}.meta" >> "$INDEX_DIR/${dir_name}.list"

    rm -f "$tmpfile"
    rm -f "$meta_file.lock"

    local size_mb=$((total_size / 1024 / 1024))

    log_event "INFOS" "SNAPSHOT_CREATED id=$snap_id files=$files_count size=${size_mb}M"

    echo "✅ Snapshot terminé ! ID: $snap_id ($files_count fichiers)"
}
# ============================================================================
# FONCTION : cmd_log()
# Affiche l'historique des snapshots d'un dossier
# Variables utilisées : $TARGET_DIR#
# ============================================================================
cmd_log() {
    log_event "INFOS" "COMMAND: log $TARGET_DIR"

    # 1. Nom du dossier (ex: "mon_projet")
    local dir_name
    dir_name=$(basename "$TARGET_DIR")

    # 2. Fichier index
    local index_file="$INDEX_DIR/${dir_name}.list"

    # 3. Vérifier que des snapshots existent
    if [[ ! -f "$index_file" ]] || [[ ! -s "$index_file" ]]; then
        die 102 "Aucun snapshot trouvé pour le dossier : $TARGET_DIR"
    fi

    # 4. Afficher l'en-tête du tableau
    echo ""
    echo "📋 Historique des snapshots : $TARGET_DIR"
    echo ""
    printf "%-20s %-20s %-10s %-12s\n" "ID" "Date" "Fichiers" "Taille"
    printf "%-20s %-20s %-10s %-12s\n" "--------------------" "--------------------" "----------" "------------"

    # 5. Parcourir chaque snapshot
    local snap_count=0
    while IFS= read -r meta_filename; do
        [[ -z "$meta_filename" ]] && continue

        local meta_file="$SNAPSHOTS_DIR/$meta_filename"
        [[ ! -f "$meta_file" ]] && continue

        # Extraire l'ID (nom du fichier sans .meta)
        local snap_id="${meta_filename%.meta}"

        # Formater la date depuis l'ID (format: YYYYMMDDHHmmSS)
        local year="${snap_id:0:4}"
        local month="${snap_id:4:2}"
        local day="${snap_id:6:2}"
        local hour="${snap_id:8:2}"
        local min="${snap_id:10:2}"
        local sec="${snap_id:12:2}"
        local date_fmt="${day}/${month}/${year} ${hour}:${min}:${sec}"

        # Compter les fichiers (lignes sans "source_dir=")
        local files_count
        files_count=$(grep -v "^source_dir=" "$meta_file" | grep -c ".")

        # Calculer la taille totale des objets
        local total_size=0
        while IFS= read -r line; do
            [[ "$line" == source_dir=* ]] && continue
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

        printf "%-20s %-20s %-10s %-12s\n" "$snap_id" "$date_fmt" "$files_count" "${size_kb} Ko"
        ((snap_count++))
    done < "$index_file"

    echo ""
    echo "Total : $snap_count snapshot(s)"
    log_event "INFOS" "LOG_DISPLAYED dir=$dir_name count=$snap_count"
}

# ============================================================================
# FONCTION : cmd_restore()
# Restaure un snapshot par son ID
# Variables utilisées : $TARGET_DIR, $OPT_SUBSHELL, $@
# ============================================================================
cmd_restore() {
    log_event "INFOS" "COMMAND: restore $TARGET_DIR (subshell=$OPT_SUBSHELL)"

    # 1. Parser --id depuis les arguments restants
    # Parser --id depuis les arguments originaux
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

    # 4. Définir la destination
    local dir_name
    dir_name=$(basename "$TARGET_DIR")
    local dest_dir

    if [[ "$OPT_SUBSHELL" -eq 1 ]]; then
        dest_dir="/tmp/snapfile_preview/${dir_name}"
        echo "Mode prévisualisation : restauration dans $dest_dir"
    else
        dest_dir="$TARGET_DIR"
        echo "Restauration dans : $dest_dir"
        read -rp "Ceci va écraser les fichiers actuels. Continuer ? (oui/non) : " confirm
        if [[ "$confirm" != "oui" ]]; then
            echo "Opération annulée."
            exit 0
        fi
    fi

    mkdir -p "$dest_dir"

    # 5. Restaurer chaque fichier
    local restored=0
    local errors=0

    while IFS= read -r line; do
        # Ignorer la ligne source_dir=
        [[ "$line" == source_dir=* ]] && continue
        [[ -z "$line" ]] && continue

        local rel_path
        rel_path=$(echo "$line" | awk '{print $1}')
        local hash
        hash=$(echo "$line" | awk '{print $2}')

        local obj_file="$OBJECTS_DIR/${hash}.gz"
        local dest_file="$dest_dir/$rel_path"

        # Créer les sous-dossiers si nécessaire
        mkdir -p "$(dirname "$dest_file")"

        # Décompresser le fichier
        if gunzip -c "$obj_file" > "$dest_file" 2>/dev/null; then
            ((restored++))
        else
            echo "Erreur : impossible de restaurer $rel_path" >&2
            ((errors++))
        fi
    done < "$meta_file"

    # 6. Résultat
    echo ""
    echo "Restauration terminée : $restored fichier(s) restauré(s)"
    [[ $errors -gt 0 ]] && echo "$errors fichier(s) en erreur"
    echo "Destination : $dest_dir"

    log_event "INFOS" "RESTORE_APPLIED id=$snap_id files=$restored dest=$dest_dir"
}

# ============================================================================
# FONCTION : run_command()
# Dispatch vers la bonne fonction selon $COMMAND
# ============================================================================
run_command() {
    case "$COMMAND" in
        save)
            cmd_save "$@"
            ;;
        log)
            cmd_log "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        *)
            die 100 "Commande inconnue : '$COMMAND'  (valides : save, log, restore)"
            ;;
    esac
}
