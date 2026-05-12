#!/bin/bash
################################################################################
# utils.sh — Fonctions utilitaires partagées
# Contient : usage(), log_event(), die()
################################################################################

# ============================================================================
# FONCTION : usage()
# Affiche le manuel complet du script (option -h)
# ============================================================================
usage() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                            SNAPFILE v1.0.0                               ║
║          Système de versionnement léger pour fichiers locaux            ║
╚══════════════════════════════════════════════════════════════════════════╝

SYNOPSIS
    snapfile [OPTIONS] <commande> <dossier>

DESCRIPTION
    SnapFile est un outil de versionnement transparent qui capture des
    instantanés horodatés de vos dossiers. Il utilise la déduplication
    par hash SHA-256 pour économiser l'espace disque.

COMMANDES
    init                        Initialise le dépôt SnapFile manuellement
    save <dossier>              Crée un nouveau snapshot du dossier
    log <dossier>               Affiche l'historique des snapshots
    restore <dossier> --id N    Restaure le snapshot N

OPTIONS
    -h                          Affiche ce manuel d'aide
    -f                          Fork : exécute la sauvegarde en arrière-plan
    -t                          Thread : compression parallèle des fichiers
    -s                          Subshell : restauration en prévisualisation
                                (dans /tmp/ sans écraser l'original)
    -l <chemin>                 Spécifie un répertoire de logs personnalisé
    -r                          Reset : réinitialise la configuration
                                (nécessite sudo)

EXEMPLES
    snapfile init
    snapfile save mon_projet/
    snapfile -f save mon_projet/
    snapfile -t save gros_projet/
    snapfile log mon_projet/
    snapfile -s restore mon_projet/ --id 3
    snapfile restore mon_projet/ --id 3
    sudo snapfile -r

CODES D'ERREUR
    100    Option non reconnue
    101    Paramètre manquant  ou invalide (chemin du dossier)
    102    Dépôt non initialisé (aucun snapshot trouvé)
    103    Version introuvable (ID de snapshot inexistant)
    104    Espace disque insuffisant
    105    Conflit d'options (ex: -f et -t simultanés)
    106    Échec de compilation (gcc manquant)
    107    Erreur système (fichiers temporaires)
    108    Interruption utilisateur (SIGINT)

FICHIERS
    ~/.snapfile/objects/        Fichiers dédupliqués (stockage par hash)
    ~/.snapfile/snapshots/      Métadonnées des snapshots
    ~/.snapfile/index/          Mapping hash → chemin
    /var/log/snapfile/          Logs des opérations

FORMAT DES LOGS
    yyyy-mm-dd-hh-mm-ss: username: TYPE: message

EOF
}

# ============================================================================
# FONCTION : log_event()
# Enregistre un événement dans le fichier de log
# Arguments :
#   $1 - TYPE  : INFOS | ERROR | WARNING
#   $2 - message
# ============================================================================
log_event() {
    local type="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d-%H-%M-%S')
    local username
    username=$(whoami)
    local log_entry="${timestamp}: ${username}: ${type}: ${message}"

    # Créer le répertoire de log si nécessaire
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || {
            echo "⚠️  Impossible de créer le répertoire de log: $log_dir" >&2
            return 1
        }
    fi

    # Écrire dans le log
    if ! echo "$log_entry" >> "$LOG_FILE" 2>/dev/null; then
        echo "⚠️  Impossible d'écrire dans le fichier de log: $LOG_FILE" >&2
        return 1
    fi
    
    # Afficher aussi sur la console en mode verbose (optionnel)
    # echo "$log_entry"
}

# ============================================================================
# FONCTION : die()
# Gestion unifiée des erreurs : log + affichage + aide + exit
# Arguments :
#   $1 - code d'erreur (100-105)
#   $2 - message d'erreur
# ============================================================================
die() {
    local error_code="$1"
    local error_message="$2"

    log_event "ERROR" "ERROR_${error_code}: ${error_message}"
    echo -e "\n❌ ERREUR ${error_code}: ${error_message}\n" >&2
    usage
    exit "$error_code"
}
