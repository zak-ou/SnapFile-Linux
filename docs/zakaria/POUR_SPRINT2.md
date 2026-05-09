# 🔄 Guide de Transition : Sprint 1 → Sprint 2

**Destinataire :** Membre 2  
**De la part de :** Membre 1  
**Date :** 30 avril 2026

---

## 👋 Bienvenue Membre 2 !

Le Sprint 1 est terminé et tout est prêt pour que tu puisses commencer le Sprint 2. Ce document te guide pas à pas pour démarrer rapidement.

---

## 📦 Ce que tu reçois

### Fichiers Principaux

1. **`snapfile.sh`** — Script principal avec toute l'infrastructure
2. **`README_sprint1.md`** — Documentation technique complète
3. **`GUIDE_DEMARRAGE.md`** — Guide de démarrage rapide
4. **`test_sprint1.sh`** — Suite de tests pour valider le Sprint 1

### Structure du Dépôt

```
~/.snapfile/
├── objects/        # Pour stocker les fichiers dédupliqués (ton travail)
├── snapshots/      # Pour stocker les métadonnées (ton travail)
└── index/          # Pour le mapping hash → chemin (ton travail)
```

---

## 🎯 Ton Objectif (Sprint 2)

Implémenter la commande `save` avec :
1. Parcours récursif du dossier
2. Calcul SHA-256 de chaque fichier
3. Déduplication (ne stocker qu'une fois les fichiers identiques)
4. Compression avec tar/gzip
5. Création des métadonnées
6. Support des options `-f` (fork) et `-t` (threads)
7. Vérification de l'espace disque

---

## 🛠️ Outils à ta Disposition

### Fonctions Utilitaires (Déjà Implémentées)

```bash
# Logger un événement
log_event "INFOS" "SNAPSHOT_CREATED id=5 files=12 size=45M"
log_event "ERROR" "ERROR_104: Espace disque insuffisant"

# Gérer une erreur fatale (affiche l'aide et quitte)
die 104 "Espace disque insuffisant"
```

### Variables Globales (Déjà Définies)

```bash
$SNAPFILE_DIR        # ~/.snapfile
$OBJECTS_DIR         # ~/.snapfile/objects
$SNAPSHOTS_DIR       # ~/.snapfile/snapshots
$INDEX_DIR           # ~/.snapfile/index
$TARGET_DIR          # Chemin du dossier à sauvegarder (validé)
$OPT_FORK            # 1 si -f activé, 0 sinon
$OPT_THREAD          # 1 si -t activé, 0 sinon
```

---

## 📍 Où Commencer ?

### Point d'Entrée : Ligne 318 de `snapfile.sh`

```bash
case "$COMMAND" in
    save)
        log_event "INFOS" "COMMAND: save $TARGET_DIR (fork=$OPT_FORK, thread=$OPT_THREAD)"
        
        # ============================================================
        # C'EST ICI QUE TU DOIS TRAVAILLER !
        # ============================================================
        
        # Remplace ces lignes par ton implémentation :
        echo "🔄 Commande 'save' détectée pour : $TARGET_DIR"
        echo "⚠️  Fonctionnalité à implémenter dans le Sprint 2 (Membre 2)"
        ;;
```

---

## 💡 Suggestions d'Implémentation

### Étape 1 : Parcours Récursif

```bash
# Lister tous les fichiers du dossier
find "$TARGET_DIR" -type f | while read -r file; do
    echo "Traitement de : $file"
    # Calculer le hash, etc.
done
```

### Étape 2 : Calcul SHA-256

```bash
# Calculer le hash d'un fichier
hash=$(sha256sum "$file" | awk '{print $1}')
echo "Hash de $file : $hash"
```

### Étape 3 : Déduplication

```bash
# Vérifier si le hash existe déjà
if [ -f "$OBJECTS_DIR/$hash.gz" ]; then
    # Fichier déjà stocké, créer un lien symbolique
    ln -s "$OBJECTS_DIR/$hash.gz" "$temp_path"
else
    # Nouveau fichier, le compresser et le stocker
    gzip -c "$file" > "$OBJECTS_DIR/$hash.gz"
fi
```

### Étape 4 : Vérification Espace Disque

```bash
# Vérifier l'espace disponible
available=$(df "$SNAPFILE_DIR" | tail -1 | awk '{print $4}')
required=1000000  # En Ko

if [ $available -lt $required ]; then
    die 104 "Espace disque insuffisant"
fi
```

### Étape 5 : Option -f (Fork)

```bash
if [[ $OPT_FORK -eq 1 ]]; then
    # Lancer en arrière-plan
    (
        # Ton code de sauvegarde ici
        log_event "INFOS" "Background save completed"
    ) &
    
    pid=$!
    disown
    echo "Sauvegarde lancée en arrière-plan (PID: $pid)"
    exit 0
fi
```

### Étape 6 : Option -t (Threads)

```bash
if [[ $OPT_THREAD -eq 1 ]]; then
    # Diviser les fichiers en lots
    # Lancer plusieurs compressions en parallèle
    
    compress_file() {
        local file=$1
        gzip -c "$file" > "$OBJECTS_DIR/$(sha256sum "$file" | awk '{print $1}').gz"
    }
    
    export -f compress_file
    export OBJECTS_DIR
    
    # Lancer 4 processus en parallèle
    find "$TARGET_DIR" -type f | xargs -P 4 -I {} bash -c 'compress_file "{}"'
    
    wait  # Attendre que tous les processus se terminent
fi
```

### Étape 7 : Métadonnées du Snapshot

```bash
# Générer un ID unique
snapshot_id=$(ls "$SNAPSHOTS_DIR" | wc -l)
snapshot_id=$((snapshot_id + 1))

# Créer le fichier de métadonnées
cat > "$SNAPSHOTS_DIR/snapshot_${snapshot_id}.txt" << EOF
id=$snapshot_id
timestamp=$(date '+%Y-%m-%d-%H-%M-%S')
source_dir=$TARGET_DIR
files_count=$files_count
total_size=$total_size
EOF

# Logger le succès
log_event "INFOS" "SNAPSHOT_CREATED id=$snapshot_id files=$files_count size=$total_size"
```

---

## 🧪 Comment Tester Ton Code

### Test Simple

```bash
# Créer un dossier de test
mkdir -p test_projet
echo "Fichier 1" > test_projet/file1.txt
echo "Fichier 2" > test_projet/file2.txt

# Lancer la sauvegarde
./snapfile.sh save test_projet/

# Vérifier que les fichiers sont dans objects/
ls -la ~/.snapfile/objects/

# Vérifier les métadonnées
ls -la ~/.snapfile/snapshots/
cat ~/.snapfile/snapshots/snapshot_1.txt
```

### Test avec Fork (-f)

```bash
./snapfile.sh -f save test_projet/
# Doit afficher le PID et se terminer immédiatement
```

### Test avec Threads (-t)

```bash
# Créer un gros dossier
mkdir -p gros_projet
for i in {1..50}; do
    dd if=/dev/urandom of=gros_projet/file$i.bin bs=1M count=10
done

# Mesurer le temps sans threads
time ./snapfile.sh save gros_projet/

# Mesurer le temps avec threads
time ./snapfile.sh -t save gros_projet/
```

---

## 📋 Checklist de Ton Sprint 2

- [ ] Parcours récursif avec `find`
- [ ] Calcul SHA-256 avec `sha256sum`
- [ ] Déduplication (liens symboliques)
- [ ] Compression avec `gzip`
- [ ] Métadonnées des snapshots
- [ ] Option `-f` (fork)
- [ ] Option `-t` (threads)
- [ ] Vérification espace disque (erreur 104)
- [ ] Logs de succès
- [ ] Tests avec scénarios léger et moyen

---

## 🔍 Commandes Unix Utiles

```bash
# Parcours récursif
find /chemin -type f

# Calcul SHA-256
sha256sum fichier.txt

# Compression
gzip -c fichier.txt > fichier.txt.gz

# Décompression
gunzip -c fichier.txt.gz > fichier.txt

# Liens symboliques
ln -s source destination

# Espace disque
df -h ~/.snapfile

# Processus en arrière-plan
commande &
disown

# Parallélisme
wait
xargs -P 4
```

---

## 📞 Besoin d'Aide ?

1. **Consulte `README_sprint1.md`** pour la documentation technique
2. **Consulte `GUIDE_DEMARRAGE.md`** pour les exemples
3. **Lance `./test_sprint1.sh`** pour vérifier que le Sprint 1 fonctionne
4. **Contacte le Membre 1** si tu as des questions sur l'infrastructure

---

## 🎯 Format des Livrables Attendus

À la fin de ton Sprint 2, tu dois livrer :

1. **`snapfile.sh`** modifié avec la commande `save` fonctionnelle
2. **`test_save.sh`** — Script de test pour les scénarios léger et moyen
3. **`README_sprint2.md`** — Documentation de ton travail
4. **Format des métadonnées** documenté pour le Sprint 3

---

## 🚀 Bon Courage !

Tout est prêt pour que tu puisses travailler efficacement. Le Sprint 1 te fournit une base solide avec :

- ✅ Gestion des options
- ✅ Validation des paramètres
- ✅ Système de log
- ✅ Gestion des erreurs
- ✅ Structure du dépôt

Tu peux te concentrer à 100% sur la logique de sauvegarde et de déduplication.

**N'hésite pas à poser des questions si besoin !**

---

*Document préparé par le Membre 1*  
*Projet SnapFile - Sprint 1 → Sprint 2*
