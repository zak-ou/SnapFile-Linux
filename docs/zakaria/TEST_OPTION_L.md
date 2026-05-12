# 🧪 Test de l'Option -l (Logs Personnalisés)

**Date :** 11 mai 2026  
**Version :** 1.1.0  
**Statut :** ✅ Implémenté et Testé

---

## 📋 Résumé

L'option `-l <chemin>` permet de spécifier un répertoire personnalisé pour les fichiers de logs au lieu d'utiliser le répertoire par défaut (`~/.snapfile/history.log`).

---

## 🔧 Implémentation

### **Fichiers Modifiés**

1. **`src/snapfile.sh`**
   - Suppression du `readonly` sur `LOG_FILE`
   - Permet la modification par l'option `-l`

2. **`src/lib/options.sh`**
   - Parse l'option `-l <chemin>`
   - Définit `LOG_FILE="${OPTARG}/snapfile.log"`
   - Exporte `LOG_FILE` pour les sous-modules

3. **`src/lib/utils.sh`**
   - Fonction `log_event()` améliorée
   - Crée automatiquement le répertoire de logs
   - Gestion d'erreurs robuste

---

## 🚀 Utilisation

### **Syntaxe**
```bash
./src/snapfile.sh -l <chemin> <commande> <dossier>
```

### **Exemples**

#### 1. Logs par défaut (sans -l)
```bash
./src/snapfile.sh save /tmp/mon_projet
# → Logs dans : ~/.snapfile/history.log
```

#### 2. Logs personnalisés
```bash
./src/snapfile.sh -l /tmp/logs save /tmp/mon_projet
# → Logs dans : /tmp/logs/snapfile.log
```

#### 3. Logs dans le répertoire courant
```bash
./src/snapfile.sh -l . save /tmp/mon_projet
# → Logs dans : ./snapfile.log
```

#### 4. Logs par projet
```bash
./src/snapfile.sh -l ~/projet_A/logs save /tmp/projet_A
# → Logs dans : ~/projet_A/logs/snapfile.log

./src/snapfile.sh -l ~/projet_B/logs save /tmp/projet_B
# → Logs dans : ~/projet_B/logs/snapfile.log
```

---

## 🧪 Tests

### **Test Automatique**

Un script de test complet est disponible :

```bash
./tests/test_option_l.sh
```

**Tests effectués :**
1. ✅ Init avec logs par défaut
2. ✅ Save avec `-l /tmp/test_logs`
3. ✅ Log avec `-l /tmp/test_logs`
4. ✅ Save avec `-l .` (répertoire courant)
5. ✅ Save avec `-l ~/mes_logs/projet_A`
6. ✅ Save sans `-l` (logs par défaut)

### **Démonstration Interactive**

Un script de démonstration est disponible :

```bash
./demo_option_l.sh
```

Ce script montre :
- Logs par défaut vs logs personnalisés
- Création automatique des répertoires
- Contenu des fichiers de logs
- Exemples pratiques

---

## 📝 Format des Logs

Les logs suivent le format :

```
yyyy-mm-dd-hh-mm-ss: username: TYPE: message
```

**Exemple :**
```
2026-05-11-14-23-45: zakaria: INFOS: COMMAND: save /tmp/mon_projet
2026-05-11-14-23-46: zakaria: INFOS: SNAPSHOT_CREATED id=20260511142345 files=10 size=2M
2026-05-11-14-23-50: zakaria: INFOS: Execution completed: save /tmp/mon_projet
```

---

## 🔍 Vérification Manuelle

### **Étape 1 : Initialisation**
```bash
./src/snapfile.sh init
```

### **Étape 2 : Créer un projet de test**
```bash
mkdir -p /tmp/test_projet
echo "contenu1" > /tmp/test_projet/file1.txt
echo "contenu2" > /tmp/test_projet/file2.txt
```

### **Étape 3 : Save avec logs personnalisés**
```bash
./src/snapfile.sh -l /tmp/mes_logs save /tmp/test_projet
```

### **Étape 4 : Vérifier le fichier de log**
```bash
cat /tmp/mes_logs/snapfile.log
```

**Sortie attendue :**
```
2026-05-11-14-30-00: zakaria: INFOS: COMMAND: save /tmp/test_projet
2026-05-11-14-30-01: zakaria: INFOS: SNAPSHOT_CREATED id=20260511143000 files=2 size=0M
2026-05-11-14-30-01: zakaria: INFOS: Execution completed: save /tmp/test_projet
```

