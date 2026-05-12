# 🎤 Guide de Présentation SnapFile

## 📋 Vue d'Ensemble

Ce dossier contient tout ce dont vous avez besoin pour présenter le projet SnapFile devant un jury ou une audience.

---

## 📁 Fichiers Disponibles

| Fichier | Description | Utilisation |
|---------|-------------|-------------|
| **`GUIDE_DEMONSTRATION_PRESENTATION.md`** | Guide complet avec explications | 📖 À lire avant la présentation |
| **`demo_presentation.sh`** | Script automatique de démonstration | 🚀 À exécuter pendant la présentation |

---

## 🚀 Démarrage Rapide

### **Option 1 : Script Automatique (Recommandé)**

```bash
# Depuis WSL
dos2unix demo_presentation.sh
chmod +x demo_presentation.sh
./demo_presentation.sh
```

**Avantages :**
- ✅ Démonstration fluide et professionnelle
- ✅ Couleurs et formatage
- ✅ Pauses automatiques
- ✅ Statistiques en temps réel
- ✅ Durée : 10-15 minutes

---

### **Option 2 : Commandes Manuelles**

Suivez le guide `GUIDE_DEMONSTRATION_PRESENTATION.md` et exécutez les commandes une par une.

**Avantages :**
- ✅ Plus de contrôle
- ✅ Possibilité d'adapter
- ✅ Réponses aux questions en direct

---

## 📝 Plan de la Démonstration

### **1. Introduction (1 min)**
- Présentation du projet
- Objectifs
- Fonctionnalités principales

### **2. Initialisation (1 min)**
- Commande `init`
- Structure du dépôt

### **3. Sauvegarde (2 min)**
- Création d'un projet de test
- Première sauvegarde
- Explication du processus

### **4. Déduplication (3 min)**
- Modification d'un fichier
- Deuxième sauvegarde
- Démonstration de l'économie d'espace
- Test sans changement

### **5. Historique (1 min)**
- Commande `log`
- Affichage des snapshots

### **6. Options Avancées (3 min)**
- Option `-t` (thread)
- Option `-l` (logs)
- Option `-f` (fork)
- Combinaisons

### **7. Restauration (3 min)**
- Prévisualisation avec `-s`
- Restauration réelle
- Vérification

### **8. Conclusion (1 min)**
- Récapitulatif
- Statistiques
- Avantages

**Durée totale : 15 minutes**

---

## 🎯 Fonctionnalités à Démontrer

### **Fonctionnalités Principales**
- ✅ Initialisation du dépôt
- ✅ Sauvegarde de fichiers
- ✅ Déduplication automatique
- ✅ Historique des snapshots
- ✅ Restauration de versions

### **Fonctionnalités Avancées**
- ✅ Option `-f` (fork - arrière-plan)
- ✅ Option `-t` (thread - parallèle)
- ✅ Option `-l` (logs personnalisés)
- ✅ Option `-s` (prévisualisation)

