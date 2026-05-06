#!/bin/bash
################################################################################
# snapfile.sh — Point d'entrée principal
#
# Projet  : SnapFile v1.0.0
# Module  : Théorie des Systèmes d'Exploitation — SE Windows/Unix/Linux
# Sujet   : Versionnement & Restauration Légère de Fichiers
# Date    : 30 avril 2026
#
# Usage   : ./snapfile.sh [OPTIONS] <commande> <dossier>
# Aide    : ./snapfile.sh -h
################################################################################

# ============================================================================
# VARIABLES GLOBALES
# ============================================================================
readonly VERSION="1.0.0"

# Dépôt de stockage
readonly SNAPFILE_DIR="$HOME/.snapfile"
readonly OBJECTS_DIR="$SNAPFILE_DIR/objects"
readonly SNAPSHOTS_DIR="$SNAPFILE_DIR/snapshots"
readonly INDEX_DIR="$SNAPFILE_DIR/index"

# Log
LOG_FILE="/var/log/snapfile/history.log"

# Flags des options (0 = désactivé, 1 = activé)
OPT_FORK=0
OPT_THREAD=0
OPT_SUBSHELL=0
OPT_RESET=0

# Paramètres positionnels
COMMAND=""
TARGET_DIR=""

# ============================================================================
# CHARGEMENT DES MODULES
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/utils.sh"    # usage(), log_event(), die()
source "$SCRIPT_DIR/lib/init.sh"     # init_repository(), validate_target_dir()
source "$SCRIPT_DIR/lib/options.sh"  # parse_options()
source "$SCRIPT_DIR/lib/reset.sh"    # check_sudo(), reset_snapfile()
source "$SCRIPT_DIR/lib/commands.sh" # cmd_save(), cmd_log(), cmd_restore(), run_command()

# ============================================================================
# POINT D'ENTRÉE
# ============================================================================

# Capturer Ctrl+C (Interruption)
trap 'echo ""; die 108 "Interruption par l utilisateur"' SIGINT

#need it cz $@ already consumed by parse_options
# Sauvegarder les arguments originaux (pour cmd_restore --id)
ORIGINAL_ARGS=("$@")

# 1. Parser les options et récupérer COMMAND + TARGET_DIR
parse_options "$@"

# 2. Traiter l'option -r (reset) en priorité
if [[ $OPT_RESET -eq 1 ]]; then
    reset_snapfile
fi

# 3. Valider le paramètre obligatoire
validate_target_dir

# 4. Initialiser le dépôt si nécessaire
init_repository

# 5. Dispatcher vers la commande demandée
run_command

# 6. Log de fin
log_event "INFOS" "Execution completed: $COMMAND $TARGET_DIR"
echo ""
echo "✓ Exécution terminée avec succès"
exit 0
