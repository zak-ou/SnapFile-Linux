# 📦 Livraison Sprint 1 - SnapFile

**Date :** 30 avril 2026  
**Membre :** Membre 1  
**Statut :** ✅ COMPLET ET VALIDÉ

---

## 📋 Résumé Exécutif

Le Sprint 1 est **100% terminé** et prêt pour le Sprint 2. Toutes les fonctionnalités demandées ont été implémentées et testées avec succès.

---

## ✅ Checklist de Livraison

### Fonctionnalités Implémentées

- [x] **Fichier principal `snapfile.sh`** avec shebang et structure modulaire
- [x] **Fonction `usage()`** — Option `-h` avec manuel complet
- [x] **Parseur d'options** avec `getopts` (6 options : -h, -f, -t, -s, -l, -r)
- [x] **Validation du paramètre obligatoire** (chemin du dossier)
- [x] **Structure du dépôt** `~/.snapfile/` (objects/, snapshots/, index/)
- [x] **Système de log** avec format standardisé
- [x] **Gestion unifiée des erreurs** (codes 100-105)
- [x] **Option `-r` (reset)** avec protection sudo

### Documentation

- [x] **README_sprint1.md** — Documentation technique complète (47 pages)
- [x] **GUIDE_DEMARRAGE.md** — Guide de démarrage rapide
- [x] **LIVRAISON_SPRINT1.md** — Ce document

### Tests

- [x] **test_sprint1.sh** — Suite de 12 tests automatisés
- [x] Tous les tests passent avec succès
- [x] Tests manuels effectués et validés

---

## 📁 Fichiers Livrés

```
SnapFile-linux/
├── snapfile.sh                  # Script principal (350 lignes)
├── README_sprint1.md            # Documentation technique complète
├── GUIDE_DEMARRAGE.md           # Guide de démarrage rapide
├── LIVRAISON_SPRINT1.md         # Ce document
├── test_sprint1.sh              # Suite de tests (12 tests)
└── test_folder/                 # Dossier de test (exemple)
    └── fichier1.txt
```

---

## 🧪 Résultats des Tests

### Tests Automatisés (test_sprint1.sh)

| # | Test | Résultat |
|---|------|----------|
| 1 | Option -h affiche le manuel | ✅ PASS |
| 2 | Option inconnue → Erreur 100 | ✅ PASS |
| 3 | Paramètre manquant → Erreur 101 | ✅ PASS |
| 4 | Chemin inexistant → Erreur 101 | ✅ PASS |
| 5 | Initialisation du dépôt ~/.snapfile/ | ✅ PASS |
| 6 | Système de log fonctionnel | ✅ PASS |
| 7 | Option -l (log personnalisé) | ✅ PASS |
| 8 | Option -r sans sudo → Erreur 105 | ✅ PASS |
| 9 | Options -f, -t, -s reconnues | ✅ PASS |
| 10 | Commandes save, log, restore reconnues | ✅ PASS |
| 11 | Commande inconnue → Erreur 100 | ✅ PASS |
| 12 | Format du log conforme | ✅ PASS |

**Résultat : 12/12 tests réussis (100%)**

### Tests Manuels

- ✅ `./snapfile.sh -h` → Manuel complet affiché
- ✅ `./snapfile.sh save test_folder/` → Dépôt créé, log enregistré
- ✅ `./snapfile.sh -z save test/` → Erreur 100 + aide
- ✅ `./snapfile.sh save` → Erreur 101 + aide
- ✅ `./snapfile.sh -r` → Erreur 105 (sans sudo)
- ✅ `sudo ./snapfile.sh -r` → Réinitialisation complète
- ✅ `./snapfile.sh -l ~/logs save test/` → Log personnalisé créé

---

## 🏗️ Architecture Technique

### Variables Globales

```bash
VERSION="1.0.0"
SNAPFILE_DIR="$HOME/.snapfile"
OBJECTS_DIR="$SNAPFILE_DIR/objects"
SNAPSHOTS_DIR="$SNAPFILE_DIR/snapshots"
INDEX_DIR="$SNAPFILE_DIR/index"
DEFAULT_LOG_FILE="/var/log/snapfile/history.log"
LOG_FILE="$DEFAULT_LOG_FILE"
OPT_FORK=0
OPT_THREAD=0
OPT_SUBSHELL=0
OPT_RESET=0
TARGET_DIR=""
```

### Fonctions Principales

| Fonction | Ligne | Description |
|----------|-------|-------------|
| `usage()` | 52 | Affiche le manuel complet |
| `log_event()` | 134 | Enregistre un événement dans le log |
| `die()` | 166 | Gestion unifiée des erreurs |
| `init_repository()` | 206 | Crée la structure ~/.snapfile/ |
| `validate_target_dir()` | 218 | Valide le chemin du dossier cible |
| `check_sudo()` | 236 | Vérifie les privilèges root |
| `reset_snapfile()` | 246 | Réinitialise complètement SnapFile |

