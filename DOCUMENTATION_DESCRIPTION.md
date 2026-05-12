# 📘 DOCUMENTATION — Système de Description des Snapshots 

## SnapFile v1.0.0 — Fonctionnalité : Messages de Commit

---

## 1. RÉSUMÉ DE LA FONCTIONNALITÉ

Chaque snapshot peut désormais être accompagné d'une **description libre**,
similaire aux messages de commit de Git. Cette description est :

- **saisie** lors du `save`
- **stockée** dans le fichier `.meta` du snapshot
- **affichée** dans le `log` (historique)
- **affichée** lors du `restore` (aide à choisir le bon snapshot)

---

## 2. SYNTAXES SUPPORTÉES

```bash
# Syntaxe 1 — argument positionnel (3ème position)
./snapfile.sh save mon_projet/ "Ajout du module de restauration"

# Syntaxe 2 — option -m (recommandée, plus explicite)
./snapfile.sh save mon_projet/ -m "Correction du bug de suppression"

# Syntaxe 3 — sans message (valeur par défaut)
./snapfile.sh save mon_projet/
# → Description automatique : "Aucune description"

# Avec d'autres options
./snapfile.sh -f save mon_projet/ -m "Sauvegarde fork"
./snapfile.sh -t save gros_projet/ -m "Compression parallèle activée"
```

---

## 3. FICHIERS MODIFIÉS

| Fichier | Fonction(s) modifiée(s) | Raison |
|---|---|---|
| `src/lib/options.sh` | `parse_options()` | Capturer `-m "msg"` et le 3ème argument |
| `src/lib/commands.sh` | `cmd_save()` | Écrire la description dans `.meta` |
| `src/lib/commands.sh` | `cmd_log()` | Lire et afficher la description |
| `src/lib/commands.sh` | `cmd_restore()` | Afficher la description avant restauration |
| `src/lib/commands.sh` | `_read_meta_field()` | **NOUVELLE** — utilitaire de lecture `.meta` |
| `src/lib/utils.sh` | `usage()` | Documenter `-m` dans l'aide |
| `src/snapfile.sh` | point d'entrée | Initialiser `SNAP_MESSAGE=""` |

---

## 4. FORMAT DU FICHIER .meta (ÉTENDU)

### Avant (ancienne version) :
```
source_dir=/home/safa/mon_projet
fichier1.txt a3f5b2c8d1e4f7...
sous-dossier/fichier2.py 9e1d4f72b3c6...
```

### Après (nouvelle version) :
```
source_dir=/home/safa/mon_projet
description=Ajout du système de logs
date=2026-05-12 14:30:22
author=safa
fichier1.txt a3f5b2c8d1e4f7...
sous-dossier/fichier2.py 9e1d4f72b3c6...
```

**Les 4 premières lignes sont les métadonnées, le reste est le contenu.**

---

## 5. EXPLICATION DÉTAILLÉE DES MODIFICATIONS

### 5.1 — `options.sh` : Capturer le message

```bash
# Ajout de "m:" dans la chaîne getopts
while getopts ":hftsl:rm:" opt; do
    ...
    m)
        SNAP_MESSAGE="$OPTARG"   # -m "mon message"
        ;;
    ...
done

# 3ème argument positionnel (si -m non utilisé)
if [[ -z "$SNAP_MESSAGE" && -n "${3:-}" ]]; then
    SNAP_MESSAGE="${3}"
fi

# Valeur par défaut
if [[ -z "$SNAP_MESSAGE" ]]; then
    SNAP_MESSAGE="Aucune description"
fi

export SNAP_MESSAGE
```

**Pourquoi ?**
- `getopts` ne gère pas nativement les arguments positionnels après les options.
- On lit d'abord `-m` (prioritaire), puis le 3ème argument si `-m` absent.
- `export` rend `SNAP_MESSAGE` accessible dans les sous-processus.

---

### 5.2 — `cmd_save()` : Écrire la description dans `.meta`

```bash
local snap_date
snap_date=$(date '+%Y-%m-%d %H:%M:%S')
local snap_author
snap_author=$(whoami)

{
    echo "source_dir=$TARGET_DIR"
    echo "description=${SNAP_MESSAGE}"    # ← NOUVEAU
    echo "date=${snap_date}"              # ← NOUVEAU
    echo "author=${snap_author}"          # ← NOUVEAU
} > "$meta_file"
```

**Pourquoi ?**
- Le fichier `.meta` est le seul endroit persistant par snapshot.
- Stocker `description`, `date` et `author` ensemble garantit que
  chaque snapshot est autonome (pas de fichier externe à synchroniser).

**Modification de la comparaison de changements :**
```bash
# Avant : grep -v "source_dir=" ...
# Après : ignorer TOUS les champs de métadonnées
grep -v -E "^(source_dir|description|date|author)=" "$meta_file" | sort
```
**Pourquoi ?** Sans ça, deux snapshots identiques mais avec des descriptions
différentes auraient semblé différents, invalidant la déduplication.

