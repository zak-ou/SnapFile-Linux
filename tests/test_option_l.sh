#!/bin/bash
################################################################################
# test_option_l.sh — Test de l'option -l (logs personnalisés)
################################################################################

set -e

echo "=========================================="
echo "TEST : Option -l (Logs Personnalisés)"
echo "=========================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
TESTS_PASSED=0
TESTS_FAILED=0

# Fonction de test
test_case() {
    local test_name="$1"
    echo -e "${YELLOW}[TEST]${NC} $test_name"
}

pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
    echo ""
}

fail() {
    local message="$1"
    echo -e "${RED}✗ FAIL${NC}: $message"
    ((TESTS_FAILED++))
    echo ""
}

# Nettoyage initial
echo "Nettoyage initial..."
rm -rf ~/.snapfile
rm -rf /tmp/test_logs
rm -rf /tmp/test_projet_l
echo ""

# ============================================================================
# TEST 1 : Initialisation avec logs par défaut
# ============================================================================
test_case "1. Init avec logs par défaut"

./src/snapfile.sh init > /dev/null 2>&1

if [[ -f ~/.snapfile/history.log ]]; then
    pass
else
    fail "Fichier de log par défaut non créé"
fi

# ============================================================================
# TEST 2 : Save avec logs personnalisés (-l)
# ============================================================================
test_case "2. Save avec -l /tmp/test_logs"

# Créer un projet de test
mkdir -p /tmp/test_projet_l
echo "contenu1" > /tmp/test_projet_l/file1.txt
echo "contenu2" > /tmp/test_projet_l/file2.txt

# Sauvegarder avec logs personnalisés
./src/snapfile.sh -l /tmp/test_logs save /tmp/test_projet_l > /dev/null 2>&1

if [[ -f /tmp/test_logs/snapfile.log ]]; then
    echo "✓ Fichier de log créé : /tmp/test_logs/snapfile.log"
    
    # Vérifier le contenu
    if grep -q "COMMAND: save /tmp/test_projet_l" /tmp/test_logs/snapfile.log; then
        echo "✓ Log contient la commande save"
    else
        fail "Log ne contient pas la commande save"
        cat /tmp/test_logs/snapfile.log
        exit 1
    fi
    
    if grep -q "SNAPSHOT_CREATED" /tmp/test_logs/snapfile.log; then
        echo "✓ Log contient SNAPSHOT_CREATED"
    else
        fail "Log ne contient pas SNAPSHOT_CREATED"
        cat /tmp/test_logs/snapfile.log
        exit 1
    fi
    
    pass
else
    fail "Fichier de log personnalisé non créé"
    ls -la /tmp/test_logs/ 2>&1 || echo "Répertoire /tmp/test_logs/ n'existe pas"
fi

# ============================================================================
# TEST 3 : Log avec -l
# ============================================================================
test_case "3. Log avec -l /tmp/test_logs"

./src/snapfile.sh -l /tmp/test_logs log /tmp/test_projet_l > /dev/null 2>&1

if grep -q "COMMAND: log /tmp/test_projet_l" /tmp/test_logs/snapfile.log; then
    echo "✓ Log contient la commande log"
    pass
else
    fail "Log ne contient pas la commande log"
fi

# ============================================================================
# TEST 4 : Logs dans le répertoire courant
# ============================================================================
test_case "4. Save avec -l . (répertoire courant)"

./src/snapfile.sh -l . save /tmp/test_projet_l > /dev/null 2>&1

if [[ -f ./snapfile.log ]]; then
    echo "✓ Fichier de log créé dans le répertoire courant"
    
    if grep -q "COMMAND: save /tmp/test_projet_l" ./snapfile.log; then
        echo "✓ Log contient la commande save"
        pass
    else
        fail "Log ne contient pas la commande save"
    fi
    
    rm -f ./snapfile.log
else
    fail "Fichier de log non créé dans le répertoire courant"
fi

# ============================================================================
# TEST 5 : Logs dans un sous-répertoire
# ============================================================================
test_case "5. Save avec -l ~/mes_logs/projet_A"

./src/snapfile.sh -l ~/mes_logs/projet_A save /tmp/test_projet_l > /dev/null 2>&1

if [[ -f ~/mes_logs/projet_A/snapfile.log ]]; then
    echo "✓ Fichier de log créé dans ~/mes_logs/projet_A/"
    
    if grep -q "COMMAND: save /tmp/test_projet_l" ~/mes_logs/projet_A/snapfile.log; then
        echo "✓ Log contient la commande save"
        pass
    else
        fail "Log ne contient pas la commande save"
    fi
else
    fail "Fichier de log non créé dans ~/mes_logs/projet_A/"
fi

# ============================================================================
# TEST 6 : Vérifier que les logs par défaut ne sont pas affectés
# ============================================================================
test_case "6. Save sans -l (logs par défaut)"

# Créer un nouveau projet
mkdir -p /tmp/test_projet_l2
echo "contenu" > /tmp/test_projet_l2/file.txt

./src/snapfile.sh save /tmp/test_projet_l2 > /dev/null 2>&1

if [[ -f ~/.snapfile/history.log ]]; then
    echo "✓ Logs par défaut toujours utilisés"
    
    if grep -q "COMMAND: save /tmp/test_projet_l2" ~/.snapfile/history.log; then
        echo "✓ Log par défaut contient la nouvelle commande"
        pass
    else
        fail "Log par défaut ne contient pas la nouvelle commande"
    fi
else
    fail "Fichier de log par défaut non trouvé"
fi

# ============================================================================
# RÉSUMÉ
# ============================================================================
echo "=========================================="
echo "RÉSUMÉ DES TESTS"
echo "=========================================="
echo -e "${GREEN}Tests réussis : $TESTS_PASSED${NC}"
echo -e "${RED}Tests échoués  : $TESTS_FAILED${NC}"
echo ""

# Nettoyage final
echo "Nettoyage final..."
rm -rf /tmp/test_logs
rm -rf /tmp/test_projet_l
rm -rf /tmp/test_projet_l2
rm -rf ~/mes_logs
rm -f ./snapfile.log

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ Tous les tests sont passés !${NC}"
    exit 0
else
    echo -e "${RED}✗ Certains tests ont échoué${NC}"
    exit 1
fi
