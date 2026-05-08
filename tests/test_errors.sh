#!/bin/bash
# Script de Test des Erreurs Complet - Mohamed Zaid Zagour

# Couleurs pour le rapport
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "--- DÉBUT DE VALIDATION DES CODES D'ERREUR ---"

# --- CODE 100 : Option Inconnue ---
./src/snapfile.sh -z save . >/dev/null 2>&1
if [ $? -eq 100 ]; then echo -e "Code 100 (-z inconnu) : ${GREEN}VALIDE${NC}"; fi

# --- CODE 101 : Paramètre Manquant ---
./src/snapfile.sh save >/dev/null 2>&1
if [ $? -eq 101 ]; then echo -e "Code 101 (Dossier absent) : ${GREEN}VALIDE${NC}"; fi

# --- CODE 102 : Pas d'historique ---
# On simule en demandant un log sur un dossier jamais sauvegardé
./src/snapfile.sh log /tmp/dossier_fantome >/dev/null 2>&1
if [ $? -eq 102 ]; then echo -e "Code 102 (Pas d'historique) : ${GREEN}VALIDE${NC}"; fi

# --- CODE 103 : ID Introuvable ---
./src/snapfile.sh restore . --id 999999 >/dev/null 2>&1
if [ $? -eq 103 ]; then echo -e "Code 103 (ID inexistant) : ${GREEN}VALIDE${NC}"; fi

# --- CODE 105 : Conflit d'options ---
./src/snapfile.sh -f -t save . >/dev/null 2>&1
if [ $? -eq 105 ]; then echo -e "Code 105 (Fork + Thread) : ${GREEN}VALIDE${NC}"; fi

echo -e "--- FIN DE LA VALIDATION ---"