---

### 5.3 — `_read_meta_field()` : Utilitaire de lecture

```bash
_read_meta_field() {
    local meta_file="$1"
    local field="$2"
    grep "^${field}=" "$meta_file" 2>/dev/null | head -1 | cut -d'=' -f2-
}
```

**Pourquoi ?**
- Factorisation du code : `cmd_log()` et `cmd_restore()` utilisent tous deux
  la même logique de lecture.
- `cut -d'=' -f2-` (avec `-f2-`) prend tout après le premier `=`,
  donc un message contenant `=` est correctement lu.
- Robuste aux anciens snapshots : retourne `""` si le champ est absent.

---

### 5.4 — `cmd_log()` : Afficher l'historique enrichi

**Avant** (tableau compact) :
```
ID                   Date                 Fichiers   Taille
-------------------- -------------------- ---------- ------------
20260512143022       12/05/2026 14:30:22  5          12 Ko
```

**Après** (blocs lisibles) :
```
  ┌─────────────────────────────────────────────────┐
  │ ID     : 20260512143022                         │
  │ Date   : 2026-05-12 14:30:22                    │
  │ Auteur : safa                                   │
  │ Fichiers: 5 fichier(s) — 12 Ko                  │
  │ Desc   : Ajout du système de logs               │
  └─────────────────────────────────────────────────┘
```

**Compatibilité descendante** : si un champ est absent (anciens snapshots),
une valeur par défaut est appliquée (`"inconnu"`, `"Aucune description"`).

---

### 5.5 — `cmd_restore()` : Afficher avant de restaurer

```bash
echo "   ID          : $snap_id"
echo "   Date        : $snap_date_stored"
echo "   Auteur      : $snap_author"
echo "   Description : $description"
echo ""
read -rp "⚠️  Ceci va écraser les fichiers actuels. Continuer ? (oui/non) : " confirm
```

**Pourquoi ?**
- L'utilisateur voit la description **avant** de confirmer la restauration.
- Si plusieurs snapshots existent, la description aide à choisir le bon.
- Évite les restaurations accidentelles sur le mauvais état.

---

## 6. COMPATIBILITÉ AVEC LES ANCIENS SNAPSHOTS

La modification est **rétro-compatible** :
- Les anciens `.meta` sans `description=`, `date=`, `author=` sont lus normalement.
- `_read_meta_field()` retourne `""` si le champ est absent.
- Des valeurs par défaut (`"Aucune description"`, `"inconnu"`) sont appliquées.
- La comparaison de changements dans `cmd_save()` ignore les nouveaux champs.

---

## 7. TESTS RAPIDES

```bash
cd src/
chmod +x snapfile.sh

# Initialiser
./snapfile.sh init

# Créer un dossier test
mkdir -p /tmp/test_snap && echo "Hello" > /tmp/test_snap/file1.txt

# Test 1 : save sans message
./snapfile.sh save /tmp/test_snap

# Test 2 : save avec message positionnel
echo "world" > /tmp/test_snap/file2.txt
./snapfile.sh save /tmp/test_snap "Ajout de file2.txt"

# Test 3 : save avec -m
echo "foo" > /tmp/test_snap/file3.txt
./snapfile.sh save /tmp/test_snap -m "Correction du bug #42"

# Test 4 : voir l'historique avec descriptions
./snapfile.sh log /tmp/test_snap

# Test 5 : restaurer (affiche la description avant confirmation)
./snapfile.sh restore /tmp/test_snap --id <ID_DU_SNAP>
```

---

## 8. QUESTIONS DU PROFESSEUR ET RÉPONSES

### Q1 : Pourquoi stocker la description dans le fichier `.meta` plutôt que dans un fichier séparé ?

**Réponse :**
Chaque snapshot possède déjà son fichier `.meta` comme source de vérité.
Y intégrer la description garantit que toutes les informations d'un snapshot
sont **colocalisées** : si on copie ou déplace le répertoire `snapshots/`,
les descriptions suivent automatiquement. Un fichier séparé (ex: `.desc`)
introduirait un risque de désynchronisation et compliquerait les opérations
de suppression, de listage et de restauration.

---

### Q2 : Pourquoi avoir choisi `getopts` avec `m:` plutôt qu'une autre approche ?

**Réponse :**
`getopts` est le mécanisme standard POSIX de Bash pour parser les options.
Ajouter `m:` dans la chaîne de format signifie que `-m` attend un argument
obligatoire. C'est cohérent avec les conventions Unix (`-l <chemin>` existait
déjà dans le projet). L'alternative `getopt` (long) aurait permis `--message`,
mais aurait ajouté une dépendance externe et rompu la cohérence du style.

---

### Q3 : Comment évitez-vous que la description brise la comparaison de changements ?

