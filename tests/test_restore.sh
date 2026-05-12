#!/bin/bash
# Script de test pour la commande RESTORE

echo "--- DÉBUT DES TESTS DE RESTAURATION ---"

# On récupère l'ID du dernier snapshot du dossier léger
LAST_ID=$(./src/snapfile.sh log ~/tests/leger | grep "ID:" | head -n 1 | awk '{print $2}')

if [ -z "$LAST_ID" ]; then
    echo "Erreur : Aucun snapshot trouvé. Lancez test_save.sh d'abord."
    exit 1
fi

echo "Restauration du snapshot $LAST_ID..."
./src/snapfile.sh restore ~/tests/leger --id $LAST_ID

echo "Vérification de l'intégrité..."
# Comparaison bit à bit (optionnel selon ton script)
if [ $? -eq 0 ]; then
    echo "SUCCÈS : Le dossier a été restauré avec succès."
else
    echo "ÉCHEC : Erreur lors de la restauration."
fi