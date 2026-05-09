# 📘 Documentation Sprint 1 - SnapFile

**Membre :** Membre 1  
**Date de livraison :** 30 avril 2026  
**Statut :** ✅ Complet et prêt pour le Sprint 2

---

## 🎯 Objectifs du Sprint 1

Créer la base solide du projet : structure de fichiers, gestion des options, validation des paramètres et système de log. Ce sprint définit le cadre dans lequel les trois autres membres vont travailler.

---

## ✅ Livrables Réalisés

### 1. Fichier Principal `snapfile.sh`

- ✅ Shebang `#!/bin/bash` configuré
- ✅ Permissions d'exécution (utiliser `chmod +x snapfile.sh`)
- ✅ Entête de documentation complète
- ✅ Structure modulaire avec fonctions clairement séparées

### 2. Fonction `usage()` — Option `-h`

**Emplacement :** Lignes 52-130

**Description :** Affiche un manuel complet et professionnel avec :
- Synopsis de la commande
- Description détaillée de chaque option
- Exemples d'utilisation concrets
- Liste complète des codes d'erreur (100-105)
- Format des logs
- Informations sur les fichiers système

**Test :**
```bash
./snapfile.sh -h
```

### 3. Parseur d'Options avec `getopts`

**Emplacement :** Lignes 264-295

**Options implémentées :**
| Option | Description | Implémentation |
|--------|-------------|----------------|
| `-h` | Affiche l'aide | ✅ Fonctionnel |
| `-f` | Fork (arrière-plan) | ✅ Flag activé |
| `-t` | Thread (parallélisme) | ✅ Flag activé |
| `-s` | Subshell (prévisualisation) | ✅ Flag activé |
| `-l <chemin>` | Log personnalisé | ✅ Chemin capturé |
| `-r` | Reset (sudo requis) | ✅ Fonctionnel |

**Gestion des erreurs :**
- ✅ Option inconnue → Erreur 100
- ✅ Argument manquant pour `-l` → Erreur 101

**Tests :**
```bash
# Test option inconnue
./snapfile.sh -z save test/
# Résultat attendu : Erreur 100 + affichage de l'aide

# Test option -l sans argument
./snapfile.sh -l
# Résultat attendu : Erreur 101
```

### 4. Validation du Paramètre Obligatoire

**Fonction :** `validate_target_dir()` (lignes 218-232)

**Validations effectuées :**
1. ✅ Vérification que le chemin est fourni
2. ✅ Vérification que le chemin existe sur le disque
3. ✅ Vérification que le chemin est bien un dossier (pas un fichier)

**Tests :**
```bash
# Test sans paramètre
./snapfile.sh save
# Résultat attendu : Erreur 101

# Test avec chemin inexistant
./snapfile.sh save /chemin/inexistant/
# Résultat attendu : Erreur 101

# Test avec un fichier au lieu d'un dossier
touch test.txt
./snapfile.sh save test.txt
# Résultat attendu : Erreur 101
```

### 5. Structure du Dépôt `~/.snapfile/`

**Fonction :** `init_repository()` (lignes 206-214)

**Arborescence créée :**
```
~/.snapfile/
├── objects/        # Fichiers dédupliqués (stockage par hash SHA-256)
├── snapshots/      # Métadonnées des snapshots (JSON/texte)
└── index/          # Mapping hash → chemin original
```

**Comportement :**
- Création automatique au premier lancement
- Vérification avant chaque opération
- Log de l'initialisation

**Test :**
```bash
# Supprimer le dépôt s'il existe
rm -rf ~/.snapfile

# Lancer le script
./snapfile.sh save test_folder/

# Vérifier la création
ls -la ~/.snapfile/
# Résultat attendu : objects/ snapshots/ index/
```

### 6. Système de Log — Option `-l`

**Fonction :** `log_event()` (lignes 134-162)

**Format du log :**
```
yyyy-mm-dd-hh-mm-ss: username: TYPE: message
```

**Exemple :**
```
2026-04-30-14-23-45: alice: INFOS: Repository initialized at /home/alice/.snapfile
2026-04-30-14-24-10: alice: INFOS: COMMAND: save mon_projet/ (fork=0, thread=0)
2026-04-30-14-25-33: bob: ERROR: ERROR_101: Paramètre manquant
```