### **Étape 5 : Log avec logs personnalisés**
```bash
./src/snapfile.sh -l /tmp/mes_logs log /tmp/test_projet
```

### **Étape 6 : Vérifier les nouvelles entrées**
```bash
tail -5 /tmp/mes_logs/snapfile.log
```

---

## ⚠️ Notes Importantes

### **Permissions**
- Le répertoire de logs doit être accessible en écriture
- Si le répertoire n'existe pas, il sera créé automatiquement
- Si la création échoue, une erreur sera affichée

### **Compatibilité**
L'option `-l` est compatible avec :
- ✅ `init`
- ✅ `save`
- ✅ `log`
- ✅ `restore`
- ✅ Toutes les autres options (`-f`, `-t`, `-s`)

### **Combinaisons**
```bash
# Avec -f (fork)
./src/snapfile.sh -f -l ~/logs save /tmp/projet

# Avec -t (thread)
./src/snapfile.sh -t -l ~/logs save /tmp/projet

# Avec -f et -t
./src/snapfile.sh -f -t -l ~/logs save /tmp/projet

# Avec -s (subshell)
./src/snapfile.sh -s -l ~/logs restore /tmp/projet --id 20260511143000
```

---

## 🐛 Dépannage

### **Problème : Fichier de log non créé**

**Vérifications :**
1. Le répertoire parent existe-t-il ?
   ```bash
   ls -la /tmp/mes_logs/
   ```

2. Avez-vous les permissions d'écriture ?
   ```bash
   touch /tmp/mes_logs/test.txt
   ```

3. Le chemin est-il correct ?
   ```bash
   # Chemin absolu recommandé
   ./src/snapfile.sh -l /tmp/logs save /tmp/projet
   
   # Chemin relatif (depuis le répertoire courant)
   ./src/snapfile.sh -l ./logs save /tmp/projet
   ```

### **Problème : Logs dans le mauvais fichier**

Si les logs apparaissent dans `~/.snapfile/history.log` au lieu du chemin spécifié :
- Vérifiez que l'option `-l` est **avant** la commande
- ✅ Correct : `./src/snapfile.sh -l /tmp/logs save /tmp/projet`
- ❌ Incorrect : `./src/snapfile.sh save /tmp/projet -l /tmp/logs`

---

## 📊 Cas d'Usage

### **1. Organisation par Projet**
```bash
# Projet A
./src/snapfile.sh -l ~/projets/A/logs save /tmp/projet_A

# Projet B
./src/snapfile.sh -l ~/projets/B/logs save /tmp/projet_B

# Chaque projet a ses propres logs séparés
```

### **2. Logs Temporaires**
```bash
# Logs dans /tmp (nettoyés au redémarrage)
./src/snapfile.sh -l /tmp/snapfile_logs save /tmp/projet
```

### **3. Logs dans le Projet**
```bash
# Logs dans le dossier du projet
cd /tmp/mon_projet
../../src/snapfile.sh -l . save .
# → Logs dans /tmp/mon_projet/snapfile.log
```

### **4. Logs Centralisés**
```bash
# Tous les projets dans un seul répertoire de logs
./src/snapfile.sh -l ~/all_logs save /tmp/projet_A
./src/snapfile.sh -l ~/all_logs save /tmp/projet_B
./src/snapfile.sh -l ~/all_logs save /tmp/projet_C
```

---

## ✅ Checklist de Validation

- [x] Option `-l` parsée correctement
- [x] Variable `LOG_FILE` modifiable (non `readonly`)
- [x] Variable `LOG_FILE` exportée
- [x] Répertoire de logs créé automatiquement
- [x] Fichier de log créé avec le bon nom
- [x] Logs écrits dans le bon fichier
- [x] Compatible avec toutes les commandes
- [x] Compatible avec toutes les options
- [x] Gestion d'erreurs robuste
- [x] Tests automatiques créés
- [x] Démonstration interactive créée
- [x] Documentation complète

---

## 📚 Références

- **Guide complet :** `docs/zakaria/GUIDE_COMPLET_OPTIONS.md`
- **Compatibilité :** `docs/zakaria/COMPATIBILITE_OPTIONS_COMMANDES.md`
- **Tests :** `tests/test_option_l.sh`
- **Démo :** `demo_option_l.sh`

---

*Dernière mise à jour : 11 mai 2026*
