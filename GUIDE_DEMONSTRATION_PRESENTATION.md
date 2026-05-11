# 🎤 Guide de Démonstration - Présentation SnapFile

**Pour :** Présentation du Projet SnapFile  
**Audience :** Jury / Enseignants / Étudiants  
**Durée :** 10-15 minutes  
**Date :** 11 mai 2026

---

## 📋 Table des Matières

1. [Introduction](#1-introduction)
2. [Initialisation](#2-initialisation)
3. [Première Sauvegarde](#3-première-sauvegarde)
4. [Déduplication](#4-déduplication)
5. [Historique](#5-historique)
6. [Options Avancées](#6-options-avancées)
7. [Restauration](#7-restauration)
8. [Conclusion](#8-conclusion)

---

## 🎯 Objectif de la Démonstration

Montrer un **workflow complet** de versionnement avec SnapFile :
- ✅ Initialisation du dépôt
- ✅ Sauvegarde de fichiers
- ✅ Déduplication automatique
- ✅ Consultation de l'historique
- ✅ Options avancées (fork, thread, logs)
- ✅ Restauration de versions

---

## 🚀 Préparation (Avant la Présentation)

### **Sur WSL (Important !)**

```bash
# 1. Ouvrir WSL
wsl

# 2. Naviguer vers le projet
cd /mnt/c/Users/HP/Documents/Projet_Enset/S2/SnapFile-linux

# 3. Corriger les fins de ligne
dos2unix src/snapfile.sh
dos2unix src/lib/*.sh

# 4. Rendre exécutable
chmod +x src/snapfile.sh

# 5. Nettoyer l'environnement
rm -rf ~/.snapfile
rm -rf /tmp/demo_projet
```

---

## 📝 Script de Démonstration

---

## 1. Introduction

### **À dire :**
> "Bonjour, nous allons vous présenter **SnapFile**, un système de versionnement léger pour fichiers locaux. SnapFile permet de créer des snapshots horodatés de vos dossiers avec déduplication automatique pour économiser l'espace disque."

### **Montrer :**
```bash
# Afficher l'aide
./src/snapfile.sh -h
```

**Points clés à mentionner :**
- 4 commandes principales : `init`, `save`, `log`, `restore`
- 6 options : `-h`, `-f`, `-t`, `-s`, `-l`, `-r`
- Déduplication par hash SHA-256
- Compression gzip

---

## 2. Initialisation

### **À dire :**
> "La première étape est d'initialiser le dépôt SnapFile. Cette commande crée la structure de stockage dans `~/.snapfile/`."

### **Commande :**
```bash
./src/snapfile.sh init
```

**Sortie attendue :**
```
✅ Dépôt SnapFile initialisé avec succès !

📁 Structure créée :
   ~/.snapfile/
   ├── objects/     (stockage des fichiers compressés)
   ├── snapshots/   (métadonnées des sauvegardes)
   └── index/       (index par projet)

Vous pouvez maintenant utiliser : ./snapfile.sh save <dossier>
```

### **Vérifier la structure :**
```bash
ls -la ~/.snapfile/
```

**Points clés à mentionner :**
- Un seul dépôt partagé pour tous les projets
- Structure simple : objects, snapshots, index
- Initialisation obligatoire avant première utilisation

---

## 3. Première Sauvegarde

### **À dire :**
> "Créons maintenant un projet de test avec quelques fichiers, puis effectuons notre première sauvegarde."

### **Créer un projet de test :**
```bash
# Créer le dossier
mkdir -p /tmp/demo_projet

# Créer des fichiers
echo "Version 1 du fichier principal" > /tmp/demo_projet/main.txt
echo "Configuration initiale" > /tmp/demo_projet/config.txt
echo "Documentation du projet" > /tmp/demo_projet/README.md

# Créer un sous-dossier
mkdir -p /tmp/demo_projet/src
echo "def hello(): print('Hello')" > /tmp/demo_projet/src/app.py

# Afficher le contenu
tree /tmp/demo_projet/
# ou
find /tmp/demo_projet/ -type f
```

### **Première sauvegarde :**
```bash
./src/snapfile.sh save /tmp/demo_projet
```

**Sortie attendue :**
```
✅ Snapshot terminé ! ID: 20260511143000 (4 fichiers)
```

**Points clés à mentionner :**
- Snapshot horodaté (ID = timestamp)
- Tous les fichiers sont compressés et stockés
- Déduplication par hash SHA-256

---

## 4. Déduplication

### **À dire :**
> "Maintenant, modifions seulement UN fichier et créons un nouveau snapshot. SnapFile va détecter que les autres fichiers n'ont pas changé et ne les stockera pas à nouveau."

### **Modifier un fichier :**
```bash
# Modifier main.txt
echo "Version 2 du fichier principal - MODIFIÉ" > /tmp/demo_projet/main.txt

# Les autres fichiers restent identiques
```

### **Deuxième sauvegarde :**
```bash
./src/snapfile.sh save /tmp/demo_projet
```

**Sortie attendue :**
```
✅ Snapshot terminé ! ID: 20260511143100 (4 fichiers)
```

### **Démontrer la déduplication :**
```bash
# Compter les objets stockés
ls ~/.snapfile/objects/ | wc -l
```

**Résultat attendu :** 4 objets (pas 8 !)

**À dire :**
> "Nous avons créé 2 snapshots de 4 fichiers chacun, soit 8 fichiers au total. Mais grâce à la déduplication, seulement 4 objets sont stockés car 3 fichiers n'ont pas changé."

### **Test : Aucun changement :**
```bash
# Sauvegarder sans modification
./src/snapfile.sh save /tmp/demo_projet
```

**Sortie attendue :**
```
ℹ️ Aucun changement détecté depuis le dernier snapshot. Annulation.
```

**Points clés à mentionner :**
- Déduplication automatique par hash
- Économie d'espace disque
- Détection des fichiers identiques
- Pas de snapshot si aucun changement

---

## 5. Historique

### **À dire :**
> "Consultons maintenant l'historique de nos sauvegardes avec la commande `log`."

### **Commande :**
```bash
./src/snapfile.sh log /tmp/demo_projet
```

**Sortie attendue :**
```
📋 Historique des snapshots : /tmp/demo_projet

ID                   Date                 Fichiers   Taille
-------------------- -------------------- ---------- ------------
20260511143000       11/05/2026 14:30:00  4          2 Ko
20260511143100       11/05/2026 14:31:00  4          2 Ko

Total : 2 snapshot(s)
```

**Points clés à mentionner :**
- Historique complet des sauvegardes
- ID horodaté pour chaque snapshot
- Nombre de fichiers et taille
- Facile de retrouver une version

---

## 6. Options Avancées

### **À dire :**
> "SnapFile propose plusieurs options pour optimiser les performances selon la taille du projet."

### **6.1. Option -f (Fork - Arrière-plan)**

```bash
# Créer un gros projet
mkdir -p /tmp/gros_projet
for i in {1..20}; do
    echo "Fichier $i" > /tmp/gros_projet/file$i.txt
done

# Sauvegarder en arrière-plan
./src/snapfile.sh -f save /tmp/gros_projet
```

**Sortie attendue :**
```
🚀 Mode FORK (C-Worker par lots de 5)
[INFO] Exécution en arrière-plan lancée (PID: 12345)

✓ Exécution terminée avec succès
```

**À dire :**
> "Avec l'option `-f`, la sauvegarde s'exécute en arrière-plan. Le terminal est libéré immédiatement et vous pouvez continuer à travailler."

---

### **6.2. Option -t (Thread - Parallèle)**

```bash
# Sauvegarder avec compression parallèle
./src/snapfile.sh -t save /tmp/gros_projet
```

**Sortie attendue :**
```
🧵 Mode THREAD (C-Worker avec pthread)
✅ Snapshot terminé ! ID: 20260511143200 (20 fichiers)
```

**À dire :**
> "L'option `-t` active la compression parallèle avec plusieurs threads. C'est 3 à 5 fois plus rapide pour les gros projets."

---

### **6.3. Option -l (Logs personnalisés)**

```bash
# Sauvegarder avec logs personnalisés
./src/snapfile.sh -l /tmp/demo_logs save /tmp/demo_projet

# Voir les logs
cat /tmp/demo_logs/snapfile.log
```

**Sortie attendue :**
```
2026-05-11-14-32-00: zakaria: INFOS: COMMAND: save /tmp/demo_projet
2026-05-11-14-32-01: INFOS: SNAPSHOT_CREATED id=20260511143200 files=4
```

**À dire :**
> "L'option `-l` permet de spécifier un répertoire personnalisé pour les logs. Utile pour organiser les logs par projet."

---

### **6.4. Combinaison Optimale**

```bash
# Combinaison -f -t -l (OPTIMAL pour gros projets)
./src/snapfile.sh -f -t -l /tmp/logs save /tmp/gros_projet
```

**À dire :**
> "On peut combiner les options : `-f` pour l'arrière-plan, `-t` pour la parallélisation, et `-l` pour les logs personnalisés. C'est la configuration optimale pour les gros projets."

---

## 7. Restauration

### **À dire :**
> "Maintenant, restaurons une version précédente de notre projet."

### **7.1. Prévisualisation (Option -s)**

```bash
# Restaurer en prévisualisation
./src/snapfile.sh -s restore /tmp/demo_projet --id 20260511143000
```

**Sortie attendue :**
```
Mode prévisualisation : restauration dans /tmp/snapfile_preview/demo_projet
Restauration terminée : 4 fichier(s) restauré(s)
Destination : /tmp/snapfile_preview/demo_projet
```

### **Vérifier la prévisualisation :**
```bash
# Voir le contenu restauré
cat /tmp/snapfile_preview/demo_projet/main.txt
```

**Résultat :** "Version 1 du fichier principal" (version originale)

**À dire :**
> "L'option `-s` restaure dans `/tmp/` pour prévisualiser avant d'écraser les fichiers actuels. C'est une restauration prudente."

---

### **7.2. Restauration Réelle**

```bash
# Restaurer pour de vrai
./src/snapfile.sh restore /tmp/demo_projet --id 20260511143000
```

**Sortie attendue :**
```
Restauration dans : /tmp/demo_projet
Ceci va écraser les fichiers actuels. Continuer ? (oui/non) : oui
Restauration terminée : 4 fichier(s) restauré(s)
Destination : /tmp/demo_projet
```

### **Vérifier la restauration :**
```bash
cat /tmp/demo_projet/main.txt
```

**Résultat :** "Version 1 du fichier principal" (version restaurée)

**Points clés à mentionner :**
- Prévisualisation avec `-s` (recommandé)
- Confirmation obligatoire pour restauration réelle
- Restauration complète du snapshot

---

## 8. Conclusion

### **À dire :**
> "En résumé, SnapFile offre un système de versionnement complet avec :"

### **Récapitulatif des fonctionnalités :**

```bash
# Afficher le résumé
cat << 'EOF'

╔══════════════════════════════════════════════════════════════╗
║                    SNAPFILE - RÉSUMÉ                         ║
╚══════════════════════════════════════════════════════════════╝

✅ FONCTIONNALITÉS DÉMONTRÉES :

1. Initialisation du dépôt
   ./src/snapfile.sh init

2. Sauvegarde de fichiers
   ./src/snapfile.sh save <dossier>

3. Déduplication automatique
   • Par hash SHA-256
   • Économie d'espace disque
   • Détection des fichiers identiques

4. Historique des snapshots
   ./src/snapfile.sh log <dossier>

5. Options avancées
   -f : Arrière-plan (fork)
   -t : Parallèle (thread)
   -l : Logs personnalisés
   -s : Prévisualisation

6. Restauration de versions
   ./src/snapfile.sh restore <dossier> --id <ID>

╔══════════════════════════════════════════════════════════════╗
║                    AVANTAGES                                 ║
╚══════════════════════════════════════════════════════════════╝

✅ Léger et rapide
✅ Déduplication automatique
✅ Compression gzip
✅ Options de performance (fork, thread)
✅ Prévisualisation avant restauration
✅ Logs personnalisables
✅ Un seul dépôt pour tous les projets

EOF
```

---

## 📊 Statistiques à Mentionner

### **Pendant la démonstration :**

```bash
# Nombre de snapshots
ls ~/.snapfile/snapshots/ | wc -l

# Nombre d'objets (fichiers uniques)
ls ~/.snapfile/objects/ | wc -l

# Taille du dépôt
du -sh ~/.snapfile/

# Taux de déduplication
echo "Snapshots créés : X"
echo "Fichiers totaux : Y"
echo "Objets stockés : Z"
echo "Taux de déduplication : $((100 - (Z * 100 / Y)))%"
```

---

## 🎬 Scénario Complet (Copier-Coller)

### **Pour une démonstration fluide, voici le script complet :**

```bash
#!/bin/bash
# Script de démonstration SnapFile

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           DÉMONSTRATION SNAPFILE                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Nettoyage
echo "🧹 Nettoyage de l'environnement..."
rm -rf ~/.snapfile /tmp/demo_projet /tmp/gros_projet /tmp/demo_logs
echo ""

# 1. INITIALISATION
echo "═══════════════════════════════════════════════════════════════"
echo "1. INITIALISATION"
echo "═══════════════════════════════════════════════════════════════"
./src/snapfile.sh init
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 2. CRÉATION DU PROJET
echo "═══════════════════════════════════════════════════════════════"
echo "2. CRÉATION D'UN PROJET DE TEST"
echo "═══════════════════════════════════════════════════════════════"
mkdir -p /tmp/demo_projet/src
echo "Version 1 du fichier principal" > /tmp/demo_projet/main.txt
echo "Configuration initiale" > /tmp/demo_projet/config.txt
echo "Documentation du projet" > /tmp/demo_projet/README.md
echo "def hello(): print('Hello')" > /tmp/demo_projet/src/app.py
echo "✅ Projet créé avec 4 fichiers"
find /tmp/demo_projet/ -type f
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 3. PREMIÈRE SAUVEGARDE
echo "═══════════════════════════════════════════════════════════════"
echo "3. PREMIÈRE SAUVEGARDE"
echo "═══════════════════════════════════════════════════════════════"
./src/snapfile.sh save /tmp/demo_projet
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 4. MODIFICATION ET DEUXIÈME SAUVEGARDE
echo "═══════════════════════════════════════════════════════════════"
echo "4. MODIFICATION ET DÉDUPLICATION"
echo "═══════════════════════════════════════════════════════════════"
echo "Version 2 du fichier principal - MODIFIÉ" > /tmp/demo_projet/main.txt
echo "✅ Fichier main.txt modifié"
./src/snapfile.sh save /tmp/demo_projet
echo ""
echo "📊 Objets stockés (déduplication) :"
ls ~/.snapfile/objects/ | wc -l
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 5. TEST AUCUN CHANGEMENT
echo "═══════════════════════════════════════════════════════════════"
echo "5. TEST : AUCUN CHANGEMENT"
echo "═══════════════════════════════════════════════════════════════"
./src/snapfile.sh save /tmp/demo_projet
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 6. HISTORIQUE
echo "═══════════════════════════════════════════════════════════════"
echo "6. HISTORIQUE DES SNAPSHOTS"
echo "═══════════════════════════════════════════════════════════════"
./src/snapfile.sh log /tmp/demo_projet
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 7. OPTIONS AVANCÉES
echo "═══════════════════════════════════════════════════════════════"
echo "7. OPTIONS AVANCÉES"
echo "═══════════════════════════════════════════════════════════════"
mkdir -p /tmp/gros_projet
for i in {1..20}; do
    echo "Fichier $i" > /tmp/gros_projet/file$i.txt
done
echo "✅ Gros projet créé (20 fichiers)"
echo ""
echo "Test option -t (thread) :"
./src/snapfile.sh -t save /tmp/gros_projet
echo ""
echo "Test option -l (logs personnalisés) :"
./src/snapfile.sh -l /tmp/demo_logs save /tmp/demo_projet
cat /tmp/demo_logs/snapfile.log | tail -3
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 8. RESTAURATION
echo "═══════════════════════════════════════════════════════════════"
echo "8. RESTAURATION"
echo "═══════════════════════════════════════════════════════════════"
SNAP_ID=$(ls ~/.snapfile/snapshots/ | head -1 | sed 's/.meta//')
echo "Restauration du snapshot : $SNAP_ID"
echo ""
echo "Prévisualisation (-s) :"
./src/snapfile.sh -s restore /tmp/demo_projet --id $SNAP_ID
echo ""
echo "Contenu restauré (prévisualisation) :"
cat /tmp/snapfile_preview/demo_projet/main.txt
echo ""
read -p "Appuyez sur Entrée pour continuer..."
echo ""

# 9. CONCLUSION
echo "═══════════════════════════════════════════════════════════════"
echo "9. CONCLUSION"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✅ Démonstration terminée !"
echo ""
echo "Statistiques :"
echo "  • Snapshots créés : $(ls ~/.snapfile/snapshots/ | wc -l)"
echo "  • Objets stockés  : $(ls ~/.snapfile/objects/ | wc -l)"
echo "  • Taille du dépôt : $(du -sh ~/.snapfile/ | cut -f1)"
echo ""
echo "Merci de votre attention ! 🎉"
```

---

## 💡 Conseils pour la Présentation

### **Avant de commencer :**
1. ✅ Tester le script complet une fois
2. ✅ Préparer un terminal avec une police lisible
3. ✅ Augmenter la taille de la police (Ctrl + +)
4. ✅ Nettoyer l'environnement

### **Pendant la présentation :**
1. 🗣️ Expliquer chaque commande AVANT de l'exécuter
2. 👀 Montrer les résultats et les commenter
3. 📊 Mentionner les statistiques (déduplication, taille)
4. ⏸️ Faire des pauses pour les questions
5. 🎯 Rester focus sur les fonctionnalités clés

### **Points à souligner :**
- ✅ Déduplication automatique (économie d'espace)
- ✅ Performance (fork, thread)
- ✅ Sécurité (prévisualisation avant restauration)
- ✅ Simplicité d'utilisation
- ✅ Logs personnalisables

---

## 📝 Questions Fréquentes

### **Q1 : Quelle est la différence avec Git ?**
**R :** SnapFile est plus simple et léger. Pas de commits, pas de branches. Juste des snapshots horodatés. Idéal pour versionner des fichiers de configuration ou des documents.

### **Q2 : Comment fonctionne la déduplication ?**
**R :** Chaque fichier est hashé avec SHA-256. Si le hash existe déjà, le fichier n'est pas stocké à nouveau. Seules les métadonnées sont mises à jour.

### **Q3 : Quelle est la performance ?**
**R :** Avec l'option `-t` (thread), la compression est 3-5× plus rapide. Avec `-f` (fork), l'exécution est en arrière-plan.

### **Q4 : Peut-on restaurer partiellement ?**
**R :** Actuellement, la restauration est complète. Une restauration partielle pourrait être ajoutée dans une version future.

---

## ✅ Checklist Finale

Avant la présentation :
- [ ] Tester le script complet
- [ ] Vérifier que tous les fichiers sont en LF (dos2unix)
- [ ] Augmenter la taille de la police du terminal
- [ ] Nettoyer l'environnement
- [ ] Préparer les réponses aux questions

Pendant la présentation :
- [ ] Expliquer avant d'exécuter
- [ ] Montrer les résultats
- [ ] Mentionner les statistiques
- [ ] Faire des pauses
- [ ] Répondre aux questions

---

## 🎉 Bonne Présentation !

Ce guide vous permet de démontrer toutes les fonctionnalités de SnapFile de manière fluide et professionnelle.

**Durée estimée :** 10-15 minutes  
**Niveau de difficulté :** Facile  
**Impact :** Maximum 🚀

---

*Dernière mise à jour : 11 mai 2026*
