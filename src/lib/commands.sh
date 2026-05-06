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
# Variables utilisées : $TARGET_DIR
# TODO : à implémenter dans le Sprint 3
# ============================================================================
cmd_log() {
    log_event "INFOS" "COMMAND: log $TARGET_DIR"

    # =========================================================
    # TODO SPRINT 3 — Membre 3
    # =========================================================
    # 1. Vérifier que ~/.snapfile/snapshots/ n'est pas vide (die 102)
    # 2. Lire les fichiers de métadonnées avec awk/grep
    # 3. Filtrer par nom de dossier source
    # 4. Afficher un tableau formaté : ID | Date | Fichiers | Taille
    # =========================================================

    echo "📋 [log] Dossier cible : $TARGET_DIR"
    echo "⚠️  À implémenter — Sprint 3 (Membre 3)"
}

# ============================================================================
# FONCTION : cmd_restore()
# Restaure un snapshot par son ID
# Variables utilisées : $TARGET_DIR, $OPT_SUBSHELL, $@
# TODO : à implémenter dans le Sprint 3
# ============================================================================
cmd_restore() {
    log_event "INFOS" "COMMAND: restore $TARGET_DIR (subshell=$OPT_SUBSHELL)"

    # =========================================================
    # TODO SPRINT 3 — Membre 3
    # =========================================================
    # 1. Parser --id N depuis les arguments restants
    # 2. Vérifier que l'ID existe (die 103 sinon)
    # 3. Lire les métadonnées du snapshot
    # 4. Reconstruire les fichiers depuis objects/ (gunzip)
    # 5. Si OPT_SUBSHELL=1 : restaurer dans /tmp/snapfile_preview/
    #    Sinon : restaurer directement dans TARGET_DIR
    # 6. log_event "INFOS" "RESTORE_APPLIED id=N"
    # =========================================================

    echo "♻️  [restore] Dossier cible : $TARGET_DIR"
    echo "⚠️  À implémenter — Sprint 3 (Membre 3)"
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
