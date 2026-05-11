# 🎤 Présentation Sprint 1 — Réunion d'Équipe

**Membre :** Zakaria  
**Sprint :** 1 — Initialisation & Architecture  
**Date :** 30 avril 2026

---

## 🎯 Mon Rôle dans le Projet

Mon rôle dans le Sprint 1 était de **construire la base du projet** : la structure, les outils communs, et le squelette que les autres membres allaient utiliser dans leurs sprints.

Sans mon travail, les autres membres n'auraient pas pu commencer.

---

## 📦 Ce que j'ai livré

### 1. Le Script Principal — `snapfile.sh`

C'est le **point d'entrée** du programme. Quand l'utilisateur tape une commande, c'est ce fichier qui s'exécute en premier.

Il fait 5 choses dans l'ordre :
```
1. Parser les options (-f, -t, -s, -l, -r, -h)
2. Traiter le reset (-r) si demandé
3. Valider le dossier cible
4. Initialiser le dépôt ~/.snapfile/
5. Lancer la bonne commande (save / log / restore)
```

---

### 2. Le Parseur d'Options — `getopts`

J'ai implémenté la lecture de toutes les options de la ligne de commande.

**Options implémentées :**

| Option | Ce qu'elle fait |
|--------|----------------|
| `-h` | Affiche le manuel d'aide |
| `-f` | Active le mode fork (arrière-plan) |
| `-t` | Active le mode thread (parallèle) |
| `-s` | Active le mode subshell (prévisualisation) |
| `-l <chemin>` | Définit un dossier de logs personnalisé |
| `-r` | Réinitialise tout (nécessite sudo) |

**Exemple :**
```bash
./snapfile.sh -f -t -l ~/logs save mon_projet/
#              ↑   ↑  ↑        ↑    ↑
#           fork thread logs  cmd  dossier
```

---

### 3. La Structure du Dépôt — `~/.snapfile/`

J'ai créé la fonction qui initialise automatiquement le dépôt de stockage au premier lancement.

```
~/.snapfile/
├── objects/      → Fichiers compressés (stockés par hash SHA-256)
├── snapshots/    → Métadonnées de chaque snapshot
└── index/        → Correspondance dossier → liste de snapshots
```

Cette structure est utilisée par **tous les autres membres** pour stocker et retrouver les données.

---

### 4. Le Système de Logs — `log_event()`

J'ai créé une fonction de log utilisée dans tout le projet.

**Format standardisé :**
```
2026-04-30-14-23-45: zakaria: INFOS: SNAPSHOT_CREATED id=5 files=12
2026-04-30-14-25-10: zakaria: ERROR: ERROR_104: Espace disque insuffisant
```

**Fonctionnalités :**
- Horodatage automatique
- Nom d'utilisateur automatique
- 3 types : `INFOS`, `ERROR`, `WARNING`
- Affichage terminal + écriture fichier en même temps
- Fallback automatique si `/var/log/` inaccessible

---

### 5. La Gestion des Erreurs — `die()`

J'ai créé une fonction centrale pour gérer toutes les erreurs du projet.

**Quand une erreur survient, elle :**
1. Enregistre l'erreur dans les logs
2. Affiche un message clair à l'utilisateur
3. Affiche l'aide automatiquement
4. Quitte avec le bon code d'erreur

**Codes d'erreur définis :**

| Code | Signification |
|------|---------------|
| 100 | Option non reconnue |
| 101 | Paramètre manquant ou chemin invalide |
| 102 | Aucun snapshot trouvé *(utilisé par Sprint 3)* |
| 103 | Snapshot introuvable *(utilisé par Sprint 3)* |
| 104 | Espace disque insuffisant *(utilisé par Sprint 2)* |
| 105 | Permission refusée (sudo requis) |

---

### 6. La Validation du Dossier Cible — `validate_target_dir()`

Avant d'exécuter quoi que ce soit, je vérifie que le dossier fourni par l'utilisateur est valide :

```
✓ Le chemin est fourni ?
✓ Le chemin existe sur le disque ?
✓ C'est bien un dossier (pas un fichier) ?
```

---

### 7. Le Reset — `reset_snapfile()`

J'ai implémenté l'option `-r` qui réinitialise complètement SnapFile.

**Protections :**
- Nécessite `sudo` (sinon erreur 105)
- Demande confirmation explicite (taper "OUI")
- Supprime `~/.snapfile/` et `/var/log/snapfile/`

---

### 8. La Documentation et les Tests

- **7 fichiers de documentation** rédigés
- **12 tests automatisés** dans `tests/test_sprint1.sh`
- **Taux de réussite : 100%** (12/12 tests passés)

---

## 🏗️ Architecture Modulaire

J'ai découpé le code en **5 modules séparés** pour que chaque membre puisse travailler indépendamment :

```
src/
├── snapfile.sh          → Point d'entrée principal
└── lib/
    ├── utils.sh         → usage(), log_event(), die()
    ├── options.sh       → parse_options()
    ├── init.sh          → init_repository(), validate_target_dir()
    ├── reset.sh         → check_sudo(), reset_snapfile()
    └── commands.sh      → cmd_save(), cmd_log(), cmd_restore()
                           (squelette prêt pour les autres membres)
```

---

## 🔗 Ce que j'ai préparé pour les autres membres

### Pour le Membre 2 (Sprint 2 — Sauvegarde)
- Variables `$TARGET_DIR`, `$OPT_FORK`, `$OPT_THREAD` déjà disponibles
- Dossiers `$OBJECTS_DIR`, `$SNAPSHOTS_DIR`, `$INDEX_DIR` déjà créés
- Squelette de `cmd_save()` prêt à remplir

### Pour le Membre 3 (Sprint 3 — Restauration)
- Codes d'erreur 102 et 103 déjà définis
- Variable `$OPT_SUBSHELL` déjà disponible
- Squelettes de `cmd_log()` et `cmd_restore()` prêts

### Pour le Membre 4 (Sprint 4 — Tests)
- Suite de tests `test_sprint1.sh` comme modèle
- Tous les codes d'erreur documentés
- Logs structurés pour faciliter le débogage

---

## 📊 Métriques

| Indicateur | Valeur |
|------------|--------|
| Lignes de code | ~350 lignes |
| Fonctions créées | 7 fonctions |
| Options implémentées | 6 options |
| Codes d'erreur | 6 codes (100-105) |
| Tests automatisés | 12 tests |
| Taux de réussite | 100% |
| Fichiers de documentation | 7 fichiers |

---

## ✅ Résumé en une phrase

> J'ai construit **la fondation complète du projet** : le squelette du script, le parseur d'options, le système de logs, la gestion des erreurs, la structure de stockage, et la documentation — tout ce dont les autres membres avaient besoin pour démarrer leurs sprints.

---

*Sprint 1 — SnapFile v1.0.0 — Théorie des Systèmes d'Exploitation*