**Fonctionnalités :**
- ✅ Horodatage automatique
- ✅ Capture du nom d'utilisateur
- ✅ Types de log : INFOS, ERROR, WARNING
- ✅ Affichage simultané terminal + fichier (via `tee`)
- ✅ Création automatique du répertoire de log
- ✅ Fallback vers `~/.snapfile/snapfile.log` si `/var/log/` inaccessible

**Emplacement par défaut :** `/var/log/snapfile/history.log`

**Test :**
```bash
# Log par défaut
./snapfile.sh save test_folder/
cat /var/log/snapfile/history.log

# Log personnalisé
./snapfile.sh -l ~/mes_logs save test_folder/
cat ~/mes_logs/snapfile.log
```

### 7. Gestion Unifiée des Erreurs

**Fonction :** `die()` (lignes 166-184)

**Comportement :**
1. ✅ Log automatique de l'erreur
2. ✅ Affichage formaté en rouge avec emoji ❌
3. ✅ Affichage automatique de l'aide (`usage()`)
4. ✅ Sortie avec le code d'erreur approprié

**Codes d'erreur implémentés :**
| Code | Signification | Déclencheur |
|------|---------------|-------------|
| 100 | Option non reconnue | Option invalide ou commande inconnue |
| 101 | Paramètre manquant | Chemin absent ou invalide |
| 102 | Dépôt non initialisé | *(Sprint 3)* |
| 103 | Version introuvable | *(Sprint 3)* |
| 104 | Espace disque plein | *(Sprint 2)* |
| 105 | Permission refusée | Option `-r` sans `sudo` |

**Test :**
```bash
# Test erreur 100
./snapfile.sh -x save test/

# Test erreur 101
./snapfile.sh save

# Test erreur 105
./snapfile.sh -r
# Puis avec sudo :
sudo ./snapfile.sh -r
```

### 8. Option `-r` (Reset) avec Protection `sudo`

**Fonctions :** `check_sudo()` (lignes 236-242) et `reset_snapfile()` (lignes 246-280)

**Comportement :**
1. ✅ Vérification que l'utilisateur est root (`$EUID`)
2. ✅ Erreur 105 si exécuté sans `sudo`
3. ✅ Demande de confirmation explicite (taper "OUI")
4. ✅ Purge complète de `~/.snapfile/`
5. ✅ Purge complète de `/var/log/snapfile/`
6. ✅ Log de l'opération

**Test :**
```bash
# Sans sudo (doit échouer)
./snapfile.sh -r

# Avec sudo
sudo ./snapfile.sh -r
# Taper "OUI" pour confirmer
```

---

## 🏗️ Architecture du Code

### Variables Globales (lignes 12-32)

```bash
VERSION="1.0.0"
SNAPFILE_DIR="$HOME/.snapfile"
OBJECTS_DIR="$SNAPFILE_DIR/objects"
SNAPSHOTS_DIR="$SNAPFILE_DIR/snapshots"
INDEX_DIR="$SNAPFILE_DIR/index"
DEFAULT_LOG_FILE="/var/log/snapfile/history.log"
LOG_FILE="$DEFAULT_LOG_FILE"
```

### Fonctions Utilitaires

| Fonction | Ligne | Rôle |
|----------|-------|------|
| `usage()` | 52 | Affiche le manuel complet |
| `log_event()` | 134 | Enregistre un événement dans le log |
| `die()` | 166 | Gestion unifiée des erreurs |
| `init_repository()` | 206 | Crée la structure `~/.snapfile/` |
| `validate_target_dir()` | 218 | Valide le chemin du dossier cible |
| `check_sudo()` | 236 | Vérifie les privilèges root |
| `reset_snapfile()` | 246 | Réinitialise complètement SnapFile |

### Flux d'Exécution

```
1. Parsing des options (getopts)
2. Traitement de l'option -r si présente
3. Validation du paramètre obligatoire
4. Initialisation du dépôt
5. Routage vers la commande (save/log/restore)
6. Log de fin d'exécution
```

---

## 🧪 Tests Manuels Effectués

### Test 1 : Affichage de l'aide
```bash
./snapfile.sh -h
# ✅ Manuel complet affiché
```

### Test 2 : Option inconnue
```bash
./snapfile.sh -z save test/
# ✅ Erreur 100 + aide affichée
```

### Test 3 : Paramètre manquant
```bash
./snapfile.sh save
# ✅ Erreur 101 + aide affichée
```

