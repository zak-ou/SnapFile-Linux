# 🚀 Test Rapide de l'Option -l

## ⚡ Test en 2 Minutes

### **1. Initialiser**
```bash
./src/snapfile.sh init
```

### **2. Créer un projet de test**
```bash
mkdir -p /tmp/test_projet
echo "fichier1" > /tmp/test_projet/file1.txt
echo "fichier2" > /tmp/test_projet/file2.txt
```

### **3. Tester l'option -l**
```bash
# Save avec logs personnalisés
./src/snapfile.sh -l /tmp/mes_logs save /tmp/test_projet
```

### **4. Vérifier le résultat**
```bash
# Voir le fichier de log créé
cat /tmp/mes_logs/snapfile.log
```

**Résultat attendu :**
```
2026-05-11-XX-XX-XX: votre_user: INFOS: COMMAND: save /tmp/test_projet
2026-05-11-XX-XX-XX: votre_user: INFOS: SNAPSHOT_CREATED id=... files=2 size=0M
2026-05-11-XX-XX-XX: votre_user: INFOS: Execution completed: save /tmp/test_projet
```

---

## ✅ Si ça fonctionne

Vous devriez voir :
- ✅ Le fichier `/tmp/mes_logs/snapfile.log` existe
- ✅ Il contient les logs de la commande save
- ✅ Le format est correct (date: user: TYPE: message)

---

## 🧪 Tests Complets

### **Test Automatique**
```bash
./tests/test_option_l.sh
```

### **Démonstration Interactive**
```bash
./demo_option_l.sh
```

---

## 📚 Documentation Complète

Voir : `docs/zakaria/TEST_OPTION_L.md`

---

## 🐛 En cas de problème

### **Sur Windows/WSL : Erreur CRLF**
```bash
# Depuis WSL (pas PowerShell !)
dos2unix src/snapfile.sh
dos2unix src/lib/options.sh
dos2unix src/lib/utils.sh
dos2unix tests/test_option_l.sh
dos2unix demo_option_l.sh
```

### **Permissions**
```bash
chmod +x src/snapfile.sh
chmod +x tests/test_option_l.sh
chmod +x demo_option_l.sh
```

---

## 💡 Exemples Supplémentaires

```bash
# Logs dans le répertoire courant
./src/snapfile.sh -l . save /tmp/projet

# Logs par projet
./src/snapfile.sh -l ~/projet_A/logs save /tmp/projet_A
./src/snapfile.sh -l ~/projet_B/logs save /tmp/projet_B

# Combiné avec -f (fork)
./src/snapfile.sh -f -l ~/logs save /tmp/projet

# Combiné avec -t (thread)
./src/snapfile.sh -t -l ~/logs save /tmp/projet

# Combiné avec -f et -t
./src/snapfile.sh -f -t -l ~/logs save /tmp/projet
```