**Réponse :**
Dans `cmd_save()`, avant de comparer deux snapshots pour détecter si des
fichiers ont changé, on filtre les lignes de métadonnées :

```bash
grep -v -E "^(source_dir|description|date|author)=" "$meta_file" | sort
```

Sans ce filtre, deux snapshots identiques avec des descriptions différentes
sembleraient différents, et un nouveau snapshot inutile serait créé.

---

### Q4 : Qu'est-ce que la compatibilité descendante et comment l'avez-vous assurée ?

**Réponse :**
La compatibilité descendante signifie que les nouvelles versions du code
fonctionnent correctement avec des données créées par les anciennes versions.

Les anciens `.meta` n'ont pas de ligne `description=` ni `date=`.
La fonction `_read_meta_field()` retourne `""` si la ligne est absente.
On applique alors des valeurs par défaut :

```bash
[[ -z "$description" ]] && description="Aucune description"
[[ -z "$snap_author" ]] && snap_author="inconnu"
```

Ainsi, `cmd_log()` et `cmd_restore()` fonctionnent avec les anciens **et**
les nouveaux snapshots sans modification de données ni migration.

---

### Q5 : En quoi ce système est-il similaire aux commits Git ? Quelles sont les différences ?

**Réponse :**

**Similitudes :**
- Chaque sauvegarde (commit/snapshot) a un ID unique, une date, un auteur et un message.
- Le message permet de retrouver l'état de la situation à un moment donné.
- L'historique (`log`) liste tous les commits/snapshots avec leur description.
- La restauration (`checkout`/`restore`) affiche les métadonnées du commit.

**Différences :**
| Aspect | Git commit | SnapFile snapshot |
|---|---|---|
| ID | Hash SHA-1/SHA-256 du contenu | Horodatage (YYYYMMDDHHmmSS) |
| Message | Obligatoire (peut être vide) | Optionnel, défaut = "Aucune description" |
| Branches | Gestion de branches | Pas de branches |
| Staging | Index/staging area | Snapshot direct du dossier |
| Distribution | Push/pull/remote | Local uniquement |
| Déduplication | Content-addressable storage | SHA-256 sur objets |

---

### Q6 : Pourquoi `cut -d'=' -f2-` et pas `cut -d'=' -f2` dans `_read_meta_field()` ?

**Réponse :**
Si le message contient lui-même le caractère `=` (ex: `description=x=y`),
`cut -d'=' -f2` ne retournerait que `x`, perdant `=y`.
`-f2-` signifie "du 2ème champ jusqu'à la fin", donc on obtient correctement
`x=y`. C'est une précaution importante pour ne pas tronquer les messages
utilisateur qui pourraient contenir des signes égal.

---

### Q7 : Quels avantages apporte cette fonctionnalité à SnapFile ?

**Réponse :**
1. **Traçabilité** : on sait pourquoi chaque snapshot a été créé.
2. **Réduction des erreurs** : lors d'un `restore`, voir la description
   aide à choisir le bon snapshot et évite les restaurations accidentelles.
3. **Collaboration** : avec le champ `author`, plusieurs utilisateurs
   peuvent identifier qui a créé quel snapshot.
4. **Maintenance** : l'historique devient lisible, comme un journal de bord.
5. **Pédagogie** : introduit les concepts de métadonnées, de versionnement
   documenté et de bonne pratique de développement.

---

### Q8 : Comment avez-vous assuré la cohérence avec le mode Fork/Thread ?

**Réponse :**
La variable `SNAP_MESSAGE` est déclarée avec `export` dans `parse_options()`,
ce qui la rend disponible dans les sous-processus créés par le mode Fork.
Les métadonnées (description, date, auteur) sont écrites dans le `.meta`
**avant** le lancement des workers, donc elles sont toujours présentes
même si un worker se termine avant les autres.

---

## 9. RÉSUMÉ VISUEL DU FLUX

```
Utilisateur tape :
./snapfile.sh save mon_projet/ -m "Fix bug #42"
         │
         ▼
parse_options()
  → SNAP_MESSAGE = "Fix bug #42"
  → COMMAND      = "save"
  → TARGET_DIR   = "mon_projet/"
         │
         ▼
cmd_save()
  → Crée snap_id = 20260512143022
  → Écrit dans .meta :
      source_dir=mon_projet/
      description=Fix bug #42     ← NOUVEAU
      date=2026-05-12 14:30:22    ← NOUVEAU
      author=safa                 ← NOUVEAU
      fichier1.txt a3f5b2...
  → Affiche résumé avec description
         │
         ▼
cmd_log()         (quand l'utilisateur tape : log)
  → Lit description dans .meta
  → Affiche bloc enrichi avec description
         │
         ▼
cmd_restore()     (quand l'utilisateur tape : restore --id ...)
  → Lit description dans .meta
  → Affiche infos avant confirmation
  → Restaure les fichiers
```
