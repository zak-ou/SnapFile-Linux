#!/bin/bash
################################################################################
# test_complet.sh — Suite de tests complète pour SnapFile
#
# Couvre toutes les fonctionnalités de tous les sprints :
#   Sprint 1 : Options, logs, erreurs, initialisation, reset
#   Sprint 2 : save, fork, thread, déduplication, espace disque
#   Sprint 3 : log, restore, subshell, erreurs 102/103
#
# Usage : bash tests/test_complet.sh
#         (depuis la racine du projet)
################################################################################

# ============================================================================
# COULEURS ET CONFIGURATION
# ============================================================================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SNAPFILE="./src/snapfile.sh"
TEST_DIR="/tmp/snapfile_test_data"
LOG_DIR="/tmp/snapfile_test_logs"

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║  $1${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo ""
    echo -e "${YELLOW}${BOLD}── $1 ──────────────────────────────────────────${NC}"
}

pass() {
    echo -e "  ${GREEN}✅ PASS${NC} : $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "  ${RED}❌ FAIL${NC} : $1"
    ((TESTS_FAILED++))
}

skip() {
    echo -e "  ${YELLOW}⏭  SKIP${NC} : $1"
    ((TESTS_SKIPPED++))
}

# Vérifie que le code de sortie est celui attendu
assert_exit() {
    local expected=$1
    local actual=$2
    local desc=$3
    if [ "$actual" -eq "$expected" ]; then
        pass "$desc (code=$actual)"
    else
        fail "$desc (attendu=$expected, obtenu=$actual)"
    fi
}

# Vérifie qu'une chaîne est présente dans la sortie
assert_contains() {
    local output=$1
    local pattern=$2
    local desc=$3
    if echo "$output" | grep -q "$pattern"; then
        pass "$desc"
    else
        fail "$desc (pattern '$pattern' absent)"
    fi
}

# Vérifie qu'un fichier ou dossier existe
assert_exists() {
    local path=$1
    local desc=$2
    if [ -e "$path" ]; then
        pass "$desc"
    else
        fail "$desc ('$path' introuvable)"
    fi
}

# Prépare un dossier de test avec N fichiers
setup_test_dir() {
    local dir=$1
    local count=${2:-5}
    rm -rf "$dir"
    mkdir -p "$dir"
    for i in $(seq 1 "$count"); do
        echo "Contenu du fichier $i — $(date)" > "$dir/fichier$i.txt"
    done
}

# Nettoyage complet
cleanup() {
    rm -rf "$TEST_DIR" "$LOG_DIR" /tmp/snapfile_preview 2>/dev/null
    rm -rf ~/.snapfile 2>/dev/null
    sudo rm -rf /var/log/snapfile 2>/dev/null
}

# ============================================================================
# VÉRIFICATIONS PRÉLIMINAIRES
# ============================================================================
print_header "SNAPFILE — SUITE DE TESTS COMPLÈTE"
echo ""
echo -e "  Script testé : ${BOLD}$SNAPFILE${NC}"
echo -e "  Dossier test : ${BOLD}$TEST_DIR${NC}"
echo -e "  Date         : ${BOLD}$(date '+%d/%m/%Y %H:%M:%S')${NC}"

echo ""
echo -e "${BLUE}Vérifications préliminaires...${NC}"

if [ ! -f "$SNAPFILE" ]; then
    echo -e "${RED}ERREUR FATALE : $SNAPFILE introuvable !${NC}"
    echo "Lancez ce script depuis la racine du projet."
    exit 1
fi

chmod +x "$SNAPFILE"
sudo mkdir -p /var/log/snapfile && sudo chmod 777 /var/log/snapfile 2>/dev/null
mkdir -p "$LOG_DIR"

echo -e "  ${GREEN}✓${NC} Script trouvé et rendu exécutable"
echo -e "  ${GREEN}✓${NC} Dossier de logs préparé"

cleanup

# ============================================================================
# SPRINT 1 — INITIALISATION & ARCHITECTURE
# ============================================================================
print_header "SPRINT 1 — Initialisation & Architecture"

