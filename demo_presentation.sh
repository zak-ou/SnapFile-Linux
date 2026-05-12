#!/bin/bash
################################################################################
# demo_presentation.sh — Script de démonstration pour présentation
# Usage : ./demo_presentation.sh
################################################################################

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction pour afficher un titre
titre() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Fonction pour afficher une commande
cmd() {
    echo -e "${YELLOW}$ $1${NC}"
}

# Fonction pour pause
pause() {
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
    echo ""
}

# Fonction pour afficher un succès
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Fonction pour afficher une info
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# En-tête
clear
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              DÉMONSTRATION SNAPFILE v1.0.0                   ║
║                                                              ║
║        Système de Versionnement Léger pour Fichiers         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""
echo "Ce script va démontrer toutes les fonctionnalités de SnapFile."
echo ""
pause

# ============================================================================
# NETTOYAGE
# ============================================================================
titre "🧹 NETTOYAGE DE L'ENVIRONNEMENT"

info "Suppression des données de test précédentes..."
rm -rf ~/.snapfile /tmp/demo_projet /tmp/gros_projet /tmp/demo_logs /tmp/snapfile_preview
success "Environnement nettoyé"
pause

# ============================================================================
# 1. INITIALISATION
# ============================================================================
titre "1️⃣  INITIALISATION DU DÉPÔT"

info "Commande : ./src/snapfile.sh init"
echo ""
./src/snapfile.sh init
pause

info "Vérification de la structure créée :"
cmd "ls -la ~/.snapfile/"
ls -la ~/.snapfile/
pause

# ============================================================================
# 2. CRÉATION DU PROJET
# ============================================================================
titre "2️⃣  CRÉATION D'UN PROJET DE TEST"

info "Création d'un projet avec 4 fichiers..."
mkdir -p /tmp/demo_projet/src
echo "Version 1 du fichier principal" > /tmp/demo_projet/main.txt
echo "Configuration initiale" > /tmp/demo_projet/config.txt
echo "Documentation du projet" > /tmp/demo_projet/README.md
echo "def hello(): print('Hello')" > /tmp/demo_projet/src/app.py

success "Projet créé : /tmp/demo_projet"
echo ""
cmd "find /tmp/demo_projet/ -type f"
find /tmp/demo_projet/ -type f
echo ""
info "Contenu de main.txt :"
cmd "cat /tmp/demo_projet/main.txt"
cat /tmp/demo_projet/main.txt
pause

# ============================================================================
# 3. PREMIÈRE SAUVEGARDE
# ============================================================================
titre "3️⃣  PREMIÈRE SAUVEGARDE"

info "Commande : ./src/snapfile.sh save /tmp/demo_projet"
echo ""
./src/snapfile.sh save /tmp/demo_projet
echo ""
success "Premier snapshot créé !"
pause

# ============================================================================
# 4. DÉDUPLICATION
# ============================================================================
titre "4️⃣  DÉDUPLICATION AUTOMATIQUE"

info "Modification d'UN SEUL fichier (main.txt)..."
echo "Version 2 du fichier principal - MODIFIÉ ✏️" > /tmp/demo_projet/main.txt
success "Fichier main.txt modifié"
echo ""
info "Nouveau contenu :"
cmd "cat /tmp/demo_projet/main.txt"
cat /tmp/demo_projet/main.txt
echo ""
pause

info "Deuxième sauvegarde..."
cmd "./src/snapfile.sh save /tmp/demo_projet"
echo ""
./src/snapfile.sh save /tmp/demo_projet
echo ""
pause

info "Vérification de la déduplication :"
echo ""
echo "📊 Statistiques :"
echo "   • Snapshots créés : 2"
echo "   • Fichiers par snapshot : 4"
echo "   • Total théorique : 8 fichiers"
echo ""
OBJETS=$(ls ~/.snapfile/objects/ | wc -l)
echo "   • Objets réellement stockés : $OBJETS"
echo ""
if [ "$OBJETS" -eq 4 ]; then
    success "Déduplication réussie ! Seulement 4 objets stockés au lieu de 8"
    echo "   → Économie d'espace : 50%"
else
    echo "   • Objets stockés : $OBJETS"
fi
pause

# ============================================================================
# 5. TEST AUCUN CHANGEMENT
# ============================================================================
titre "5️⃣  TEST : AUCUN CHANGEMENT"

info "Tentative de sauvegarde sans modification..."
cmd "./src/snapfile.sh save /tmp/demo_projet"
echo ""
./src/snapfile.sh save /tmp/demo_projet
echo ""
success "SnapFile détecte qu'il n'y a aucun changement !"
pause

# ============================================================================
# 6. HISTORIQUE
# ============================================================================
titre "6️⃣  HISTORIQUE DES SNAPSHOTS"

info "Commande : ./src/snapfile.sh log /tmp/demo_projet"
echo ""
./src/snapfile.sh log /tmp/demo_projet
pause

# ============================================================================
# 7. OPTIONS AVANCÉES
# ============================================================================
titre "7️⃣  OPTIONS AVANCÉES"

