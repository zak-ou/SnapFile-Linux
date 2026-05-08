#!/bin/bash
# Script de test automatisé pour la commande SAVE

echo "--- DÉBUT DES TESTS DE SAUVEGARDE ---"

# 1. Scénario Léger
echo "[1/3] Test Léger (10 Ko)..."
mkdir -p ~/tests/leger
head -c 10K /dev/urandom > ~/tests/leger/note.txt
./src/snapfile.sh save ~/tests/leger

# 2. Scénario Moyen (Mode Fork)
echo "[2/3] Test Moyen (25 Mo) avec Fork..."
mkdir -p ~/tests/moyen
for i in {1..15}; do head -c 1.6M /dev/urandom > ~/tests/moyen/doc$i.pdf 2>/dev/null || head -c 1600K /dev/urandom > ~/tests/moyen/doc$i.pdf; done
time ./src/snapfile.sh -f save ~/tests/moyen

# 3. Scénario Lourd (Mode Thread)
echo "[3/3] Test Lourd (500 Mo) avec Threads..."
mkdir -p ~/tests/lourd
for i in {1..50}; do head -c 10M /dev/urandom > ~/tests/lourd/data$i.bin; done
time ./src/snapfile.sh -t save ~/tests/lourd

echo "--- TESTS DE SAUVEGARDE TERMINÉS ---"