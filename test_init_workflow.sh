#!/bin/bash
# Test du nouveau workflow avec init obligatoire

echo "=== TEST 1 : Essayer save SANS init ==="
rm -rf ~/.snapfile
mkdir -p /tmp/test_projet
echo "test" > /tmp/test_projet/fichier.txt

./src/snapfile.sh save /tmp/test_projet 2>&1 | head -10

echo ""
echo "=== TEST 2 : Initialiser avec init ==="
./src/snapfile.sh init

echo ""
echo "=== TEST 3 : Maintenant save devrait fonctionner ==="
./src/snapfile.sh save /tmp/test_projet

echo ""
echo "=== TEST 4 : Refaire init (doit afficher les stats) ==="
./src/snapfile.sh init

echo ""
echo "=== Nettoyage ==="
rm -rf ~/.snapfile /tmp/test_projet
