# 📘 Documentation Technique Complète — Sprint 2

> **Auteur** : Doha (Membre 2)  
> **Rôle** : Développeur Backend & Optimisation Parallèle  
> **Projet** : SnapFile v1.0.0 — Versionnement & Restauration Légère de Fichiers  
> **Module** : Théorie des Systèmes d'Exploitation & SE Windows/Unix/Linux  

---

## 🎯 Objectifs du Sprint 2

Le Sprint 2 avait pour mission d'implémenter la commande `save` complète, en intégrant :
1. **La déduplication** par empreinte SHA-256 pour éviter la redondance de stockage.
2. **Le parallélisme réel** via deux programmes C distincts : `fork_worker` et `thread_worker`.
3. **La robustesse** avec la gestion du verrou (`flock`), la détection de non-changement, et des codes d'erreur explicites.

---

## 🏗️ Concept de Stockage (Data Model)

Le projet s'inspire de l'architecture de Git : le stockage est adressable par contenu.

```
~/.snapfile/
├── objects/         ← Données réelles compressées (nommées par hash SHA-256)
│   ├── a3f2c1e8....gz
│   └── d8f1b0c2....gz
├── snapshots/       ← Métadonnées de chaque sauvegarde
│   ├── 20260504023310.meta
│   └── 20260504023310.meta.lock  (temporaire, supprimé à la fin)
└── index/           ← Historique par dossier source
    └── test_snap.list
```

### Rôle de chaque dossier
| Dossier | Contenu | Rôle |
| :--- | :--- | :--- |
| `objects/` | Fichiers `.gz` nommés par hash | Stockage unique (déduplication) |
| `snapshots/` | Fichiers `.meta` par snapshot | Recette pour restaurer l'état |
| `index/` | Fichiers `.list` par dossier | Historique des snapshots |

### Format d'un fichier `.meta`
```
source_dir=/home/doha/test_snap
docs/rapport.pdf  a3f2c1e8b0d7a1f9...
src/main.c        d8f1b0c256e3a2b1...
README.md         f7e2d1c390b8a4e5...
```
Chaque ligne représente un fichier : son chemin relatif + son hash SHA-256.

---

## 🔄 Cycle de Vie d'une Sauvegarde (`cmd_save`)

Quand on exécute `./snapfile.sh save /mon/dossier`, voici les étapes précises :

```
[1] Vérification espace disque
       ↓
[2] Génération de l'ID (timestamp)
       ↓
[3] Listing des fichiers avec `find`
       ↓
[4] Traitement selon le mode
    ├── Normal  → séquentiel en Bash
    ├── -f Fork → fork_worker.c (processus fils)
    └── -t Thread → thread_worker.c (threads pthread)
         ↓
[5] Comparaison avec le snapshot précédent
    ├── Identique → ANNULATION (no-change skip)
    └── Différent → continuer
         ↓
[6] Mise à jour de l'index
         ↓
[7] Nettoyage des fichiers temporaires
         ↓
[8] Journalisation dans /var/log/snapfile/history.log
```

---

## 🛠️ Architecture de la Solution

### 1. La Fonction `process_file` (Bash — dans `commands.sh`)

C'est le **cœur du traitement**. Elle accepte plusieurs fichiers en arguments (jusqu'à 5) et traite chacun d'eux :

```bash
process_file() {
    for file in "$@"; do                        # Boucle sur chaque fichier reçu
        [ ! -f "$file" ] && continue            # Ignorer si le fichier n'existe plus

        hash=$(sha256sum "$file" | awk '{print $1}')       # Calcul SHA-256
        obj_path="$OBJECTS_DIR/${hash}.gz"                 # Chemin de stockage
        file_size=$(stat -c%s "$file")                     # Taille en octets

        if [ ! -f "$obj_path" ]; then           # Déduplication : ne compresser que si nouveau
            gzip -c "$file" > "$obj_path"
        fi

        relative_path="${file#$TARGET_DIR/}"    # Chemin relatif (sans le préfixe du dossier)

        (                                       # Écriture dans le .meta avec verrou
            flock 200                           # Pose le verrou (empêche les écritures simultanées)
            echo "$relative_path $hash" >> "$meta_file"
        ) 200>"$meta_file.lock"                 # Fichier de verrouillage

        echo "$file_size" >> "/tmp/snap_${snap_id}.size"   # Taille pour le résumé final
    done
}
export -f process_file
export TARGET_DIR OBJECTS_DIR meta_file snap_id            # Rendre accessible aux sous-shells
```

#### Pourquoi `flock` ?
Quand plusieurs processus ou threads écrivent dans le même fichier `.meta` en même temps, il y a un risque de **race condition** (corruption des données). `flock` pose un verrou exclusif : seul un processus à la fois peut écrire. Les autres attendent leur tour.

---

### 2. Le Worker Fork (`src/lib/fork_worker.c`)

#### Principes Fondamentaux

| Concept | Explication |
| :--- | :--- |
| `fork()` | Duplique le processus courant. Le père et le fils s'exécutent en parallèle avec leur propre espace mémoire. |
| `execvp()` | Remplace le processus fils par un autre programme (ici `bash`). La mémoire du fils est remplacée. |
| `wait()` | Le père bloque jusqu'à ce qu'un fils termine. Évite les processus zombies. |

