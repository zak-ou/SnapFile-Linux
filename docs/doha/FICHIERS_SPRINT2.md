# 📂 Fichiers du Sprint 2 — Documentation Détaillée

> **Auteur :** Doha (Membre 2)  
> **Sprint :** 2 — Sauvegarde, Déduplication, Parallélisme  

---

## 📄 Fichier 1 : `src/lib/commands.sh`

### Rôle
Ce fichier est le **cœur de la logique du Sprint 2**. Il contient la fonction principale `cmd_save()` qui orchestre toutes les étapes d'une sauvegarde. Il est chargé par le script principal `snapfile.sh` via la commande `source`.

### Structure Interne

#### Fonction `process_file()`
```
Paramètres : $@ (un ou plusieurs chemins de fichiers)
```
C'est la fonction de traitement unitaire. Elle accepte un **lot de fichiers** en arguments. Pour chaque fichier :
1. Elle vérifie que le fichier existe réellement (`[ ! -f "$file" ]`).
2. Elle calcule son empreinte numérique avec **SHA-256** (`sha256sum`).
3. Elle vérifie si cet objet est déjà dans `~/.snapfile/objects/` (déduplication).
4. Si l'objet est nouveau, elle le compresse avec `gzip` et le stocke.
5. Elle enregistre le chemin relatif et le hash dans le fichier `.meta` en utilisant `flock` pour éviter les conflits d'écriture concurrents (race condition).
6. Elle enregistre la taille du fichier pour le calcul final.

**Exemple de ligne écrite dans le .meta :**
```
docs/rapport.pdf a3f2c1e8b0d7...
```

#### Fonction `cmd_save()`
C'est le chef d'orchestre. Voici ses étapes dans l'ordre :

| Étape | Code | Description |
| :--- | :--- | :--- |
| 1. Validation | `df -k` + `die 104` | Vérifie qu'il y a au moins 50 Mo d'espace disque disponible. |
| 2. ID Snapshot | `date '+%Y%m%d%H%M%S'` | Génère un identifiant unique basé sur l'horodatage. |
| 3. Fichier temp | `mktemp` + `die 107` | Crée un fichier temporaire pour stocker la liste des fichiers trouvés. |
| 4. Inventaire | `find "$TARGET_DIR" -type f` | Liste récursivement tous les fichiers du dossier cible. |
| 5. Traitement | Selon le mode | Appelle le bon worker (Normal, Fork ou Thread). |
| 6. Comparaison | `diff` + `sort` | Compare le nouveau snapshot avec le précédent. Annule si identique. |
| 7. Indexation | `echo >> "$INDEX_DIR"` | Ajoute l'ID du snapshot dans le fichier d'historique du dossier. |
| 8. Nettoyage | `rm -f "$tmpfile"` + `rm -f "*.lock"` | Supprime tous les fichiers temporaires. |

#### Gestion des 3 Modes
```
if OPT_FORK=1     → Compilation auto + lancement de fork_worker
elif OPT_THREAD=1 → Compilation auto + lancement de thread_worker
else              → Traitement séquentiel dans Bash
```

---

## 📄 Fichier 2 : `src/lib/fork_worker.c`

### Rôle
Ce programme C implémente le **mode Fork** (`-f`). Il est compilé automatiquement par le script Bash lors de son premier appel. Il est conçu pour paralléliser le traitement en créant des **processus fils indépendants**.

### Architecture

```
main()
├── Ouvrir le fichier liste
├── Lire les chemins ligne par ligne
├── Remplir un lot (batch) de 5 fichiers
└── Quand le lot est plein → execute_batch()

execute_batch()
├── fork() → crée un processus fils
│   └── Le fils : execvp("bash", ["bash", "-c", "process_file \"$@\"", ...])
│                  → transforme le processus en interpréteur Bash
│                  → appelle la fonction process_file sur les 5 fichiers
└── Le père : continue à lire le fichier liste
└── wait() → attendre la fin de TOUS les fils avant de terminer
```

