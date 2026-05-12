#!/bin/bash
################################################################################
# options.sh — Parseur d'options et de commandes
# Contient : parse_options()
#
# MODIFICATION (Système de description) :
#   - Ajout de l'option -m "message" pour décrire un snapshot
#   - Syntaxe supportée :
#       ./snapfile.sh save <dossier> "message direct"      (3ème argument)
#       ./snapfile.sh save <dossier> -m "message"          (option -m)
#   - Si aucun message fourni, SNAP_MESSAGE = "Aucune description"
#   - Variable exportée : SNAP_MESSAGE
################################################################################

# ============================================================================
# FONCTION : parse_options()
# Parse les options CLI avec getopts et positionne les flags globaux.
# Après l'appel, les variables suivantes sont définies :
#   OPT_FORK, OPT_THREAD, OPT_SUBSHELL, OPT_RESET
#   LOG_FILE      (si -l fourni)
#   SNAP_MESSAGE  (description/message du snapshot — NOUVEAU)
#   COMMAND, TARGET_DIR (paramètres positionnels restants)
# ============================================================================
parse_options() {
    # Aucun argument → afficher l'aide
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    # Initialiser SNAP_MESSAGE vide (sera complété après getopts)
    SNAP_MESSAGE=""

    # Parser les options courtes — "m:" signifie que -m attend un argument
    while getopts ":hftsl:rm:" opt; do
        case $opt in
            h)
                usage
                exit 0
                ;;
            f)
                OPT_FORK=1
                ;;
            t)
                OPT_THREAD=1
                ;;
            s)
                OPT_SUBSHELL=1
                ;;
            l)
                LOG_FILE="${OPTARG}/snapfile.log"
                export LOG_FILE
                ;;
            r)
                OPT_RESET=1
                ;;
            m)
                
                SNAP_MESSAGE="$OPTARG"
                ;;
            \?)
                die 100 "Option non reconnue : -${OPTARG}"
                ;;
            :)
                die 101 "L'option -${OPTARG} nécessite un argument"
                ;;
        esac
    done

    # Décaler les arguments pour accéder aux paramètres positionnels
    shift $((OPTIND - 1))

    # Vérification de conflits d'options
    if [[ $OPT_FORK -eq 1 ]] && [[ $OPT_THREAD -eq 1 ]]; then
        die 105 "Conflit d'options : Choisissez soit -f (fork) soit -t (thread), pas les deux"
    fi

    # Récupérer la commande et le dossier cible (arguments positionnels)
    COMMAND="${1:-}"
    TARGET_DIR="${2:-}"

    # -----------------------------------------------------------------------
    # Recherche de -m dans les arguments restants
    #
    # Problème : l'utilisateur tape souvent :
    #   ./snapfile.sh save <dossier> -m "message"
    # getopts s'arrête à "save" (premier argument non-option) et ne voit
    # jamais le -m qui vient après. On le recherche donc manuellement
    # dans les arguments restants (${3}, ${4}, ...).
    #
    # Priorité :
    #   1. -m avant la commande (déjà capturé par getopts ci-dessus)
    #   2. -m après la commande et le dossier (recherche manuelle ci-dessous)
    #   3. 3ème argument positionnel sans flag
    # -----------------------------------------------------------------------
    if [[ -z "$SNAP_MESSAGE" ]]; then
        # Parcourir tous les arguments pour trouver -m <valeur>
        local args_array=("$@")
        local i
        for (( i=0; i<${#args_array[@]}; i++ )); do
            if [[ "${args_array[$i]}" == "-m" ]]; then
                # L'argument suivant est le message
                local next_i=$(( i + 1 ))
                if [[ -n "${args_array[$next_i]:-}" ]]; then
                    SNAP_MESSAGE="${args_array[$next_i]}"
                fi
                break
            fi
        done
    fi

    # 3ème argument positionnel (si -m n'a pas été trouvé)
    # Exemple : ./snapfile.sh save mon_dossier/ "Correction du bug"
    if [[ -z "$SNAP_MESSAGE" && -n "${3:-}" && "${3}" != "-m" ]]; then
        SNAP_MESSAGE="${3}"
    fi

    # Valeur par défaut si aucun message n'a été fourni
    if [[ -z "$SNAP_MESSAGE" ]]; then
        SNAP_MESSAGE="Aucune description"
    fi

    # Exporter pour que cmd_save() et les sous-processus y accèdent
    export SNAP_MESSAGE
}
