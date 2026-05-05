# 🎯 Différence entre OPTIONS et COMMANDES dans SnapFile

**Date :** 2 mai 2026  
**Version :** 1.0.0

---

## 📋 Table des Matières

- [Introduction](#-introduction)
- [Différence Fondamentale](#-différence-fondamentale)
- [Schéma Visuel](#-schéma-visuel)
- [Exemples Concrets](#-exemples-concrets)
- [Analogie Simple](#-analogie-simple)
- [Les 3 Commandes Disponibles](#-les-3-commandes-disponibles)
- [Les Options Modifient les Commandes](#-les-options-modifient-les-commandes)
- [Pourquoi Cette Structure ?](#-pourquoi-cette-structure-)
- [Résumé Final](#-résumé-final)

---

## 🎯 Introduction

Ce document explique pourquoi SnapFile utilise des **COMMANDES** (comme `save`) et des **OPTIONS** (comme `-f`, `-t`, `-s`), et quelle est la différence entre les deux.

---

## 🔑 Différence Fondamentale

### **COMMANDES** (save, log, restore)
Ce sont des **actions principales** que vous voulez effectuer. C'est **OBLIGATOIRE** !

### **OPTIONS** (-f, -t, -s, -l, -h, -r)
Ce sont des **modificateurs** qui changent **comment** la commande s'exécute. C'est **OPTIONNEL** !

---

## 📊 Schéma Visuel

```
./snapfile.sh  [OPTIONS]  <COMMANDE>  <DOSSIER>
              ↑           ↑            ↑
           Optionnel   OBLIGATOIRE  OBLIGATOIRE
           (comment)   (quoi faire) (sur quoi)
```

---

## 🔍 Exemples Concrets

### **1. Commande seule (minimum requis)**
```bash
./snapfile.sh save mon_projet/
              ↑    ↑
           COMMANDE DOSSIER
```
**Signification :** "Sauvegarde le dossier mon_projet/"

---

### **2. Option + Commande**
```bash
./snapfile.sh -f save mon_projet/
              ↑  ↑    ↑
           OPTION COMMANDE DOSSIER
```
**Signification :** "Sauvegarde le dossier mon_projet/ **en arrière-plan**"

L'option `-f` modifie **comment** la commande `save` s'exécute.

---

### **3. Plusieurs options + Commande**
```bash
./snapfile.sh -f -t -l ~/logs save mon_projet/
              ↑  ↑  ↑         ↑    ↑
           OPTIONS...      COMMANDE DOSSIER
```
**Signification :** 
- Sauvegarde le dossier mon_projet/
- **En arrière-plan** (-f)
- **Avec compression parallèle** (-t)
- **Logs dans ~/logs** (-l ~/logs)

---

## 🎭 Analogie Simple

Imaginez un restaurant :

| Élément | Dans SnapFile | Au Restaurant |
|---------|---------------|---------------|
| **COMMANDE** | `save` | "Je veux un burger" |
| **DOSSIER** | `mon_projet/` | "Burger au poulet" |
| **OPTIONS** | `-f -t -s` | "Sans oignons, bien cuit, à emporter" |

- La **commande** = ce que vous voulez faire (burger)
- Le **dossier** = sur quoi (poulet)
- Les **options** = comment vous le voulez (sans oignons, bien cuit...)

**Vous ne pouvez pas dire :**
- ❌ "Je veux sans oignons" (incomplet - sans oignons sur quoi ?)
- ✅ "Je veux un burger sans oignons" (complet)

**De même dans SnapFile :**
- ❌ `./snapfile.sh -f mon_projet/` (incomplet - faire quoi en arrière-plan ?)
- ✅ `./snapfile.sh -f save mon_projet/` (complet - sauvegarder en arrière-plan)

---

## 📋 Les 3 Commandes Disponibles

### **1. save** - Créer un snapshot
```bash
./snapfile.sh save mon_projet/
```
**Action :** Sauvegarde l'état actuel du dossier

**Exemples avec options :**
```bash
# Sauvegarde en arrière-plan
./snapfile.sh -f save mon_projet/

# Sauvegarde avec compression parallèle
./snapfile.sh -t save gros_projet/

# Sauvegarde avec logs personnalisés
./snapfile.sh -l ~/logs save mon_projet/

# Combinaison d'options
./snapfile.sh -f -t -l ~/logs save gros_projet/
```

---

### **2. log** - Consulter l'historique
```bash
./snapfile.sh log mon_projet/
```
**Action :** Affiche tous les snapshots créés pour ce dossier

**Exemples avec options :**
```bash
# Log avec fichier de log personnalisé
./snapfile.sh -l ~/logs log mon_projet/
```

---

### **3. restore** - Restaurer une version
```bash
./snapfile.sh restore mon_projet/ --id 3
```
**Action :** Restaure le snapshot numéro 3

**Exemples avec options :**
```bash
# Restauration en prévisualisation (sûr)
./snapfile.sh -s restore mon_projet/ --id 3

# Restauration avec logs personnalisés
./snapfile.sh -l ~/logs restore mon_projet/ --id 3

# Combinaison
./snapfile.sh -s -l ~/logs restore mon_projet/ --id 3
```

---

## 🔧 Les Options Modifient les Commandes

### **Option -h (Help)**
```bash
./snapfile.sh -h
```
**Effet :** Affiche le manuel d'aide complet

**Note :** C'est la seule option qui ne nécessite pas de commande.

---

### **Option -f (Fork)**
```bash
# Sans -f : bloque le terminal jusqu'à la fin
./snapfile.sh save gros_projet/
# ⏳ Vous attendez... (peut prendre plusieurs minutes)

# Avec -f : libère le terminal immédiatement
./snapfile.sh -f save gros_projet/
# ✅ Vous pouvez continuer à travailler pendant la sauvegarde
```

**Utilisation :** Pour les gros projets qui prennent du temps à sauvegarder.

---

### **Option -t (Thread)**
```bash
# Sans -t : compression séquentielle (lent)
./snapfile.sh save gros_projet/
# Fichier 1 → Fichier 2 → Fichier 3... (un par un)

# Avec -t : compression parallèle (rapide)
./snapfile.sh -t save gros_projet/
# Fichier 1, 2, 3... en même temps ! (utilise plusieurs CPU)
```

**Utilisation :** Pour accélérer la compression des gros projets.

**Combinaison recommandée :**
```bash
./snapfile.sh -f -t save gros_projet/
# Arrière-plan + Parallèle = Maximum de performance
```

---

### **Option -s (Subshell)**
```bash
# Sans -s : restaure directement (risqué)
./snapfile.sh restore mon_projet/ --id 3
# ⚠️ Écrase le dossier actuel immédiatement

# Avec -s : prévisualisation dans /tmp/ (sûr)
./snapfile.sh -s restore mon_projet/ --id 3
# ✅ Restaure dans /tmp/ pour vérifier d'abord
# Vous pouvez inspecter avant de décider
```

**Utilisation :** Pour vérifier le contenu d'un snapshot avant de restaurer.

**Workflow recommandé :**
```bash
# 1. Prévisualiser d'abord
./snapfile.sh -s restore mon_projet/ --id 3
# 2. Vérifier dans /tmp/mon_projet/
ls /tmp/mon_projet/
# 3. Si OK, restaurer pour de vrai
./snapfile.sh restore mon_projet/ --id 3
```

---

### **Option -l (Log personnalisé)**
```bash
# Sans -l : logs par défaut
./snapfile.sh save mon_projet/
# → /var/log/snapfile/history.log

# Avec -l : logs personnalisés
./snapfile.sh -l ~/mes_logs save mon_projet/
# → ~/mes_logs/snapfile.log
```

**Utilisation :** Pour organiser vos logs par projet ou par utilisateur.

**Exemples pratiques :**
```bash
# Logs par projet
./snapfile.sh -l ~/projet_A/logs save projet_A/
./snapfile.sh -l ~/projet_B/logs save projet_B/

# Logs dans le dossier courant
./snapfile.sh -l . save mon_projet/
# → ./snapfile.log
```

---

### **Option -r (Reset)**
```bash
sudo ./snapfile.sh -r
```
**Effet :** Réinitialise complètement SnapFile (supprime tout)

**⚠️ ATTENTION :** Nécessite `sudo` et supprime :
- Tous les snapshots
- Tous les fichiers dédupliqués
- Toutes les métadonnées
- Tous les logs

**Utilisation :** Uniquement pour repartir de zéro.

---

## ❓ Pourquoi Cette Structure ?

### **1. Flexibilité**
```bash
# Utilisation simple (débutant)
./snapfile.sh save mon_projet/

# Utilisation avancée (expert)
./snapfile.sh -f -t -l ~/logs save mon_projet/
```

Vous pouvez commencer simple et ajouter des options au fur et à mesure.

---

### **2. Standard Unix**
C'est la convention standard des outils Unix/Linux :

```bash
# Commande ls
ls -la /home/
# ls = commande, -la = options, /home/ = argument

# Commande cp
cp -r src/ dest/
# cp = commande, -r = option, src/ dest/ = arguments

# Commande tar
tar -xzvf file.tar.gz
# tar = commande, -xzvf = options, file = argument

# Commande grep
grep -r "pattern" /path/
# grep = commande, -r = option, "pattern" /path/ = arguments
```

**SnapFile suit le même modèle :**
```bash
./snapfile.sh -f save mon_projet/
# snapfile.sh = commande, -f = option, save = sous-commande, mon_projet/ = argument
```

---

### **3. Clarté**
```bash
./snapfile.sh save mon_projet/
              ↑
         "Je veux SAUVEGARDER"
         (action claire et explicite)
```

En lisant la commande, on comprend immédiatement :
- **Quoi** : sauvegarder
- **Où** : mon_projet/
- **Comment** : (par défaut, ou avec options)

---

### **4. Extensibilité**
Facile d'ajouter de nouvelles options sans casser l'existant :

```bash
# Aujourd'hui
./snapfile.sh -f save mon_projet/

# Demain (nouvelle option -c pour compression)
./snapfile.sh -f -c gzip save mon_projet/

# Après-demain (nouvelle option -e pour encryption)
./snapfile.sh -f -c gzip -e aes256 save mon_projet/
```

---

## 🎯 Résumé Final

```
┌─────────────────────────────────────────────────────────┐
│  STRUCTURE COMPLÈTE                                     │
├─────────────────────────────────────────────────────────┤
│  ./snapfile.sh [OPTIONS] <COMMANDE> <DOSSIER>          │
│                ↑         ↑          ↑                   │
│             Optionnel  OBLIGATOIRE OBLIGATOIRE          │
│             (comment)  (quoi)      (où)                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  COMMANDES (Actions principales)                        │
├─────────────────────────────────────────────────────────┤
│  save      → Créer un snapshot                          │
│  log       → Voir l'historique                          │
│  restore   → Restaurer une version                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  OPTIONS (Modificateurs)                                │
├─────────────────────────────────────────────────────────┤
│  -h  → Aide                                             │
│  -f  → En arrière-plan (fork)                           │
│  -t  → Compression parallèle (thread)                   │
│  -s  → Prévisualisation (subshell)                      │
│  -l  → Logs personnalisés                               │
│  -r  → Reset complet (nécessite sudo)                   │
└─────────────────────────────────────────────────────────┘
```

---

## 💡 Réponse Directe

**Pourquoi `save` n'est pas une option ?**

Parce que `save` est **l'action principale** que vous voulez faire, pas une **modification** de comment le faire.

| Type | Question | Réponse |
|------|----------|---------|
| **Commande** | "Qu'est-ce que je veux faire ?" | `save` (sauvegarder) |
| **Option** | "Comment je veux le faire ?" | `-f` (en arrière-plan) |
| **Dossier** | "Sur quoi ?" | `mon_projet/` |

C'est comme dire :
- ❌ "Je veux **rapidement**" (incomplet - rapidement quoi ?)
- ✅ "Je veux **manger** rapidement" (complet - action + modificateur)

De même :
- ❌ `./snapfile.sh -f mon_projet/` (incomplet - faire quoi en arrière-plan ?)
- ✅ `./snapfile.sh -f save mon_projet/` (complet - sauvegarder en arrière-plan)

---

## 📚 Exemples Complets

### **Scénario 1 : Petit projet**
```bash
# Simple et direct
./snapfile.sh save mon_petit_projet/
```

---

### **Scénario 2 : Gros projet**
```bash
# Arrière-plan + Parallèle + Logs personnalisés
./snapfile.sh -f -t -l ~/logs save gros_projet/
```

---

### **Scénario 3 : Restauration prudente**
```bash
# 1. Voir l'historique
./snapfile.sh log mon_projet/

# 2. Prévisualiser le snapshot 3
./snapfile.sh -s restore mon_projet/ --id 3

# 3. Vérifier dans /tmp/
ls -la /tmp/mon_projet/

# 4. Si OK, restaurer pour de vrai
./snapfile.sh restore mon_projet/ --id 3
```

---

### **Scénario 4 : Réinitialisation complète**
```bash
# Supprimer tout et repartir de zéro
sudo ./snapfile.sh -r
```

---

## 📞 Support

Pour plus d'informations :
- **Manuel complet :** `./snapfile.sh -h`
- **Guide de démarrage :** `docs/GUIDE_DEMARRAGE.md`
- **Documentation technique :** `docs/README_sprint1.md`

---

*Dernière mise à jour : 2 mai 2026*