### Flux d'Exécution

```
1. Parsing des options (getopts) → Lignes 264-295
2. Traitement de l'option -r si présente → Lignes 300-303
3. Validation du paramètre obligatoire → Lignes 308-314
4. Initialisation du dépôt → Ligne 319
5. Routage vers la commande (save/log/restore) → Lignes 324-343
6. Log de fin d'exécution → Ligne 348
```

---

## 🔗 Interface pour le Sprint 2

### Fonctions Disponibles

Le Membre 2 peut utiliser directement :

```bash
# Logger un événement
log_event "INFOS" "SNAPSHOT_CREATED id=5 files=12 size=45M"
log_event "ERROR" "ERROR_104: Espace disque insuffisant"

# Gérer une erreur fatale
die 104 "Espace disque insuffisant"

# Accéder aux variables globales
echo $SNAPFILE_DIR        # ~/.snapfile
echo $OBJECTS_DIR         # ~/.snapfile/objects
echo $SNAPSHOTS_DIR       # ~/.snapfile/snapshots
echo $INDEX_DIR           # ~/.snapfile/index
echo $TARGET_DIR          # Chemin du dossier à sauvegarder

# Vérifier les options activées
if [[ $OPT_FORK -eq 1 ]]; then
    # Lancer en arrière-plan avec & et disown
fi

if [[ $OPT_THREAD -eq 1 ]]; then
    # Compression parallèle avec wait
fi
```

### Point d'Entrée pour la Commande `save`

**Fichier :** `snapfile.sh`  
**Ligne :** 318

```bash
case "$COMMAND" in
    save)
        log_event "INFOS" "COMMAND: save $TARGET_DIR (fork=$OPT_FORK, thread=$OPT_THREAD)"
        
        # ============================================================
        # TODO SPRINT 2 : IMPLÉMENTER LA SAUVEGARDE ICI
        # ============================================================
        # 1. Parcours récursif avec find
        # 2. Calcul SHA-256 avec sha256sum
        # 3. Déduplication (liens symboliques si hash existe)
        # 4. Compression avec tar et gzip
        # 5. Création des métadonnées du snapshot
        # 6. Vérification espace disque (erreur 104 si insuffisant)
        # 7. Log de succès
        # ============================================================
        
        echo "🔄 Commande 'save' détectée pour : $TARGET_DIR"
        echo "⚠️  Fonctionnalité à implémenter dans le Sprint 2 (Membre 2)"
        ;;
```

---

## 📊 Métriques du Sprint 1

- **Lignes de code :** 350 lignes (snapfile.sh)
- **Fonctions créées :** 7 fonctions utilitaires
- **Options implémentées :** 6 options (-h, -f, -t, -s, -l, -r)
- **Codes d'erreur :** 6 codes (100-105)
- **Tests automatisés :** 12 tests
- **Taux de réussite :** 100%
- **Documentation :** 3 fichiers (README, GUIDE, LIVRAISON)

---

## 🎯 Prochaines Étapes (Sprint 2)

Le Membre 2 doit maintenant implémenter :

### Tâches Prioritaires

1. **Commande `save`** avec parcours récursif (`find`)
2. **Calcul SHA-256** de chaque fichier (`sha256sum`)
3. **Déduplication** par hash (liens symboliques avec `ln -s`)
4. **Compression** avec `tar` et `gzip`
5. **Métadonnées** des snapshots (format JSON ou texte)
6. **Option `-f`** : fork avec `&` et `disown`
7. **Option `-t`** : compression parallèle avec `wait`
8. **Vérification espace disque** avec `df` (erreur 104)

### Format des Métadonnées (Suggestion)

```json
{
  "id": 1,
  "timestamp": "2026-04-30-23-47-18",
  "source_dir": "/home/user/mon_projet",
  "files_count": 12,
  "total_size": "45M",
  "files": [
    {
      "path": "fichier1.txt",
      "hash": "a1b2c3d4...",
      "size": "1024"
    }
  ]
}
```

---

## 📞 Contact et Support

**Membre 1** : Disponible pour toute question sur le Sprint 1

**Documentation :**
- Technique complète : `README_sprint1.md`
- Démarrage rapide : `GUIDE_DEMARRAGE.md`
- Tests : `test_sprint1.sh`

---

## ✅ Validation Finale

- [x] Toutes les fonctionnalités du Sprint 1 sont implémentées
- [x] Tous les tests passent avec succès (12/12)
- [x] La documentation est complète et claire
- [x] Le code est commenté et structuré
- [x] L'interface pour le Sprint 2 est bien définie
- [x] Les conventions de code sont respectées

---

## 🎉 Conclusion

Le Sprint 1 est **100% terminé et validé**. Le Membre 2 peut commencer le Sprint 2 en toute confiance avec une base solide et bien documentée.

**Statut : ✅ PRÊT POUR LIVRAISON**

---

*Document généré le 30 avril 2026*  
*Projet SnapFile - Théorie des Systèmes d'Exploitation*
