# SnapFile

Système de versionnement léger pour dossiers locaux sous Linux.

SnapFile capture des instantanés horodatés de vos dossiers. Chaque snapshot est stocké de façon compressée avec déduplication par hash SHA-256 — si un fichier n'a pas changé, il n'est pas re-stocké.

---

## Concept

Vous travaillez normalement sur vos fichiers. Quand vous voulez sauvegarder l'état actuel d'un dossier, vous lancez `snapfile save`. Plus tard, si vous avez besoin de revenir en arrière, `snapfile restore` remet les fichiers dans l'état exact du snapshot choisi.

Tout est stocké dans `~/.snapfile/` — pas de serveur, pas de configuration complexe.

---

## Installation

```bash
# Rendre le script exécutable
chmod +x src/snapfile.sh

# Optionnel : créer un alias global
echo "alias snapfile='$(pwd)/src/snapfile.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## Démarrage rapide

```bash
# 1. Initialiser le dépôt (une seule fois)
./src/snapfile.sh init

# 2. Sauvegarder un dossier
./src/snapfile.sh save mon_projet/

# 3. Voir l'historique des sauvegardes
./src/snapfile.sh log mon_projet/

# 4. Restaurer une version précédente
./src/snapfile.sh restore mon_projet/ --id 20260512143022
```

---

## Commandes

| Commande | Description |
|----------|-------------|
| `init` | Initialise le dépôt `~/.snapfile/` |
| `save <dossier>` | Crée un snapshot du dossier |
| `log <dossier>` | Affiche l'historique des snapshots |
| `restore <dossier> --id <ID>` | Restaure le snapshot correspondant à l'ID |

---

## Options

| Option | Description | Exemple |
|--------|-------------|---------|
| `-h` | Affiche l'aide complète | `./snapfile.sh -h` |
| `-m "message"` | Ajoute une description au snapshot | `./snapfile.sh save projet/ -m "version stable"` |
| `-f` | Fork : sauvegarde en arrière-plan | `./snapfile.sh -f save projet/` |
| `-t` | Thread : compression parallèle (gros dossiers) | `./snapfile.sh -t save projet/` |
| `-s` | Subshell : restauration en prévisualisation dans `/tmp/` | `./snapfile.sh -s restore projet/ --id <ID>` |
| `-l <chemin>` | Spécifie un dossier de logs personnalisé | `./snapfile.sh -l ~/mes_logs save projet/` |
| `-r` | Reset : supprime tous les snapshots (nécessite sudo) | `sudo ./snapfile.sh -r` |

> 

---

## Ajouter une description à un snapshot

Deux syntaxes sont acceptées :

```bash
# Via l'option -m (recommandé)
./src/snapfile.sh save mon_projet/ -m "Correction du bug de login"

# Via le 3ème argument positionnel
./src/snapfile.sh save mon_projet/ "Correction du bug de login"
```

Si aucun message n'est fourni, la description sera `Aucune description`.

---

## Restauration en prévisualisation (-s)

L'option `-s` restaure le snapshot dans `/tmp/snapfile_preview/` au lieu d'écraser le dossier original. Utile pour vérifier le contenu avant de vraiment restaurer.

```bash
./src/snapfile.sh -s restore mon_projet/ --id 20260512143022
# → fichiers restaurés dans /tmp/snapfile_preview/mon_projet/
```

---

## Structure du dépôt

```
~/.snapfile/
├── objects/      # Fichiers compressés, dédupliqués par hash SHA-256
├── snapshots/    # Métadonnées de chaque snapshot (.meta)
├── index/        # Index des snapshots par dossier
└── history.log   # Journal de toutes les opérations
```

Chaque fichier `.meta` contient :
```
source_dir=/chemin/vers/dossier
description=Mon message
date=2026-05-12 14:30:22
author=doha
fichier1.txt   a3f5b2c...
sous-dossier/fichier2.py   9e1d4f7...
```

---

## Codes d'erreur

| Code | Cause |
|------|-------|
| 100 | Option non reconnue |
| 101 | Chemin du dossier manquant ou invalide |
| 102 | Dépôt non initialisé ou aucun snapshot trouvé |
| 103 | ID de snapshot introuvable |
| 104 | Espace disque insuffisant |
| 105 | Conflit d'options ou sudo requis |
| 106 | Échec de compilation du worker C (gcc manquant) |
| 107 | Erreur système (fichier temporaire) |
| 108 | Interruption utilisateur (Ctrl+C) |

---

## Format des logs

```
yyyy-mm-dd-hh-mm-ss: username: TYPE: message
```

Exemple :
```
2026-05-12-14-30-22: doha: INFOS: SNAPSHOT_CREATED id=20260512143022 files=42 size=2M desc="version stable"
```

---

## Tests

```bash
# Suite de tests complète
chmod +x tests/test_complet.sh
./tests/test_complet.sh
```

---

## Structure du code source

```
src/
├── snapfile.sh        # Point d'entrée principal
└── lib/
    ├── init.sh        # init_repository(), validate_target_dir()
    ├── options.sh     # parse_options()
    ├── commands.sh    # cmd_init(), cmd_save(), cmd_log(), cmd_restore(), run_command()
    ├── reset.sh       # check_sudo(), reset_snapfile()
    ├── utils.sh       # usage(), log_event(), die()
    ├── fork_worker.c  # Worker C pour le mode fork (-f)
    └── thread_worker.c # Worker C pour le mode thread (-t)
```

---

## Licence

Projet académique — Théorie des Systèmes d'Exploitation, module SE Windows/Unix/Linux.
