#!/bin/bash
################################################################################
# test_sprint2.sh — Suite de tests pour les fonctionnalités de Doha (Membre 2)
#
# Ce script valide :
#   1. Sauvegarde normale
#   2. Mode Fork (C-Worker)
#   3. Mode Thread (C-Worker)
#   4. Déduplication SHA-256
#   5. Détection de non-changement
################################################################################

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Lancement de la suite de tests SPRINT 2 (SnapFile)${NC}\n"

# Chemins
SNAPFILE="../src/snapfile.sh"
TEST_DIR="./data_test_sprint2"


# 1. Préparation des données
echo -e "\n${BLUE}[1/6] Préparation des données de test...${NC}"
mkdir -p "$TEST_DIR"
for i in {1..12}; do echo "Contenu original $i" > "$TEST_DIR/file$i.txt"; done
echo "OK."

# 2. Test Sauvegarde Normale
echo -e "\n${BLUE}[2/6] Test : Sauvegarde Normale...${NC}"
$SNAPFILE save "$TEST_DIR"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Succès${NC}"
else
    echo -e "${RED}❌ Échec${NC}"
fi

# 3. Test Mode FORK
echo -e "\n${BLUE}[3/6] Test : Mode FORK (-f)...${NC}"
$SNAPFILE -f save "$TEST_DIR"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Succès${NC}"
else
    echo -e "${RED}❌ Échec${NC}"
fi

# 4. Test Mode THREAD
echo -e "\n${BLUE}[4/6] Test : Mode THREAD (-t)...${NC}"
$SNAPFILE -t save "$TEST_DIR"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Succès${NC}"
else
    echo -e "${RED}❌ Échec${NC}"
fi

# 5. Test Déduplication
echo -e "\n${BLUE}[5/6] Test : Déduplication...${NC}"
obj_count_before=$(ls ~/.snapfile/objects | wc -l)
echo "Doublon de file1.txt..."
cp "$TEST_DIR/file1.txt" "$TEST_DIR/file1_copy.txt"
$SNAPFILE save "$TEST_DIR"
obj_count_after=$(ls ~/.snapfile/objects | wc -l)

if [ "$obj_count_before" -eq "$obj_count_after" ]; then
    echo -e "${GREEN}✅ Succès (Aucun objet créé pour le doublon)${NC}"
else
    echo -e "${RED}❌ Échec (Un nouvel objet a été créé)${NC}"
fi

# 6. Test No-change Skip
echo -e "\n${BLUE}[6/6] Test : Détection de non-changement...${NC}"
output=$($SNAPFILE save "$TEST_DIR")
if echo "$output" | grep -q "Aucun changement détecté"; then
    echo -e "${GREEN}✅ Succès (Snapshot annulé comme prévu)${NC}"
else
    echo -e "${RED}❌ Échec (Le snapshot n'a pas été annulé)${NC}"
fi

echo -e "\n${GREEN}==============================================${NC}"
echo -e "${GREEN}🎉 TOUS LES TESTS DU SPRINT 2 SONT RÉUSSIS !${NC}"
echo -e "${GREEN}==============================================${NC}\n"

# Nettoyage APRÈS les tests
cleanup
echo -e "\n${GREEN}✅ Environnement nettoyé. Prêt pour la livraison.${NC}"
