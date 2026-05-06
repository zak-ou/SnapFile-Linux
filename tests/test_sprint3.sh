#!/bin/bash
################################################################################
# test_sprint3.sh — Tests pour cmd_log() et cmd_restore()
################################################################################

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SNAPFILE="../src/snapfile.sh"
TEST_DIR="./data_test_sprint3"

echo -e "${BLUE}Tests SPRINT 3 — cmd_log() et cmd_restore()${NC}\n"

# Préparation
mkdir -p "$TEST_DIR"
for i in {1..5}; do echo "Fichier $i" > "$TEST_DIR/file$i.txt"; done

# Créer 2 snapshots
echo -e "${BLUE}[SETUP] Création de 2 snapshots...${NC}"
bash "$SNAPFILE" save "$TEST_DIR" > /dev/null
sleep 1
echo "Modification" >> "$TEST_DIR/file1.txt"
bash "$SNAPFILE" save "$TEST_DIR" > /dev/null
echo "OK."

# Test 1 : cmd_log affiche des snapshots
echo -e "\n${BLUE}[1/4] Test : cmd_log affiche l'historique...${NC}"
output=$(bash "$SNAPFILE" log "$TEST_DIR")
if echo "$output" | grep -q "snapshot"; then
    echo -e "${GREEN}✅ Succès${NC}"
else
    echo -e "${RED}❌ Échec — sortie : $output${NC}"
fi

# Test 2 : cmd_log sur dossier sans snapshots → erreur 102
echo -e "\n${BLUE}[2/4] Test : cmd_log dossier sans snapshots → erreur 102...${NC}"
mkdir -p "/tmp/dossier_vide_test"
bash "$SNAPFILE" log "/tmp/dossier_vide_test" 2>/dev/null
if [ $? -eq 102 ]; then
    echo -e "${GREEN}✅ Succès (code 102 retourné)${NC}"
else
    echo -e "${RED}❌ Échec${NC}"
fi

# Test 3 : cmd_restore avec un ID valide
echo -e "\n${BLUE}[3/4] Test : cmd_restore avec ID valide...${NC}"
DIR_NAME=$(basename "$TEST_DIR")
SNAP_ID=$(head -1 "$HOME/.snapfile/index/${DIR_NAME}.list" | sed 's/.meta//')

mkdir -p "/tmp/test_restore"
output=$(bash "$SNAPFILE" -s restore "$TEST_DIR" --id "$SNAP_ID" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Succès${NC}"
else
    echo -e "${RED}❌ Échec — $output${NC}"
fi

# Test 4 : cmd_restore avec ID invalide → erreur 103
echo -e "\n${BLUE}[4/4] Test : cmd_restore ID invalide → erreur 103...${NC}"
bash "$SNAPFILE" restore "$TEST_DIR" --id "99999999999999" 2>/dev/null
if [ $? -eq 103 ]; then
    echo -e "${GREEN}✅ Succès (code 103 retourné)${NC}"
else
    echo -e "${RED}❌ Échec${NC}"
fi

# Nettoyage
rm -rf "$TEST_DIR" "/tmp/dossier_vide_test"

echo -e "\n${GREEN}=== Tests Sprint 3 terminés ===${NC}\n"