### Test 4 : Initialisation du dépôt
```bash
rm -rf ~/.snapfile
./snapfile.sh save test_folder/
ls -la ~/.snapfile/
# ✅ Dossiers objects/, snapshots/, index/ créés
```

### Test 5 : Système de log
```bash
./snapfile.sh save test_folder/
cat /var/log/snapfile/history.log
# ✅ Entrées de log au bon format
```

### Test 6 : Option -r sans sudo
```bash
./snapfile.sh -r
# ✅ Erreur 105 + aide affichée
```

### Test 7 : Option -r avec sudo
```bash
sudo ./snapfile.sh -r
# Taper "OUI"
# ✅ Dépôt et logs supprimés
```

### Test 8 : Log personnalisé
```bash
./snapfile.sh -l ~/mes_logs save test_folder/
cat ~/mes_logs/snapfile.log
# ✅ Log créé au bon endroit
```

---

## 📦 Conventions de Code

### Style de Nommage
- **Variables globales :** `MAJUSCULES_AVEC_UNDERSCORES`
- **Variables locales :** `minuscules_avec_underscores`
- **Fonctions :** `snake_case()` avec verbe d'action

### Commentaires
- Blocs de séparation avec `# ===...===`
- Documentation de fonction avec Description + Arguments
- Commentaires inline pour logique complexe

### Gestion des Erreurs
- Toujours utiliser `die()` pour les erreurs fatales
- Logger avant de quitter
- Codes d'erreur cohérents (100-105)

### Logs
- Format strict : `yyyy-mm-dd-hh-mm-ss: user: TYPE: message`
- Types : INFOS, ERROR, WARNING
- Toujours logger les opérations importantes

---

## 🔄 Interface pour le Sprint 2 (Membre 2)

### Fonctions Disponibles

Le Membre 2 peut utiliser directement :

```bash
# Logger un événement
log_event "INFOS" "SNAPSHOT_CREATED id=5 files=12 size=45M"

# Gérer une erreur
die 104 "Espace disque insuffisant"

# Accéder aux variables globales
echo $SNAPFILE_DIR        # ~/.snapfile
echo $OBJECTS_DIR         # ~/.snapfile/objects
echo $SNAPSHOTS_DIR       # ~/.snapfile/snapshots
echo $INDEX_DIR           # ~/.snapfile/index

# Vérifier les options activées
if [[ $OPT_FORK -eq 1 ]]; then
    # Lancer en arrière-plan
fi

if [[ $OPT_THREAD -eq 1 ]]; then
    # Compression parallèle
fi
```

### Point d'Entrée pour `save`

**Ligne 318 :** Remplacer le placeholder par l'implémentation réelle

```bash
case "$COMMAND" in
    save)
        log_event "INFOS" "COMMAND: save $TARGET_DIR (fork=$OPT_FORK, thread=$OPT_THREAD)"
        # TODO Sprint 2 : Implémenter la sauvegarde ici
        ;;
```

### Variables Utiles

- `$TARGET_DIR` : Chemin du dossier à sauvegarder (déjà validé)
- `$OPT_FORK` : 1 si `-f` activé, 0 sinon
- `$OPT_THREAD` : 1 si `-t` activé, 0 sinon

---

## 📋 Checklist de Livraison

- [x] `snapfile.sh` exécutable avec squelette fonctionnel
- [x] Option `-h` affichant un manuel complet
- [x] Parseur d'options opérationnel (erreurs 100 et 101 testées)
- [x] Dossier `~/.snapfile/` créé automatiquement au premier lancement
- [x] Fonction `log_event()` testée manuellement
- [x] Fichier `README_sprint1.md` documentant les fonctions créées
- [x] Tous les tests manuels passés avec succès

---

## 🚀 Prochaines Étapes (Sprint 2)

Le Membre 2 doit maintenant implémenter :

1. **Commande `save`** avec parcours récursif (`find`)
2. **Calcul SHA-256** de chaque fichier (`sha256sum`)
3. **Déduplication** par hash (liens symboliques)
4. **Compression** avec `tar` et `gzip`
5. **Métadonnées** des snapshots (JSON/texte)
6. **Option `-f`** : fork avec `&` et `disown`
7. **Option `-t`** : compression parallèle avec `wait`
8. **Vérification espace disque** avec `df` (erreur 104)

---

## 📞 Contact

Pour toute question sur le Sprint 1, contacter le Membre 1.

**Bon courage pour le Sprint 2 ! 🎯**
