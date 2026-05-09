# 🚀 Guide de Démarrage Rapide - Sprint 1

## Installation

```bash
cd SnapFile-linux
chmod +x snapfile.sh
```

## Tests Rapides

### 1. Afficher l'aide
```bash
./snapfile.sh -h
```

### 2. Tester la commande save
```bash
# Créer un dossier de test
mkdir -p test_folder
echo "Contenu de test" > test_folder/fichier1.txt

# Lancer la sauvegarde
./snapfile.sh save test_folder/
```

### 3. Vérifier la structure créée
```bash
ls -la ~/.snapfile/
# Vous devriez voir : objects/ snapshots/ index/
```

### 4. Consulter les logs
```bash
cat ~/.snapfile/snapfile.log
# ou
cat /var/log/snapfile/history.log
```

### 5. Tester les erreurs

**Erreur 100 (option inconnue) :**
```bash
./snapfile.sh -z save test_folder/
```

**Erreur 101 (paramètre manquant) :**
```bash
./snapfile.sh save
```

**Erreur 105 (sudo requis) :**
```bash
./snapfile.sh -r
# Puis avec sudo :
sudo ./snapfile.sh -r
```

### 6. Tester les options

**Option -f (fork) :**
```bash
./snapfile.sh -f save test_folder/
```

**Option -t (thread) :**
```bash
./snapfile.sh -t save test_folder/
```

**Option -l (log personnalisé) :**
```bash
mkdir -p ~/mes_logs
./snapfile.sh -l ~/mes_logs save test_folder/
cat ~/mes_logs/snapfile.log
```

## Lancer la Suite de Tests Complète

```bash
chmod +x test_sprint1.sh
./test_sprint1.sh
```

## Vérification Finale

Avant de livrer au Membre 2, vérifiez que :

- [x] `./snapfile.sh -h` affiche le manuel complet
- [x] `./snapfile.sh save test_folder/` crée `~/.snapfile/`
- [x] Les logs sont créés au bon format
- [x] Les erreurs 100, 101, 105 fonctionnent
- [x] Toutes les options (-f, -t, -s, -l, -r) sont reconnues
- [x] `./test_sprint1.sh` passe tous les tests

## Structure Livrée

```
SnapFile-linux/
├── snapfile.sh              # Script principal (Sprint 1 complet)
├── README_sprint1.md        # Documentation technique complète
├── GUIDE_DEMARRAGE.md       # Ce guide
├── test_sprint1.sh          # Suite de tests automatisés
└── test_folder/             # Dossier de test (exemple)
```

## Pour le Membre 2

Le Membre 2 peut maintenant :

1. Utiliser toutes les fonctions utilitaires (`log_event()`, `die()`, etc.)
2. Accéder aux variables globales (`$SNAPFILE_DIR`, `$OBJECTS_DIR`, etc.)
3. Implémenter la commande `save` à la ligne 318 de `snapfile.sh`
4. Utiliser les flags `$OPT_FORK` et `$OPT_THREAD`

**Point d'entrée pour le Sprint 2 :** Ligne 318 dans `snapfile.sh`

```bash
case "$COMMAND" in
    save)
        log_event "INFOS" "COMMAND: save $TARGET_DIR (fork=$OPT_FORK, thread=$OPT_THREAD)"
        # TODO Sprint 2 : Implémenter la sauvegarde ici
        ;;
```

## Support

Pour toute question sur le Sprint 1, consulter `README_sprint1.md` ou contacter le Membre 1.

**Bon courage pour le Sprint 2 ! 🎯**