### Points Techniques Importants
*   **`fork()`** : Crée une copie exacte du processus courant. Le père et le fils s'exécutent en parallèle.
*   **`execvp()`** : Remplace le processus fils par le programme `bash`. Cela permet d'appeler la fonction `process_file` exportée depuis le script parent.
*   **Passage des fichiers** : Les fichiers du lot sont passés comme arguments positionnels (`$1`, `$2`, ...) à la fonction bash via le mécanisme `"$@"`.
*   **`wait()`** : Le père appelle `wait()` en boucle jusqu'à ce que tous ses fils aient terminé, garantissant qu'aucun fils n'est abandonné (zombie process).

### Compilation
```bash
gcc -O3 src/lib/fork_worker.c -o src/lib/fork_worker
```

---

## 📄 Fichier 3 : `src/lib/thread_worker.c`

### Rôle
Ce programme C implémente le **mode Thread** (`-t`). Il utilise la bibliothèque **POSIX pthread** pour créer des **fils d'exécution légers** au sein du même processus. Contrairement au Fork, tous les threads partagent le même espace mémoire.

### Architecture

```
main()
├── Ouvrir le fichier liste
├── Lire les chemins ligne par ligne
├── Remplir un lot (Lot) de 5 fichiers dans une structure
└── Quand le lot est plein → pthread_create(&thread, traiter_lot)
    ├── Incrémenter le compteur de threads
    └── Si 4 threads actifs → pthread_join() → attendre avant d'en créer de nouveaux

traiter_lot(void *arg)
└── Pour chaque fichier dans le lot :
    ├── fork() + execlp("bash") → appel de process_file
    └── waitpid() → attendre la fin de ce fils avant le fichier suivant

pthread_join() → attendre tous les threads restants
```

### Structure de Données `Lot`
```c
typedef struct {
    char fichiers[MAX_FICHIERS][1024]; // Tableau des chemins
    int count;                          // Nombre de fichiers dans le lot
} Lot;
```
Chaque thread reçoit un pointeur vers une structure `Lot` qui lui appartient en propre (allouée avec `malloc`). Le thread libère la mémoire avec `free()` une fois son traitement terminé.

### Différence avec Fork
| Point | Fork | Thread |
| :--- | :--- | :--- |
| Mémoire | Espace isolé (copie) | Espace partagé |
| Création | `fork()` | `pthread_create()` |
| Attente | `wait()` | `pthread_join()` |
| Poids | Lourd (copie mémoire) | Léger (pas de copie) |

### Compilation
```bash
gcc -O3 src/lib/thread_worker.c -o src/lib/thread_worker -lpthread
```
> ⚠️ Le flag `-lpthread` est **obligatoire** pour lier la bibliothèque POSIX Threads.

---

## 📄 Fichier 4 : `tests/test_sprint2.sh`

### Rôle
Ce script automatise la **validation de toutes les fonctionnalités du Sprint 2**. Il suit la directive 3.2.4 de l'énoncé qui impose au moins 3 scénarios de test (léger, moyen, lourd).

### Suite de Tests

| N° | Test | Ce que ça valide |
| :--- | :--- | :--- |
| 1 | Préparation (12 fichiers) | L'environnement de test est propre. |
| 2 | Sauvegarde Normale | `cmd_save` fonctionne en mode séquentiel. |
| 3 | Mode FORK (`-f`) | Le `fork_worker` C se compile et s'exécute. |
| 4 | Mode THREAD (`-t`) | Le `thread_worker` C se compile et s'exécute. |
| 5 | Déduplication | Aucun objet supplémentaire créé pour un doublon. |
| 6 | No-change Skip | Le snapshot est annulé si le dossier n'a pas changé. |

### Comment lancer
```bash
cd ~/SnapFile-Linux/tests
./test_sprint2.sh
```

### Résultat attendu
```
✅ Succès  (test 2 - Normal)
✅ Succès  (test 3 - Fork)
✅ Succès  (test 4 - Thread)
✅ Succès  (test 5 - Déduplication)
✅ Succès  (test 6 - No-change)
🎉 TOUS LES TESTS DU SPRINT 2 SONT RÉUSSIS !
```

---
*Ce document fait partie intégrante de la livraison du Sprint 2.*
