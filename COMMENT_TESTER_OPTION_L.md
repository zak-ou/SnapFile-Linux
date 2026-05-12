# 🚀 Comment Tester l'Option -l

## ⚡ Test Ultra-Rapide (30 secondes)

### **Depuis WSL (Important !)**

```bash
# 1. Corriger les fins de ligne (OBLIGATOIRE sur Windows/WSL)
dos2unix src/snapfile.sh
dos2unix src/lib/options.sh
dos2unix src/lib/utils.sh

# 2. Rendre exécutable
chmod +x src/snapfile.sh

# 3. Initialiser
./src/snapfile.sh init

# 4. Créer un projet de test
mkdir -p /tmp/test_projet
echo "fichier1" > /tmp/test_projet/file1.txt

# 5. Tester l'option -l
./src/snapfile.sh -l /tmp/mes_logs save /tmp/test_projet

# 6. Vérifier le résultat
cat /tmp/mes_logs/snapfile.log
```

### **Résultat Attendu**

Vous devriez voir quelque chose comme :
```
2026-05-11-14-30-00: votre_user: INFOS: COMMAND: save /tmp/test_projet
2026-05-11-14-30-01: votre_user: INFOS: SNAPSHOT_CREATED id=20260511143000 files=1 size=0M
2026-05-11-14-30-01: votre_user: INFOS: Execution completed: save /tmp/test_projet
```

✅ **Si vous voyez ces lignes → L'option -l fonctionne parfaitement !**

---

## 🧪 Tests Automatiques

### **Test Complet (6 tests)**

```bash
# Corriger les fins de ligne
dos2unix tests/test_option_l.sh

# Rendre exécutable
chmod +x tests/test_option_l.sh

# Lancer les tests
./tests/test_option_l.sh
```

**Résultat attendu :**
```
==========================================
RÉSUMÉ DES TESTS
==========================================
✓ Tests réussis : 6
✗ Tests échoués  : 0

✓ Tous les tests sont passés !
```

---

## 🎬 Démonstration Interactive

```bash
# Corriger les fins de ligne
dos2unix demo_option_l.sh

# Rendre exécutable
chmod +x demo_option_l.sh

# Lancer la démo
./demo_option_l.sh
```

Cette démo montre :
- Logs par défaut vs logs personnalisés
- Création automatique des répertoires
- Contenu des fichiers de logs
- Exemples pratiques

---

## 📝 Exemples d'Utilisation

### **1. Logs Personnalisés**
```bash
./src/snapfile.sh -l /tmp/logs save /tmp/mon_projet
cat /tmp/logs/snapfile.log
```

### **2. Logs dans le Répertoire Courant**
```bash
./src/snapfile.sh -l . save /tmp/mon_projet
cat ./snapfile.log
```

### **3. Logs par Projet**
```bash
# Projet A
./src/snapfile.sh -l ~/projet_A/logs save /tmp/projet_A

# Projet B
./src/snapfile.sh -l ~/projet_B/logs save /tmp/projet_B

# Chaque projet a ses propres logs
cat ~/projet_A/logs/snapfile.log
cat ~/projet_B/logs/snapfile.log
```

### **4. Combiné avec -f (Fork)**
```bash
./src/snapfile.sh -f -l ~/logs save /tmp/mon_projet
# Arrière-plan + logs personnalisés
```

### **5. Combiné avec -t (Thread)**
```bash
./src/snapfile.sh -t -l ~/logs save /tmp/mon_projet
# Parallèle + logs personnalisés
```

### **6. Combiné avec -f et -t (OPTIMAL)**
```bash
./src/snapfile.sh -f -t -l ~/logs save /tmp/gros_projet
# Arrière-plan + Parallèle + logs personnalisés
```

---

## ⚠️ Important : WSL/Windows

### **Toujours depuis WSL, PAS PowerShell !**

```bash
# ❌ NE PAS FAIRE depuis PowerShell
# ✅ FAIRE depuis WSL

# Ouvrir WSL :
wsl

# Puis naviguer vers le projet :
cd /mnt/c/Users/HP/Documents/Projet_Enset/S2/SnapFile-linux

# Corriger les fins de ligne :
dos2unix src/snapfile.sh
dos2unix src/lib/options.sh
dos2unix src/lib/utils.sh
dos2unix tests/test_option_l.sh
dos2unix demo_option_l.sh

# Tester :
./src/snapfile.sh -l /tmp/logs save /tmp/test
```

---

## 🐛 Dépannage

### **Problème : "required file not found"**

**Solution :** Corriger les fins de ligne avec `dos2unix` depuis WSL

```bash
dos2unix src/snapfile.sh
dos2unix src/lib/*.sh
```

### **Problème : "Permission denied"**

**Solution :** Rendre les scripts exécutables

```bash
chmod +x src/snapfile.sh
chmod +x tests/test_option_l.sh
chmod +x demo_option_l.sh
```

### **Problème : Logs non créés**

**Vérifications :**

1. L'option `-l` est-elle AVANT la commande ?
   ```bash
   # ✅ Correct
   ./src/snapfile.sh -l /tmp/logs save /tmp/projet
   
   # ❌ Incorrect
   ./src/snapfile.sh save /tmp/projet -l /tmp/logs
   ```

2. Le répertoire parent existe-t-il ?
   ```bash
   mkdir -p /tmp/logs
   ./src/snapfile.sh -l /tmp/logs save /tmp/projet
   ```

3. Avez-vous les permissions d'écriture ?
   ```bash
   touch /tmp/logs/test.txt
   ```

---

## 📚 Documentation Complète

- **Guide Complet :** `docs/zakaria/GUIDE_COMPLET_OPTIONS.md`
- **Test Détaillé :** `docs/zakaria/TEST_OPTION_L.md`
- **Test Rapide :** `TEST_RAPIDE_OPTION_L.md`
- **Résumé :** `RESUME_IMPLEMENTATION_OPTION_L.txt`

---

## ✅ Checklist

- [ ] Ouvrir WSL (pas PowerShell)
- [ ] Naviguer vers le projet
- [ ] Corriger les fins de ligne avec `dos2unix`
- [ ] Rendre les scripts exécutables avec `chmod +x`
- [ ] Initialiser avec `./src/snapfile.sh init`
- [ ] Tester avec `./src/snapfile.sh -l /tmp/logs save /tmp/test`
- [ ] Vérifier avec `cat /tmp/logs/snapfile.log`
- [ ] Lancer les tests avec `./tests/test_option_l.sh`
- [ ] Lancer la démo avec `./demo_option_l.sh`

---

## 🎯 Résumé

L'option `-l` permet de spécifier un répertoire personnalisé pour les logs.

**Syntaxe :**
```bash
./src/snapfile.sh -l <chemin> <commande> <dossier>
```

**Exemple :**
```bash
./src/snapfile.sh -l /tmp/logs save /tmp/projet
```

**Résultat :**
- Logs dans `/tmp/logs/snapfile.log` au lieu de `~/.snapfile/history.log`

---

✨ **L'option -l est maintenant pleinement fonctionnelle !** ✨