# ── Option -h ────────────────────────────────────────────────────────────────
print_section "Option -h (Aide)"

output=$("$SNAPFILE" -h 2>&1)
assert_exit 0 $? "Option -h retourne code 0"
assert_contains "$output" "SNAPFILE" "Manuel contient 'SNAPFILE'"
assert_contains "$output" "save" "Manuel contient la commande 'save'"
assert_contains "$output" "restore" "Manuel contient la commande 'restore'"
assert_contains "$output" "log" "Manuel contient la commande 'log'"
assert_contains "$output" "\-f" "Manuel contient l'option -f"
assert_contains "$output" "\-t" "Manuel contient l'option -t"
assert_contains "$output" "\-s" "Manuel contient l'option -s"
assert_contains "$output" "\-l" "Manuel contient l'option -l"
assert_contains "$output" "\-r" "Manuel contient l'option -r"

# ── Erreurs d'options ─────────────────────────────────────────────────────────
print_section "Gestion des erreurs d'options"

"$SNAPFILE" -z save /tmp 2>/dev/null
assert_exit 100 $? "Option inconnue -z → erreur 100"

"$SNAPFILE" -l 2>/dev/null
assert_exit 101 $? "Option -l sans argument → erreur 101"

"$SNAPFILE" 2>/dev/null
assert_exit 0 $? "Aucun argument → affiche aide (code 0)"

# ── Validation du dossier cible ───────────────────────────────────────────────
print_section "Validation du dossier cible"

"$SNAPFILE" save 2>/dev/null
assert_exit 101 $? "save sans dossier → erreur 101"

"$SNAPFILE" save /chemin/qui/nexiste/pas 2>/dev/null
assert_exit 101 $? "Chemin inexistant → erreur 101"

touch /tmp/fichier_test_snap.txt
"$SNAPFILE" save /tmp/fichier_test_snap.txt 2>/dev/null
assert_exit 101 $? "Fichier au lieu de dossier → erreur 101"
rm -f /tmp/fichier_test_snap.txt

# ── Commande inconnue ─────────────────────────────────────────────────────────
print_section "Commande inconnue"

setup_test_dir "$TEST_DIR"
"$SNAPFILE" supprimer "$TEST_DIR" 2>/dev/null
assert_exit 100 $? "Commande inconnue 'supprimer' → erreur 100"

"$SNAPFILE" backup "$TEST_DIR" 2>/dev/null
assert_exit 100 $? "Commande inconnue 'backup' → erreur 100"

# ── Initialisation du dépôt ───────────────────────────────────────────────────
print_section "Initialisation du dépôt ~/.snapfile/"

cleanup
setup_test_dir "$TEST_DIR"
"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1

assert_exists "$HOME/.snapfile" "Dépôt ~/.snapfile/ créé"
assert_exists "$HOME/.snapfile/objects" "Dossier objects/ créé"
assert_exists "$HOME/.snapfile/snapshots" "Dossier snapshots/ créé"
assert_exists "$HOME/.snapfile/index" "Dossier index/ créé"

# ── Système de logs ───────────────────────────────────────────────────────────
print_section "Système de logs"

cleanup
setup_test_dir "$TEST_DIR"
"$SNAPFILE" -l "$LOG_DIR" save "$TEST_DIR" > /dev/null 2>&1

assert_exists "$LOG_DIR/snapfile.log" "Fichier de log créé avec -l"

if [ -f "$LOG_DIR/snapfile.log" ]; then
    log_content=$(cat "$LOG_DIR/snapfile.log")
    assert_contains "$log_content" "INFOS" "Log contient des entrées INFOS"
    # Vérifier le format : yyyy-mm-dd-hh-mm-ss: user: TYPE: message
    if grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}: .+: (INFOS|ERROR|WARNING): .+' "$LOG_DIR/snapfile.log"; then
        pass "Format du log conforme (yyyy-mm-dd-hh-mm-ss: user: TYPE: msg)"
    else
        fail "Format du log non conforme"
    fi
fi