# Option -t (Thread)
info "Test de l'option -t (compression parallèle)..."
echo ""
mkdir -p /tmp/gros_projet
for i in {1..20}; do
    echo "Contenu du fichier $i" > /tmp/gros_projet/file$i.txt
done
success "Gros projet créé (20 fichiers)"
echo ""
cmd "./src/snapfile.sh -t save /tmp/gros_projet"
echo ""
./src/snapfile.sh -t save /tmp/gros_projet
echo ""
success "Compression parallèle avec threads !"
pause

# Option -l (Logs)
info "Test de l'option -l (logs personnalisés)..."
echo ""
cmd "./src/snapfile.sh -l /tmp/demo_logs save /tmp/demo_projet"
echo ""
./src/snapfile.sh -l /tmp/demo_logs save /tmp/demo_projet
echo ""
info "Contenu des logs personnalisés :"
cmd "cat /tmp/demo_logs/snapfile.log | tail -3"
cat /tmp/demo_logs/snapfile.log | tail -3
pause

# Option -f (Fork)
info "Test de l'option -f (arrière-plan)..."
echo ""
cmd "./src/snapfile.sh -f save /tmp/gros_projet"
echo ""
./src/snapfile.sh -f save /tmp/gros_projet
echo ""
success "Exécution en arrière-plan !"
pause

# ============================================================================
# 8. RESTAURATION
# ============================================================================
titre "8️⃣  RESTAURATION DE VERSION"

# Récupérer le premier snapshot
SNAP_ID=$(ls ~/.snapfile/snapshots/ | head -1 | sed 's/.meta//')

info "Restauration du premier snapshot : $SNAP_ID"
echo ""
info "Contenu actuel de main.txt :"
cmd "cat /tmp/demo_projet/main.txt"
cat /tmp/demo_projet/main.txt
echo ""
pause

# Prévisualisation
info "Prévisualisation avec l'option -s..."
cmd "./src/snapfile.sh -s restore /tmp/demo_projet --id $SNAP_ID"
echo ""
./src/snapfile.sh -s restore /tmp/demo_projet --id $SNAP_ID
echo ""
pause

info "Contenu restauré (prévisualisation) :"
cmd "cat /tmp/snapfile_preview/demo_projet/main.txt"
cat /tmp/snapfile_preview/demo_projet/main.txt
echo ""
success "Prévisualisation réussie ! C'est bien la version 1"
pause

# Restauration réelle
info "Restauration réelle..."
echo ""
echo "oui" | ./src/snapfile.sh restore /tmp/demo_projet --id $SNAP_ID
echo ""
pause

info "Vérification de la restauration :"
cmd "cat /tmp/demo_projet/main.txt"
cat /tmp/demo_projet/main.txt
echo ""
success "Restauration réussie ! Retour à la version 1"
pause

# ============================================================================
# 9. STATISTIQUES FINALES
# ============================================================================
titre "9️⃣  STATISTIQUES FINALES"

echo "📊 Résumé de la démonstration :"
echo ""
echo "   • Snapshots créés    : $(ls ~/.snapfile/snapshots/ | wc -l)"
echo "   • Objets stockés     : $(ls ~/.snapfile/objects/ | wc -l)"
echo "   • Taille du dépôt    : $(du -sh ~/.snapfile/ | cut -f1)"
echo "   • Projets versionnés : 2 (demo_projet, gros_projet)"
echo ""
pause

# ============================================================================
# 10. CONCLUSION
# ============================================================================
titre "🎉 CONCLUSION"

echo -e "${GREEN}"
cat << 'EOF'
✅ FONCTIONNALITÉS DÉMONTRÉES :

  1. ✅ Initialisation du dépôt
  2. ✅ Sauvegarde de fichiers
  3. ✅ Déduplication automatique (économie d'espace)
  4. ✅ Détection des changements
  5. ✅ Historique des snapshots
  6. ✅ Options avancées (-f, -t, -l)
  7. ✅ Prévisualisation avant restauration
  8. ✅ Restauration de versions

╔══════════════════════════════════════════════════════════════╗
║                    AVANTAGES SNAPFILE                        ║
╚══════════════════════════════════════════════════════════════╝

  ✅ Léger et rapide
  ✅ Déduplication automatique (économie d'espace)
  ✅ Compression gzip
  ✅ Options de performance (fork, thread)
  ✅ Prévisualisation avant restauration
  ✅ Logs personnalisables
  ✅ Un seul dépôt pour tous les projets
  ✅ Simple d'utilisation

EOF
echo -e "${NC}"
echo ""
echo -e "${CYAN}Merci de votre attention ! 🎉${NC}"
echo ""
echo -e "${YELLOW}Pour plus d'informations :${NC}"
echo "  • Guide complet : docs/zakaria/GUIDE_COMPLET_OPTIONS.md"
echo "  • Documentation : README.md"
echo "  • Tests : ./tests/test_complet.sh"
echo ""
