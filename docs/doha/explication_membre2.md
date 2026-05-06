# 📖 Explication Détaillée du Code — Sprint 2

> Ce document explique chaque bloc de code implémenté pour la commande `save`,
> destiné à être compris facilement par tous les membres de l'équipe.

---

## 📄 Fichier modifié : `src/lib/commands.sh`

---

## ✅ Étape 1 — Vérification de l'espace disque

```bash
local avail_space
avail_space=$(df -k "$TARGET_DIR" | tail -1 | awk '{print $4}')
[ "$avail_space" -lt 51200 ] && die 104 "Espace insuffisant"
```

**Explication détaillée :**
- `df -k "$TARGET_DIR"` : Affiche l'espace disque en **kilo-octets** pour la partition où se trouve le dossier cible.
- `tail -1` : On garde seulement la **dernière ligne** (celle qui contient les données, pas l'en-tête).
- `awk '{print $4}'` : On extrait la **4ème colonne**, qui représente l'espace disponible.
- `-lt 51200` : En bash, `-lt` signifie "less than" (inférieur à). 51200 Ko = **50 Mo**.
- Si l'espace est insuffisant → `die 104` arrête le programme avec une erreur et affiche l'aide.

---

## ✅ Étape 2 — Génération de l'identifiant de snapshot

```bash
local snap_id
snap_id=$(date '+%Y%m%d%H%M%S')
local meta_file="$SNAPSHOTS_DIR/${snap_id}.meta"
local tmpfile
tmpfile=$(mktemp) || die 107 "Impossible de créer un fichier temporaire"
```

**Explication détaillée :**
- `date '+%Y%m%d%H%M%S'` : Génère une chaîne basée sur la date et l'heure (ex: `20260504023310`). Cet ID est **unique** car deux sauvegardes ne peuvent pas se déclencher à la même seconde.
- `mktemp` : Crée un fichier temporaire dans `/tmp/` avec un nom aléatoire pour y stocker la liste des fichiers à traiter.
- `|| die 107` : Si `mktemp` échoue (système saturé), on déclenche l'erreur 107 proprement.

---

## ✅ Étape 3 — Inventaire des fichiers

```bash
find "$TARGET_DIR" -type f > "$tmpfile"
echo "source_dir=$TARGET_DIR" > "$meta_file"
```

**Explication détaillée :**
- `find "$TARGET_DIR" -type f` : Parcourt **récursivement** le dossier cible et liste uniquement les fichiers (pas les dossiers). La liste est sauvegardée dans le fichier temporaire créé à l'étape 2.
- `echo "source_dir=..."` : Initialise le fichier `.meta` avec la première ligne (chemin du dossier source). Cette ligne sera utilisée par le Membre 3 pour la commande `log`.

---

## ✅ Étape 4 — La fonction `process_file` (Cœur du traitement)

```bash
process_file() {
    for file in "$@"; do
        [ ! -f "$file" ] && continue
        
        local hash
        hash=$(sha256sum "$file" | awk '{print $1}')
        local obj_path="$OBJECTS_DIR/${hash}.gz"
        local file_size
        file_size=$(stat -c%s "$file")
        
        if [ ! -f "$obj_path" ]; then
            gzip -c "$file" > "$obj_path" || continue
        fi
        
        local relative_path="${file#$TARGET_DIR/}"
        
        (
            flock 200
            echo "$relative_path $hash" >> "$meta_file"
        ) 200>"$meta_file.lock"
        
        echo "$file_size" >> "/tmp/snap_${snap_id}.size"
    done
}
```

**Explication ligne par ligne :**

| Ligne | Explication |
| :--- | :--- |
| `for file in "$@"` | Boucle sur tous les fichiers passés en argument (max 5 par appel). |
| `[ ! -f "$file" ]` | Vérifie que le fichier existe vraiment avant de le traiter. |
| `sha256sum "$file"` | Calcule l'empreinte numérique unique du contenu du fichier. |
| `awk '{print $1}'` | Extrait uniquement le hash (pas le nom de fichier que sha256sum inclut). |
| `$OBJECTS_DIR/${hash}.gz` | Chemin de stockage : le hash devient le nom du fichier. |
| `if [ ! -f "$obj_path" ]` | **Déduplication** : ne compresser que si cet objet n'existe pas encore. |
| `gzip -c "$file"` | Compresse le fichier en envoyant le résultat vers stdout (`-c`). |
| `${file#$TARGET_DIR/}` | Opération de suppression de préfixe en bash. Ex: `/home/doha/test/a.txt` → `a.txt`. |
| `flock 200` | Verrou exclusif pour éviter que deux processus écrivent simultanément. |
| `echo "$file_size" >> ...` | Enregistre la taille pour calculer le total à la fin. |

---

## ✅ Étape 5 — Dispatch selon le mode (`-f`, `-t`, ou normal)

```bash
if [ "$OPT_FORK" -eq 1 ]; then
    if [ ! -f "$SCRIPT_DIR/lib/fork_worker" ]; then
        gcc -O3 "$SCRIPT_DIR/lib/fork_worker.c" -o "$SCRIPT_DIR/lib/fork_worker" \
            || die 106 "Échec de compilation du fork_worker (gcc requis)"
    fi
    export -f process_file
    export TARGET_DIR OBJECTS_DIR meta_file snap_id
    "$SCRIPT_DIR/lib/fork_worker" "$tmpfile"

elif [ "$OPT_THREAD" -eq 1 ]; then
    if [ ! -f "$SCRIPT_DIR/lib/thread_worker" ]; then
        gcc -O3 "$SCRIPT_DIR/lib/thread_worker.c" -o "$SCRIPT_DIR/lib/thread_worker" -lpthread \
            || die 106 "Échec de compilation du thread_worker (gcc requis)"
    fi
    export -f process_file
    export TARGET_DIR OBJECTS_DIR meta_file snap_id
    "$SCRIPT_DIR/lib/thread_worker" "$tmpfile"

else
    while IFS= read -r file; do
        process_file "$file"
    done < "$tmpfile"
fi
```

**Explication par mode :**

- **Mode Normal** : Simple boucle `while read` qui traite les fichiers un par un, dans l'ordre.
- **Mode Fork (`-f`)** : Compile le worker C si nécessaire, exporte les variables et la fonction bash, puis délègue tout au programme C. Ce programme créera des processus fils indépendants.
- **Mode Thread (`-t`)** : Identique mais utilise `pthread`. Important : le flag `-lpthread` est obligatoire pour que `pthread_create` fonctionne.
- `export -f process_file` : **Obligatoire** pour que les sous-shells créés par les workers C puissent accéder à la fonction bash.

---

## ✅ Étape 6 — Vérification de non-changement (No-Change Skip)

```bash
local last_meta
last_meta=$(tail -n 1 "$INDEX_DIR/${dir_name}.list" 2>/dev/null)

if [ -n "$last_meta" ] && [ -f "$SNAPSHOTS_DIR/$last_meta" ]; then
    grep -v "source_dir=" "$SNAPSHOTS_DIR/$last_meta" | sort > "/tmp/last.tmp"
    grep -v "source_dir=" "$meta_file" | sort > "/tmp/curr.tmp"

    if diff "/tmp/last.tmp" "/tmp/curr.tmp" > /dev/null; then
        echo "ℹ️ Aucun changement détecté. Annulation."
        rm -f "$meta_file" "$meta_file.lock" "$tmpfile" ...
        return 0
    fi
fi
```

**Explication :**
- `tail -n 1` : Récupère le dernier snapshot connu pour ce dossier.
- `grep -v "source_dir="` : On exclut la 1ère ligne (chemin source) pour comparer uniquement les fichiers.
- `sort` : **Crucial en mode Fork et Thread** car les processus parallèles peuvent écrire dans un ordre imprévisible. Le tri permet une comparaison fiable.
- `diff > /dev/null` : Si les deux fichiers sont identiques, `diff` retourne 0 (succès) et on annule le snapshot.

---

## ✅ Étape 7 — Finalisation et Indexation

```bash
files_count=$(wc -l < "$tmpfile")
total_size=$(awk '{s+=$1} END {print s}' "/tmp/snap_${snap_id}.size")
echo "${snap_id}.meta" >> "$INDEX_DIR/${dir_name}.list"
rm -f "$tmpfile"
rm -f "$meta_file.lock"
```

**Explication :**
- `wc -l` : Compte le nombre de lignes dans la liste pour connaître le nombre de fichiers traités.
- `awk '{s+=$1} END {print s}'` : Somme toutes les tailles de fichiers enregistrées pour afficher la taille totale.
- `echo "${snap_id}.meta" >> "$INDEX_DIR/..."` : Ajoute l'ID du snapshot dans le fichier d'index du dossier. C'est cela qui permettra au Membre 3 de lister l'historique.
- `rm -f "$meta_file.lock"` : Supprime le fichier de verrou devenu inutile.

---

*Fin de l'explication du code — Sprint 2*
