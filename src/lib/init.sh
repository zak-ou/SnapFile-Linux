#!/bin/bash
################################################################################
# init.sh — Initialisation et validation
# Contient : init_repository(), validate_target_dir()
################################################################################

# ============================================================================
# FONCTION : init_repository()
# Crée la structure du dépôt ~/.snapfile/ si elle n'existe pas encore
# ============================================================================
init_repository() {
    if [[ ! -d "$SNAPFILE_DIR" ]]; then
        mkdir -p "$OBJECTS_DIR" "$SNAPSHOTS_DIR" "$INDEX_DIR"
        log_event "INFOS" "Repository initialized at $SNAPFILE_DIR"
        echo "✓ Dépôt SnapFile initialisé : $SNAPFILE_DIR"
    fi
}

# ============================================================================
# FONCTION : validate_target_dir()
# Vérifie que le chemin du dossier cible est fourni et valide
# ============================================================================
validate_target_dir() {
    # 1. Vérifier si l'argument est vide (Erreur 101)
    if [[ -z "$TARGET_DIR" ]]; then
        die 101 "Paramètre manquant : vous devez spécifier un chemin de dossier"
    fi

    # 2. Vérifier si le dossier existe (Erreur 102)
    if [[ ! -d "$TARGET_DIR" ]]; then
        die 102 "Le chemin spécifié n'existe pas : $TARGET_DIR"
    fi

    # 3. AJOUT : Vérifier les permissions de lecture (Erreur 104)
    if [[ ! -r "$TARGET_DIR" ]]; then
        die 104 "Permission refusée : impossible de lire le contenu de $TARGET_DIR"
    fi
}
