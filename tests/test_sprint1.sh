#!/bin/bash

################################################################################
# Script de Test - Sprint 1
# Valide toutes les fonctionnalités du Sprint 1
################################################################################

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
TESTS_PASSED=0
TESTS_FAILED=0

# Fonction pour afficher un test
print_test() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}TEST: $1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Fonction pour valider un test
assert_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $1"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $1"
        ((TESTS_FAILED++))
    fi
}

assert_failure() {
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $1"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $1"
        ((TESTS_FAILED++))
    fi
}

assert_exit_code() {
    local expected=$1
    local actual=$2
    local description=$3
    if [ $actual -eq $expected ]; then
        echo -e "${GREEN}✓ PASS${NC}: $description (code $actual)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $description (attendu: $expected, obtenu: $actual)"
        ((TESTS_FAILED++))
    fi
}

# Nettoyer l'environnement de test
cleanup() {
    rm -rf ~/.snapfile 2>/dev/null
    rm -rf /tmp/test_snapfile 2>/dev/null
    sudo rm -rf /var/log/snapfile 2>/dev/null
}

echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                    TESTS DU SPRINT 1 - SNAPFILE                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"

# Vérifier que le script existe
if [ ! -f "./snapfile.sh" ]; then
    echo -e "${RED}ERREUR: snapfile.sh introuvable${NC}"
    exit 1
fi

# Rendre le script exécutable
chmod +x ./snapfile.sh

# ============================================================================
# TEST 1 : Option -h (Aide)
# ============================================================================
print_test "Option -h affiche le manuel"
./snapfile.sh -h > /dev/null 2>&1
assert_success "L'aide s'affiche sans erreur"

# ============================================================================
# TEST 2 : Option inconnue (Erreur 100)
# ============================================================================
print_test "Option inconnue déclenche l'erreur 100"
./snapfile.sh -z save test/ 2>/dev/null
EXIT_CODE=$?
assert_exit_code 100 $EXIT_CODE "Code d'erreur 100 pour option inconnue"

# ============================================================================
# TEST 3 : Paramètre manquant (Erreur 101)
# ============================================================================
print_test "Paramètre manquant déclenche l'erreur 101"
./snapfile.sh save 2>/dev/null
EXIT_CODE=$?
assert_exit_code 101 $EXIT_CODE "Code d'erreur 101 pour paramètre manquant"

# ============================================================================
# TEST 4 : Chemin inexistant (Erreur 101)
# ============================================================================
print_test "Chemin inexistant déclenche l'erreur 101"
./snapfile.sh save /chemin/totalement/inexistant 2>/dev/null
EXIT_CODE=$?
assert_exit_code 101 $EXIT_CODE "Code d'erreur 101 pour chemin inexistant"

# ============================================================================
# TEST 5 : Initialisation du dépôt
# ============================================================================
print_test "Initialisation du dépôt ~/.snapfile/"
cleanup
mkdir -p /tmp/test_snapfile
./snapfile.sh save /tmp/test_snapfile > /dev/null 2>&1

if [ -d "$HOME/.snapfile/objects" ] && [ -d "$HOME/.snapfile/snapshots" ] && [ -d "$HOME/.snapfile/index" ]; then
    echo -e "${GREEN}✓ PASS${NC}: Structure du dépôt créée correctement"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}: Structure du dépôt incomplète"
    ((TESTS_FAILED++))
fi

# ============================================================================
# TEST 6 : Système de log
# ============================================================================
print_test "Système de log fonctionnel"
cleanup
mkdir -p /tmp/test_snapfile
./snapfile.sh save /tmp/test_snapfile > /dev/null 2>&1

# Vérifier que le log existe (soit dans /var/log soit dans ~/.snapfile)
if [ -f "/var/log/snapfile/history.log" ] || [ -f "$HOME/.snapfile/snapfile.log" ]; then
    echo -e "${GREEN}✓ PASS${NC}: Fichier de log créé"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}: Fichier de log introuvable"
    ((TESTS_FAILED++))
fi

