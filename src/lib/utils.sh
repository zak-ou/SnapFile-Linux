#!/bin/bash
################################################################################
# utils.sh — Fonctions utilitaires partagées
# Contient : usage(), log_event(), die()
#
# MODIFICATION:
#   - usage() : ajout de l'option -m et des exemples de messages
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
    snapfile [OPTIONS] <commande> <dossier> ["message"]

DESCRIPTION
    SnapFile est un outil de versionnement transparent qui capture des
    instantanés horodatés de vos dossiers. Il utilise la déduplication
    par hash SHA-256 pour économiser l'espace disque.

    Chaque snapshot peut être accompagné d'une description (similaire
    aux messages de commit Git) pour documenter les modifications.

COMMANDES
    init                              Initialise le dépôt SnapFile
    save <dossier> ["message"]        Crée un snapshot avec description optionnelle
    log <dossier>                     Affiche l'historique des snapshots
    restore <dossier> --id N          Restaure le snapshot N

OPTIONS
    -h                          Affiche ce manuel d'aide
    -m "message"                Ajoute une description au snapshot (save uniquement)
    -f                          Fork : exécute la sauvegarde en arrière-plan
    -t                          Thread : compression parallèle des fichiers
    -s                          Subshell : restauration en prévisualisation
                                (dans /tmp/ sans écraser l'original)
    -l <chemin>                 Spécifie un répertoire de logs personnalisé
    -r                          Reset : réinitialise la configuration
                                (nécessite sudo)

DESCRIPTION D'UN SNAPSHOT
    Deux syntaxes sont supportées pour ajouter un message :

    1) Via l'option -m (recommandé) :
       ./snapfile.sh save mon_projet/ -m "Correction du bug de restauration"

    2) Via le 3ème argument positionnel :
       ./snapfile.sh save mon_projet/ "Ajout du module de logs"

    Si aucun message n'est fourni, la description sera "Aucune description".

EXEMPLES
    snapfile init
    snapfile save mon_projet/
    snapfile save mon_projet/ "Première version stable"
    snapfile save mon_projet/ -m "Correction du bug d'index"
    snapfile -f save mon_projet/ -m "Sauvegarde en arrière-plan"
    snapfile -t save gros_projet/ -m "Compression parallèle"
    snapfile log mon_projet/
    snapfile restore mon_projet/ --id 20260512143022
    snapfile -s restore mon_projet/ --id 20260512143022

CODES D'ERREUR
    100    Option non reconnue
    101    Paramètre manquant ou invalide (chemin du dossier)
    102    Dépôt non initialisé (aucun snapshot trouvé)
    103    Version introuvable (ID de snapshot inexistant)
    104    Espace disque insuffisant
    105    Conflit d'options (ex: -f et -t simultanés)
    106    Échec de compilation (gcc manquant)
    107    Erreur système (fichiers temporaires)
    108    Interruption utilisateur (SIGINT)

FICHIERS
    ~/.snapfile/objects/        Fichiers dédupliqués (stockage par hash)
    ~/.snapfile/snapshots/      Métadonnées des snapshots (.meta)
    ~/.snapfile/index/          Index des snapshots par dossier
    ~/.snapfile/history.log     Journal des opérations

FORMAT DES FICHIERS .meta
    source_dir=/chemin/vers/dossier
    description=Message de l'utilisateur
    date=2026-05-12 14:30:22
    author=safa
    fichier1.txt a3f5b2c...
    sous-dossier/fichier2.py 9e1d4f7...

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
}

# ============================================================================
# FONCTION : die()
# Gestion unifiée des erreurs : log + affichage + aide + exit
# Arguments :
#   $1 - code d'erreur (100-108)
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