### **Points Forts à Souligner**
- ✅ Déduplication automatique (économie d'espace)
- ✅ Performance (fork, thread)
- ✅ Sécurité (prévisualisation)
- ✅ Simplicité d'utilisation
- ✅ Logs personnalisables

---

## 💡 Conseils pour la Présentation

### **Avant la Présentation**

1. **Tester le script complet**
   ```bash
   ./demo_presentation.sh
   ```

2. **Préparer le terminal**
   - Police lisible (Consolas, Monaco, etc.)
   - Taille de police : 14-16pt
   - Couleurs activées
   - Plein écran

3. **Nettoyer l'environnement**
   ```bash
   rm -rf ~/.snapfile /tmp/demo_projet /tmp/gros_projet
   ```

4. **Vérifier les fins de ligne**
   ```bash
   dos2unix src/snapfile.sh src/lib/*.sh demo_presentation.sh
   ```

---

### **Pendant la Présentation**

1. **Expliquer avant d'exécuter**
   - Dire ce que vous allez faire
   - Expliquer pourquoi
   - Montrer le résultat attendu

2. **Commenter les résultats**
   - Souligner les points importants
   - Mentionner les statistiques
   - Faire le lien avec la théorie

3. **Gérer le temps**
   - Respecter les 15 minutes
   - Faire des pauses pour les questions
   - Ne pas s'attarder sur les détails

4. **Rester calme**
   - Si une erreur survient, expliquer
   - Avoir un plan B (captures d'écran)
   - Continuer avec confiance

---

### **Après la Présentation**

1. **Répondre aux questions**
   - Écouter attentivement
   - Répondre clairement
   - Montrer des exemples si nécessaire

2. **Montrer la documentation**
   - Guide complet des options
   - Tests automatiques
   - Code source

---

## 🎬 Scénario de Démonstration

### **Script Complet**

```bash
# 1. Nettoyage
rm -rf ~/.snapfile /tmp/demo_projet /tmp/gros_projet

# 2. Initialisation
./src/snapfile.sh init

# 3. Création du projet
mkdir -p /tmp/demo_projet/src
echo "Version 1" > /tmp/demo_projet/main.txt
echo "Config" > /tmp/demo_projet/config.txt
echo "README" > /tmp/demo_projet/README.md
echo "print('Hello')" > /tmp/demo_projet/src/app.py

# 4. Première sauvegarde
./src/snapfile.sh save /tmp/demo_projet

# 5. Modification
echo "Version 2 - MODIFIÉ" > /tmp/demo_projet/main.txt

# 6. Deuxième sauvegarde
./src/snapfile.sh save /tmp/demo_projet

# 7. Vérification déduplication
ls ~/.snapfile/objects/ | wc -l

# 8. Test aucun changement
./src/snapfile.sh save /tmp/demo_projet

# 9. Historique
./src/snapfile.sh log /tmp/demo_projet

# 10. Options avancées
mkdir -p /tmp/gros_projet
for i in {1..20}; do echo "File $i" > /tmp/gros_projet/file$i.txt; done
./src/snapfile.sh -t save /tmp/gros_projet
./src/snapfile.sh -l /tmp/logs save /tmp/demo_projet

# 11. Restauration
SNAP_ID=$(ls ~/.snapfile/snapshots/ | head -1 | sed 's/.meta//')
./src/snapfile.sh -s restore /tmp/demo_projet --id $SNAP_ID
cat /tmp/snapfile_preview/demo_projet/main.txt

# 12. Statistiques
echo "Snapshots : $(ls ~/.snapfile/snapshots/ | wc -l)"
echo "Objets : $(ls ~/.snapfile/objects/ | wc -l)"
echo "Taille : $(du -sh ~/.snapfile/ | cut -f1)"
```

---

## 📊 Statistiques à Mentionner

### **Pendant la Démonstration**

```bash
# Nombre de snapshots
ls ~/.snapfile/snapshots/ | wc -l

# Nombre d'objets (déduplication)
ls ~/.snapfile/objects/ | wc -l

# Taille du dépôt
du -sh ~/.snapfile/

# Taux de déduplication
# Exemple : 2 snapshots × 4 fichiers = 8 fichiers
#           Mais seulement 4 objets stockés
#           → 50% d'économie d'espace
```

---

## ❓ Questions Fréquentes

### **Q1 : Quelle est la différence avec Git ?**
**R :** SnapFile est plus simple et léger. Pas de commits, pas de branches. Juste des snapshots horodatés. Idéal pour versionner des fichiers de configuration ou des documents.

### **Q2 : Comment fonctionne la déduplication ?**
**R :** Chaque fichier est hashé avec SHA-256. Si le hash existe déjà, le fichier n'est pas stocké à nouveau. Seules les métadonnées sont mises à jour.

### **Q3 : Quelle est la performance ?**
**R :** Avec l'option `-t` (thread), la compression est 3-5× plus rapide. Avec `-f` (fork), l'exécution est en arrière-plan.

### **Q4 : Peut-on restaurer partiellement ?**
**R :** Actuellement, la restauration est complète. Une restauration partielle pourrait être ajoutée dans une version future.

### **Q5 : Quelle est la taille maximale supportée ?**
**R :** Pas de limite théorique. Testé avec succès sur des projets de plusieurs Go.

### **Q6 : Les fichiers sont-ils chiffrés ?**
**R :** Non, actuellement les fichiers sont compressés mais pas chiffrés. Le chiffrement pourrait être ajouté dans une version future.

---

## 🐛 Dépannage

### **Problème : "required file not found"**
```bash
# Solution : Corriger les fins de ligne depuis WSL
dos2unix src/snapfile.sh src/lib/*.sh demo_presentation.sh
```

### **Problème : "Permission denied"**
```bash
# Solution : Rendre exécutable
chmod +x src/snapfile.sh demo_presentation.sh
```

### **Problème : Erreur pendant la démo**
- Rester calme
- Expliquer le problème
- Continuer avec le reste de la démo
- Avoir des captures d'écran en backup

---

## ✅ Checklist Finale

### **Avant la Présentation**
- [ ] Tester le script complet
- [ ] Vérifier les fins de ligne (dos2unix)
- [ ] Augmenter la taille de la police
- [ ] Nettoyer l'environnement
- [ ] Préparer les réponses aux questions
- [ ] Avoir un plan B (captures d'écran)

### **Pendant la Présentation**
- [ ] Expliquer avant d'exécuter
- [ ] Montrer les résultats
- [ ] Mentionner les statistiques
- [ ] Faire des pauses
- [ ] Répondre aux questions
- [ ] Rester dans le temps (15 min)

### **Après la Présentation**
- [ ] Répondre aux questions
- [ ] Montrer la documentation
- [ ] Partager le code source

---

## 🎉 Bonne Présentation !

Avec ce guide et le script automatique, vous êtes prêt pour une démonstration professionnelle et convaincante de SnapFile.

**Durée :** 10-15 minutes  
**Niveau :** Facile  
**Impact :** Maximum 🚀

---

## 📚 Ressources Supplémentaires

- **Guide complet :** `docs/zakaria/GUIDE_COMPLET_OPTIONS.md`
- **Documentation technique :** `docs/zakaria/TEST_OPTION_L.md`
- **Tests automatiques :** `tests/test_complet.sh`
- **Code source :** `src/snapfile.sh`

---

*Dernière mise à jour : 11 mai 2026*