# ============================================================================
# TEST 7 : Option -l (Log personnalisé)
# ============================================================================
print_test "Option -l pour log personnalisé"
cleanup
mkdir -p /tmp/test_snapfile
mkdir -p /tmp/test_logs
./snapfile.sh -l /tmp/test_logs save /tmp/test_snapfile > /dev/null 2>&1

if [ -f "/tmp/test_logs/snapfile.log" ]; then
    echo -e "${GREEN}✓ PASS${NC}: Log personnalisé créé au bon endroit"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}: Log personnalisé introuvable"
    ((TESTS_FAILED++))
fi

# ============================================================================
# TEST 8 : Option -r sans sudo (Erreur 105)
# ============================================================================
print_test "Option -r sans sudo déclenche l'erreur 105"
./snapfile.sh -r 2>/dev/null
EXIT_CODE=$?
assert_exit_code 105 $EXIT_CODE "Code d'erreur 105 pour -r sans sudo"

# ============================================================================
# TEST 9 : Parsing des options -f, -t, -s
# ============================================================================
print_test "Options -f, -t, -s sont reconnues"
cleanup
mkdir -p /tmp/test_snapfile
./snapfile.sh -f save /tmp/test_snapfile > /dev/null 2>&1
assert_success "Option -f acceptée"

./snapfile.sh -t save /tmp/test_snapfile > /dev/null 2>&1
assert_success "Option -t acceptée"

./snapfile.sh -s restore /tmp/test_snapfile --id 1 > /dev/null 2>&1
assert_success "Option -s acceptée"

# ============================================================================
# TEST 10 : Commandes save, log, restore reconnues
# ============================================================================
print_test "Commandes save, log, restore sont reconnues"
cleanup
mkdir -p /tmp/test_snapfile

./snapfile.sh save /tmp/test_snapfile > /dev/null 2>&1
assert_success "Commande 'save' reconnue"

./snapfile.sh log /tmp/test_snapfile > /dev/null 2>&1
assert_success "Commande 'log' reconnue"

./snapfile.sh restore /tmp/test_snapfile --id 1 > /dev/null 2>&1
assert_success "Commande 'restore' reconnue"

# ============================================================================
# TEST 11 : Commande inconnue (Erreur 100)
# ============================================================================
print_test "Commande inconnue déclenche l'erreur 100"
./snapfile.sh delete /tmp/test_snapfile 2>/dev/null
EXIT_CODE=$?
assert_exit_code 100 $EXIT_CODE "Code d'erreur 100 pour commande inconnue"

# ============================================================================
# TEST 12 : Format du log
# ============================================================================
print_test "Format du log respecte le standard"
cleanup
mkdir -p /tmp/test_snapfile
mkdir -p /tmp/test_logs
./snapfile.sh -l /tmp/test_logs save /tmp/test_snapfile > /dev/null 2>&1

if [ -f "/tmp/test_logs/snapfile.log" ]; then
    # Vérifier le format : yyyy-mm-dd-hh-mm-ss: username: TYPE: message
    if grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}: [a-zA-Z0-9_]+: (INFOS|ERROR|WARNING):' /tmp/test_logs/snapfile.log > /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}: Format du log conforme"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Format du log non conforme"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗ FAIL${NC}: Impossible de vérifier le format (log absent)"
    ((TESTS_FAILED++))
fi

# ============================================================================
# RÉSUMÉ DES TESTS
# ============================================================================
echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                           RÉSUMÉ DES TESTS                               ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "Tests réussis : ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests échoués : ${RED}$TESTS_FAILED${NC}"
echo -e "Total         : $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ TOUS LES TESTS SONT PASSÉS !${NC}"
    echo -e "${GREEN}✓ Le Sprint 1 est prêt pour livraison au Membre 2${NC}"
    cleanup
    exit 0
else
    echo -e "${RED}✗ CERTAINS TESTS ONT ÉCHOUÉ${NC}"
    echo -e "${RED}✗ Veuillez corriger les erreurs avant la livraison${NC}"
    cleanup
    exit 1
fi