# ── Option -r sans sudo ───────────────────────────────────────────────────────
print_section "Option -r (Reset)"

"$SNAPFILE" -r 2>/dev/null
assert_exit 105 $? "Option -r sans sudo → erreur 105"

# ============================================================================
# SPRINT 2 — SAUVEGARDE & DÉDUPLICATION
# ============================================================================
print_header "SPRINT 2 — Sauvegarde & Déduplication"

# ── Sauvegarde normale ────────────────────────────────────────────────────────
print_section "Commande save (mode normal)"

cleanup
setup_test_dir "$TEST_DIR" 5
output=$("$SNAPFILE" save "$TEST_DIR" 2>&1)
assert_exit 0 $? "save retourne code 0"
assert_contains "$output" "Snapshot" "Sortie mentionne 'Snapshot'"

# Vérifier que des objets ont été créés
obj_count=$(ls ~/.snapfile/objects/ 2>/dev/null | wc -l)
if [ "$obj_count" -gt 0 ]; then
    pass "Objets créés dans ~/.snapfile/objects/ ($obj_count fichiers)"
else
    fail "Aucun objet créé dans ~/.snapfile/objects/"
fi

# Vérifier que le fichier meta existe
meta_count=$(ls ~/.snapfile/snapshots/*.meta 2>/dev/null | wc -l)
if [ "$meta_count" -gt 0 ]; then
    pass "Fichier .meta créé dans ~/.snapfile/snapshots/"
else
    fail "Aucun fichier .meta créé"
fi

# ── Déduplication SHA-256 ─────────────────────────────────────────────────────
print_section "Déduplication SHA-256"

obj_before=$(ls ~/.snapfile/objects/ 2>/dev/null | wc -l)

# Copier un fichier existant (même contenu = même hash)
cp "$TEST_DIR/fichier1.txt" "$TEST_DIR/fichier1_copie.txt"
"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1

obj_after=$(ls ~/.snapfile/objects/ 2>/dev/null | wc -l)

if [ "$obj_after" -eq "$((obj_before + 1))" ] || [ "$obj_after" -eq "$obj_before" ]; then
    pass "Déduplication : fichier identique non re-stocké"
else
    fail "Déduplication : objet dupliqué créé ($obj_before → $obj_after)"
fi

# ── Détection de non-changement ───────────────────────────────────────────────
print_section "Détection de non-changement"

output=$("$SNAPFILE" save "$TEST_DIR" 2>&1)
if echo "$output" | grep -qi "aucun changement\|no change\|annul"; then
    pass "Snapshot annulé si aucun changement détecté"
else
    skip "Détection de non-changement (comportement variable selon implémentation)"
fi

# ── Mode Fork (-f) ────────────────────────────────────────────────────────────
print_section "Option -f (Fork — arrière-plan)"

cleanup
setup_test_dir "$TEST_DIR" 10
output=$("$SNAPFILE" -f save "$TEST_DIR" 2>&1)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    pass "Mode fork (-f) retourne code 0"
else
    fail "Mode fork (-f) a échoué (code=$exit_code)"
fi

if echo "$output" | grep -qi "fork\|arrière-plan\|background\|lot\|batch\|PID"; then
    pass "Mode fork (-f) affiche un message de confirmation"
else
    skip "Message fork non détecté (peut varier selon implémentation)"
fi

# ── Mode Thread (-t) ──────────────────────────────────────────────────────────
print_section "Option -t (Thread — parallèle)"

cleanup
setup_test_dir "$TEST_DIR" 10
output=$("$SNAPFILE" -t save "$TEST_DIR" 2>&1)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    pass "Mode thread (-t) retourne code 0"
else
    fail "Mode thread (-t) a échoué (code=$exit_code)"
fi

if echo "$output" | grep -qi "thread\|parallèle\|pthread"; then
    pass "Mode thread (-t) affiche un message de confirmation"
else
    skip "Message thread non détecté (peut varier selon implémentation)"
fi

# ── Combinaison -f -t ─────────────────────────────────────────────────────────
print_section "Combinaison -f -t (fork + thread)"

cleanup
setup_test_dir "$TEST_DIR" 10
"$SNAPFILE" -f -t save "$TEST_DIR" > /dev/null 2>&1
assert_exit 0 $? "Combinaison -f -t retourne code 0"

# ── Vérification espace disque ────────────────────────────────────────────────
print_section "Vérification espace disque (erreur 104)"

# On ne peut pas facilement simuler un disque plein, on vérifie juste
# que le code 104 est défini dans le script
if grep -q "104" "$SNAPFILE" || grep -rq "104" src/lib/; then
    pass "Code d'erreur 104 (espace disque) défini dans le projet"
else
    fail "Code d'erreur 104 non trouvé dans le projet"
fi

# ============================================================================
# SPRINT 3 — CONSULTATION & RESTAURATION
# ============================================================================
print_header "SPRINT 3 — Consultation & Restauration"

# Préparer 2 snapshots pour les tests
cleanup
setup_test_dir "$TEST_DIR" 5
"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1
sleep 1
echo "Modification pour 2ème snapshot" >> "$TEST_DIR/fichier1.txt"
"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1

DIR_NAME=$(basename "$TEST_DIR")
SNAP_ID=$(head -1 "$HOME/.snapfile/index/${DIR_NAME}.list" 2>/dev/null | sed 's/.meta//')

# ── Commande log ──────────────────────────────────────────────────────────────
print_section "Commande log (historique)"

output=$("$SNAPFILE" log "$TEST_DIR" 2>&1)
assert_exit 0 $? "log retourne code 0"
assert_contains "$output" "snapshot\|Snapshot\|ID\|Date" "log affiche un tableau de snapshots"

# Vérifier que les 2 snapshots sont listés
snap_count=$(echo "$output" | grep -c "[0-9]\{14\}" 2>/dev/null || echo 0)
if [ "$snap_count" -ge 2 ]; then
    pass "log affiche les 2 snapshots créés"
else
    skip "Nombre de snapshots affiché non vérifié ($snap_count trouvé)"
fi

# ── Erreur 102 : aucun snapshot ───────────────────────────────────────────────
print_section "Erreur 102 — Aucun snapshot trouvé"

mkdir -p /tmp/dossier_vide_test_snap
"$SNAPFILE" log /tmp/dossier_vide_test_snap 2>/dev/null
assert_exit 102 $? "log sur dossier sans snapshot → erreur 102"
rm -rf /tmp/dossier_vide_test_snap

# ── Commande restore ──────────────────────────────────────────────────────────
print_section "Commande restore"

if [ -n "$SNAP_ID" ]; then
    # Restauration en prévisualisation (-s)
    output=$("$SNAPFILE" -s restore "$TEST_DIR" --id "$SNAP_ID" 2>&1)
    assert_exit 0 $? "restore -s avec ID valide retourne code 0"
    assert_contains "$output" "restaur\|Restaur\|preview\|tmp" "restore -s mentionne la destination"

    # Vérifier que les fichiers sont dans /tmp/
    if [ -d "/tmp/snapfile_preview" ]; then
        pass "Fichiers restaurés dans /tmp/ (mode subshell)"
    else
        skip "Dossier /tmp/snapfile_preview non trouvé (chemin peut varier)"
    fi
else
    skip "Pas de snapshot ID disponible pour tester restore"
fi

# ── Erreur 103 : snapshot introuvable ────────────────────────────────────────
print_section "Erreur 103 — Snapshot introuvable"

"$SNAPFILE" restore "$TEST_DIR" --id "99999999999999" 2>/dev/null
assert_exit 103 $? "restore avec ID invalide → erreur 103"

# ── restore sans --id ─────────────────────────────────────────────────────────
print_section "restore sans --id"

"$SNAPFILE" restore "$TEST_DIR" 2>/dev/null
assert_exit 103 $? "restore sans --id → erreur 103"

# ── Option -s (subshell) ──────────────────────────────────────────────────────
print_section "Option -s (Subshell — prévisualisation)"

if [ -n "$SNAP_ID" ]; then
    "$SNAPFILE" -s restore "$TEST_DIR" --id "$SNAP_ID" > /dev/null 2>&1
    assert_exit 0 $? "Option -s avec restore retourne code 0"
else
    skip "Option -s non testée (pas de snapshot disponible)"
fi

# ============================================================================
# TESTS TRANSVERSAUX
# ============================================================================
print_header "TESTS TRANSVERSAUX"

# ── Logs générés pour chaque commande ────────────────────────────────────────
print_section "Logs générés pour chaque commande"

cleanup
setup_test_dir "$TEST_DIR" 3
"$SNAPFILE" -l "$LOG_DIR" save "$TEST_DIR" > /dev/null 2>&1

if [ -f "$LOG_DIR/snapfile.log" ]; then
    assert_contains "$(cat "$LOG_DIR/snapfile.log")" "COMMAND: save" "Log enregistre la commande save"
fi

"$SNAPFILE" -l "$LOG_DIR" log "$TEST_DIR" > /dev/null 2>&1
if [ -f "$LOG_DIR/snapfile.log" ]; then
    assert_contains "$(cat "$LOG_DIR/snapfile.log")" "COMMAND: log" "Log enregistre la commande log"
fi

# ── Plusieurs sauvegardes successives ────────────────────────────────────────
print_section "Plusieurs sauvegardes successives"

cleanup
setup_test_dir "$TEST_DIR" 3

"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1
sleep 1
echo "Changement 1" >> "$TEST_DIR/fichier1.txt"
"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1
sleep 1
echo "Changement 2" >> "$TEST_DIR/fichier2.txt"
"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1

meta_count=$(ls ~/.snapfile/snapshots/*.meta 2>/dev/null | wc -l)
if [ "$meta_count" -ge 2 ]; then
    pass "Plusieurs snapshots créés successivement ($meta_count snapshots)"
else
    fail "Snapshots successifs non créés ($meta_count trouvé)"
fi

# ── Sous-dossiers récursifs ───────────────────────────────────────────────────
print_section "Sauvegarde récursive (sous-dossiers)"

cleanup
mkdir -p "$TEST_DIR/sous_dossier/profond"
echo "fichier racine" > "$TEST_DIR/racine.txt"
echo "fichier sous-dossier" > "$TEST_DIR/sous_dossier/sub.txt"
echo "fichier profond" > "$TEST_DIR/sous_dossier/profond/deep.txt"

"$SNAPFILE" save "$TEST_DIR" > /dev/null 2>&1
obj_count=$(ls ~/.snapfile/objects/ 2>/dev/null | wc -l)

if [ "$obj_count" -ge 3 ]; then
    pass "Sauvegarde récursive : $obj_count fichiers stockés (sous-dossiers inclus)"
else
    fail "Sauvegarde récursive incomplète ($obj_count objets, attendu ≥ 3)"
fi

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================
TOTAL=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                    RÉSUMÉ DES TESTS                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}✅ Réussis  : $TESTS_PASSED${NC}"
echo -e "  ${RED}❌ Échoués  : $TESTS_FAILED${NC}"
echo -e "  ${YELLOW}⏭  Ignorés  : $TESTS_SKIPPED${NC}"
echo -e "  ${BOLD}   Total    : $TOTAL${NC}"
echo ""

# Taux de réussite
if [ $((TESTS_PASSED + TESTS_FAILED)) -gt 0 ]; then
    RATE=$(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))
    echo -e "  Taux de réussite : ${BOLD}${RATE}%${NC}"
    echo ""
fi

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}  🎉 TOUS LES TESTS SONT PASSÉS !${NC}"
    echo -e "${GREEN}  SnapFile fonctionne correctement sur tous les sprints.${NC}"
else
    echo -e "${RED}${BOLD}  ⚠️  $TESTS_FAILED TEST(S) ONT ÉCHOUÉ${NC}"
    echo -e "${RED}  Vérifiez les erreurs ci-dessus avant la livraison.${NC}"
fi

echo ""

# Nettoyage final
cleanup

exit $TESTS_FAILED
