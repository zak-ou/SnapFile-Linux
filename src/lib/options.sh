#!/bin/bash
################################################################################
# options.sh — Parseur d'options et de commandes
# Contient : parse_options()
################################################################################

# ============================================================================
# FONCTION : parse_options()
# Parse les options CLI avec getopts et positionne les flags globaux.
# Après l'appel, les variables suivantes sont définies :
#   OPT_FORK, OPT_THREAD, OPT_SUBSHELL, OPT_RESET
#   LOG_FILE (si -l fourni)
#   COMMAND, TARGET_DIR (paramètres positionnels restants)
# ============================================================================
parse_options() {
    # Aucun argument → afficher l'aide
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    while getopts ":hftsl:r" opt; do
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
                ;;
            r)
                OPT_RESET=1
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

    # Récupérer la commande et le dossier cible
    COMMAND="${1:-}"
    TARGET_DIR="${2:-}"
}
