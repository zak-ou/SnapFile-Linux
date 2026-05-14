#!/bin/bash
################################################################################
# reset.sh — Réinitialisation complète (option -r)
# Contient : check_sudo(), reset_snapfile()
# Nécessite : sudo
################################################################################

# ============================================================================
# FONCTION : check_sudo()
# Vérifie que le script est exécuté avec les privilèges root
# ============================================================================
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        die 105 "L'option -r nécessite les privilèges administrateur (sudo)"
    fi
}

# ============================================================================
# FONCTION : reset_snapfile()
# Purge complète du dépôt et des logs (nécessite sudo)
# ============================================================================
reset_snapfile() {
    check_sudo

    echo "⚠️  ATTENTION : Cette opération va supprimer TOUS les snapshots !"
    echo "   Dépôt à purger  : $SNAPFILE_DIR"
    echo "   Logs à effacer  : /var/log/snapfile/"
    echo ""
    read -rp "Êtes-vous sûr ? (tapez 'OUI' pour confirmer) : " confirmation

    if [[ "$confirmation" != "OUI" ]]; then
        echo "Opération annulée."
        exit 0
    fi

    # Logger AVANT la suppression (sinon le fichier de log sera supprimé)
    log_event "INFOS" "RESET_INITIATED: Purging all snapshots and logs"

    # Purger le dépôt
    if [[ -d "$SNAPFILE_DIR" ]]; then
        rm -rf "$SNAPFILE_DIR"
        echo "✓ Dépôt $SNAPFILE_DIR supprimé"
    else
        echo "ℹ️  Dépôt $SNAPFILE_DIR n'existe pas (déjà supprimé)"
    fi

    # Purger les logs système
    if [[ -d "/var/log/snapfile" ]]; then
        rm -rf "/var/log/snapfile"
        echo "✓ Logs /var/log/snapfile/ supprimés"
    else
        echo "ℹ️  Logs /var/log/snapfile/ n'existent pas"
    fi

    echo ""
    echo "✓ Réinitialisation terminée avec succès"
    echo "✓ Tous les snapshots et logs ont été purgés"
    exit 0
}
