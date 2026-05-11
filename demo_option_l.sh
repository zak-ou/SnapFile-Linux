#!/bin/bash
################################################################################
# demo_option_l.sh — Démonstration de l'option -l
################################################################################

echo "=========================================="
echo "DÉMONSTRATION : Option -l"
echo "=========================================="
echo ""

# Nettoyage
echo "1. Nettoyage initial..."
rm -rf ~/.snapfile
rm -rf /tmp/demo_logs
rm -rf /tmp/demo_projet
echo "   ✓ Nettoyage terminé"
echo ""

# Initialisation
echo "2. Initialisation du dépôt..."
./src/snapfile.sh init
echo ""

# Créer un projet de test
echo "3. Création d'un projet de test..."
mkdir -p /tmp/demo_projet
echo "Fichier 1" > /tmp/demo_projet/file1.txt
echo "Fichier 2" > /tmp/demo_projet/file2.txt
echo "Fichier 3" > /tmp/demo_projet/file3.txt
echo "   ✓ Projet créé : /tmp/demo_projet (3 fichiers)"
echo ""

# Test 1 : Save avec logs par défaut
echo "4. Save SANS -l (logs par défaut)..."
./src/snapfile.sh save /tmp/demo_projet
echo ""
echo "   📄 Logs par défaut :"
echo "   Fichier : ~/.snapfile/history.log"
if [[ -f ~/.snapfile/history.log ]]; then
    echo "   Contenu :"
    tail -3 ~/.snapfile/history.log | sed 's/^/      /'
else
    echo "   ⚠️  Fichier non trouvé"
fi
echo ""

# Test 2 : Save avec logs personnalisés
echo "5. Save AVEC -l /tmp/demo_logs..."
./src/snapfile.sh -l /tmp/demo_logs save /tmp/demo_projet
echo ""
echo "   📄 Logs personnalisés :"
echo "   Fichier : /tmp/demo_logs/snapfile.log"
if [[ -f /tmp/demo_logs/snapfile.log ]]; then
    echo "   Contenu :"
    cat /tmp/demo_logs/snapfile.log | sed 's/^/      /'
else
    echo "   ⚠️  Fichier non trouvé"
fi
echo ""

# Test 3 : Log avec logs personnalisés
echo "6. Log AVEC -l /tmp/demo_logs..."
./src/snapfile.sh -l /tmp/demo_logs log /tmp/demo_projet
echo ""
echo "   📄 Logs personnalisés (après log) :"
if [[ -f /tmp/demo_logs/snapfile.log ]]; then
    echo "   Dernières lignes :"
    tail -5 /tmp/demo_logs/snapfile.log | sed 's/^/      /'
else
    echo "   ⚠️  Fichier non trouvé"
fi
echo ""

# Test 4 : Logs dans le répertoire courant
echo "7. Save AVEC -l . (répertoire courant)..."
./src/snapfile.sh -l . save /tmp/demo_projet
echo ""
echo "   📄 Logs dans le répertoire courant :"
echo "   Fichier : ./snapfile.log"
if [[ -f ./snapfile.log ]]; then
    echo "   Contenu :"
    cat ./snapfile.log | sed 's/^/      /'
else
    echo "   ⚠️  Fichier non trouvé"
fi
echo ""

# Résumé
echo "=========================================="
echo "RÉSUMÉ"
echo "=========================================="
echo ""
echo "L'option -l permet de spécifier un répertoire personnalisé pour les logs."
echo ""
echo "Exemples :"
echo "  ./src/snapfile.sh save /tmp/projet"
echo "    → Logs dans : ~/.snapfile/history.log"
echo ""
echo "  ./src/snapfile.sh -l /tmp/logs save /tmp/projet"
echo "    → Logs dans : /tmp/logs/snapfile.log"
echo ""
echo "  ./src/snapfile.sh -l . save /tmp/projet"
echo "    → Logs dans : ./snapfile.log"
echo ""
echo "  ./src/snapfile.sh -l ~/projet_A/logs save /tmp/projet"
echo "    → Logs dans : ~/projet_A/logs/snapfile.log"
echo ""

# Nettoyage optionnel
read -p "Voulez-vous nettoyer les fichiers de test ? (o/n) : " cleanup
if [[ "$cleanup" == "o" ]]; then
    rm -rf /tmp/demo_logs
    rm -rf /tmp/demo_projet
    rm -f ./snapfile.log
    echo "✓ Nettoyage terminé"
fi