#### Diagramme de fonctionnement
```
PÈRE (fork_worker)
│
├── Lit 5 fichiers → execute_batch()
│       └── fork()
│            ├── FILS 1 → execvp(bash) → process_file f1 f2 f3 f4 f5 → EXIT
│
├── Lit 5 fichiers suivants → execute_batch()
│       └── fork()
│            ├── FILS 2 → execvp(bash) → process_file f6 f7 f8 f9 f10 → EXIT
│
└── wait() → attend FILS 1 et FILS 2 (en parallèle !)
```

#### Code clé commenté
```c
void execute_batch(char *files[], int count) {
    pid_t pid = fork();            // Créer un processus fils
    if (pid == 0) {                // On est dans le fils
        char *args[BATCH_SIZE + 5];
        args[0] = "bash";
        args[1] = "-c";
        args[2] = "process_file \"$@\"";  // Appel de la fonction bash exportée
        args[3] = "bash_worker";          // Nom du script (pour $@)
        for (int i = 0; i < count; i++) args[i+4] = files[i]; // Fichiers en args
        args[count + 4] = NULL;
        execvp("bash", args);      // Transformer le fils en bash
    }
    // Le père continue immédiatement (non-bloquant)
}
// En fin de programme :
while (wait(&status) > 0);         // Le père attend TOUS ses fils
```

---

### 3. Le Worker Thread (`src/lib/thread_worker.c`)

#### Différence fondamentale avec le Fork
Contrairement aux processus, les threads **partagent la même mémoire**. Ils sont plus légers à créer et permettent une communication directe. En contrepartie, une erreur grave dans un thread peut affecter tout le programme.

#### Structure de données
```c
typedef struct {
    char fichiers[MAX_FICHIERS][1024]; // Tableau de 5 chemins de fichiers max
    int count;                          // Nombre réel de fichiers dans le lot
} Lot;
```
Chaque thread reçoit un pointeur vers son propre `Lot` alloué avec `malloc()`. Il libère la mémoire avec `free()` une fois son travail terminé.

#### Diagramme de fonctionnement
```
Programme principal (thread_worker)
│
├── Lot 1 (5 fichiers) → pthread_create → THREAD 1 → traiter_lot() → free() → EXIT
├── Lot 2 (5 fichiers) → pthread_create → THREAD 2 → traiter_lot() → free() → EXIT
├── Lot 3 (5 fichiers) → pthread_create → THREAD 3 → traiter_lot() → free() → EXIT
├── Lot 4 (5 fichiers) → pthread_create → THREAD 4 → traiter_lot() → free() → EXIT
│
└── [MAX 4 threads] → pthread_join() → Attendre avant d'en créer de nouveaux
```

#### Code clé commenté
```c
void *traiter_lot(void *arg) {
    Lot *lot = (Lot *)arg;              // Récupérer le lot de fichiers

    for (int i = 0; i < lot->count; i++) {
        pid_t pid = fork();             // Fork dans le thread pour appeler bash
        if (pid == 0) {
            execlp("bash", "bash", "-c", "process_file \"$1\"",
                   "bash_worker", lot->fichiers[i], NULL);
        } else {
            waitpid(pid, NULL, 0);     // Attendre que bash finisse ce fichier
        }
    }

    free(lot);                          // Libérer la mémoire du lot
    return NULL;
}
```

---

## 📊 Analyse Comparative : Fork vs Thread

| Caractéristique | Mode FORK (`-f`) | Mode THREAD (`-t`) |
| :--- | :--- | :--- |
| **Mémoire** | Copie de l'espace mémoire (lourd) | Mémoire partagée (léger) |
| **Vitesse de création** | Plus lent | Plus rapide |
| **Isolation** | Totale (crash d'un fils = pas d'impact) | Partielle (crash grave = tout s'arrête) |
| **Communication** | Difficile (IPC, pipes) | Facile (variables partagées) |
| **Appel système** | `fork()` + `execvp()` | `pthread_create()` + `pthread_join()` |

### Résultats de Performance (100 fichiers)

| Mode | Temps réel | Gain |
| :--- | :--- | :--- |
| Normal (séquentiel) | 4,629 s | — |
| Thread (`-t`) | 2,466 s | **-46%** |

> Ces mesures ont été obtenues avec la commande `time ./snapfile.sh [options] save ~/test_large`.

---

## ⚠️ Codes d'Erreur Spécifiques au Sprint 2

| Code | Message | Cause | Déclencheur |
| :--- | :--- | :--- | :--- |
| **104** | Espace disque insuffisant | < 50 Mo disponibles | `df -k` dans `cmd_save` |
| **106** | Échec de compilation | `gcc` absent ou erreur C | Compilation des workers |
| **107** | Erreur système | `mktemp` échoue | Pas d'accès à `/tmp` |
| **108** | Interruption utilisateur | `Ctrl+C` | `trap SIGINT` dans `snapfile.sh` |

---

## 📈 Conclusion et Impact

Les tests montrent une réduction du temps de traitement de **46%** sur 100 fichiers avec le mode Thread. Sur des volumes plus importants (500+ fichiers), ce gain devient encore plus significatif. La déduplication SHA-256 garantit qu'aucun espace n'est gaspillé pour des contenus identiques.

---
*Fin de la documentation Sprint 2 — Doha (Membre 2)*
