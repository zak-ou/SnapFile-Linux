# 📖 Guide Complet des Options — SnapFile

**Date :** 11 mai 2026  
**Version :** 1.1.0  
**Projet :** SnapFile — Système de Versionnement Léger

---

## 📋 Table des Matières

- [Vue d'Ensemble](#-vue-densemble)
- [Option -h (Help)](#-option--h-help)
- [Option -f (Fork)](#-option--f-fork)
- [Option -t (Thread)](#-option--t-thread)
- [Option -s (Subshell)](#-option--s-subshell)
- [Option -l (Log)](#-option--l-log)
- [Option -r (Reset)](#-option--r-reset)
- [Combinaisons d'Options](#-combinaisons-doptions)
- [Exemples Pratiques](#-exemples-pratiques)

---

## 🎯 Vue d'Ensemble

SnapFile dispose de **6 options** pour modifier le comportement des commandes.

| Option | Nom | Argument | Rôle |
|--------|-----|----------|------|
| `-h` | Help | Non | Affiche le manuel d'aide |
| `-f` | Fork | Non | Exécute en arrière-plan |
| `-t` | Thread | Non | Compression parallèle |
| `-s` | Subshell | Non | Prévisualisation dans /tmp/ |
| `-l <chemin>` | Log | Oui | Logs personnalisés |
| `-r` | Reset | Non | Réinitialisation complète |

---

## 📚 Option `-h` (Help)

### **Rôle**
Affiche le manuel d'aide complet avec toutes les commandes, options, exemples et codes d'erreur.

### **Syntaxe**
```bash
./src/snapfile.sh -h
```

### **Utilisation**
```bash
# Afficher l'aide
./src/snapfile.sh -h

# Pas besoin d'autres arguments
```

### **Sortie**
```
╔══════════════════════════════════════════════════════════╗
║                    SNAPFILE v1.0.0                       ║
║    Système de versionnement léger pour fichiers locaux  ║
╚══════════════════════════════════════════════════════════╝

SYNOPSIS
    snapfile [OPTIONS] <commande> <dossier>

DESCRIPTION
    SnapFile est un outil de versionnement transparent...

COMMANDES
    init                        Initialise le dépôt
    save <dossier>              Crée un snapshot
    log <dossier>               Affiche l'historique
    restore <dossier> --id N    Restaure un snapshot

OPTIONS
    -h    Affiche ce manuel
    -f    Fork (arrière-plan)
    -t    Thread (parallèle)
    -s    Subshell (prévisualisation)
    -l    Logs personnalisés
    -r    Reset complet

EXEMPLES
    snapfile init
    snapfile save mon_projet/
    snapfile -f save mon_projet/
    ...
```

### **Implémentation**
- **Fichier :** `src/lib/options.sh` ligne 24-27
- **Fonction appelée :** `usage()` dans `src/lib/utils.sh`

### **Compatible avec**
- Aucune commande (utilisée seule)

---

## 🍴 Option `-f` (Fork)

### **Rôle**
Lance la sauvegarde en **arrière-plan** pour libérer le terminal immédiatement.

### **Syntaxe**
```bash
./src/snapfile.sh -f save <dossier>
```

### **Comment ça fonctionne**
1. Crée un **processus fils** (fork)
2. Le processus fils traite les fichiers par **lots de 5**
3. Le terminal est **libéré immédiatement**
4. Vous pouvez continuer à travailler pendant la sauvegarde

### **Utilisation**
```bash
# Sauvegarde en arrière-plan
./src/snapfile.sh -f save /tmp/mon_projet

# Sortie immédiate :
🚀 Mode FORK (C-Worker par lots de 5)
[INFO] Exécution en arrière-plan lancée (PID: 12345)

# Vous pouvez continuer à travailler
ls
cd autre_dossier/
# La sauvegarde continue en arrière-plan
```

### **Implémentation**
- **Parser :** `src/lib/options.sh` ligne 28-30
- **Traitement :** `src/lib/commands.sh` ligne 138-155
- **Worker C :** `src/lib/fork_worker.c`

### **Détails Techniques**
```c
// fork_worker.c
#define BATCH_SIZE 5  // 5 fichiers par lot

void execute_batch(char *files[], int count) {
    pid_t pid = fork();  // Crée un nouveau processus
    if (pid == 0) {
        // Processus fils : traite les fichiers
        execvp("bash", args);
    }
}
```

### **Compatible avec**
- `save` uniquement
- Peut être combiné avec `-t` et `-l`

### **Quand l'utiliser**
- Gros projets (> 100 fichiers)
- Vous voulez continuer à travailler pendant la sauvegarde
- Sauvegardes automatiques en arrière-plan

---

## 🧵 Option `-t` (Thread)

### **Rôle**
Active la **compression parallèle** pour accélérer la sauvegarde (utilise plusieurs CPU).

### **Syntaxe**
```bash
./src/snapfile.sh -t save <dossier>
```

### **Comment ça fonctionne**
1. Crée **4 threads maximum** (MAX_THREADS=4)
2. Chaque thread traite **5 fichiers** (MAX_FICHIERS=5)
3. Les fichiers sont compressés **en parallèle**
4. Utilise plusieurs cœurs CPU → **3-5× plus rapide**

### **Utilisation**
```bash
# Compression parallèle
./src/snapfile.sh -t save /tmp/mon_projet

# Sortie :
🧵 Mode THREAD (C-Worker avec pthread)
✅ Snapshot terminé ! ID: 20260511142345 (50 fichiers)
```

### **Implémentation**
- **Parser :** `src/lib/options.sh` ligne 31-33
- **Traitement :** `src/lib/commands.sh` ligne 162-177
- **Worker C :** `src/lib/thread_worker.c`

### **Détails Techniques**
```c
// thread_worker.c
#define MAX_THREADS 4      // 4 threads maximum
#define MAX_FICHIERS 5     // 5 fichiers par thread

void *traiter_lot(void *arg) {
    // Chaque thread traite son lot de fichiers
    for (int i = 0; i < lot->count; i++) {
        // Traitement parallèle
    }
}
```

### **Compatible avec**
- `save` uniquement
- Peut être combiné avec `-f` et `-l`

### **Quand l'utiliser**
- Gros projets (> 50 fichiers)
- Vous voulez que la sauvegarde soit rapide
- Votre machine a plusieurs cœurs CPU

### **Performance**
```
Sans -t : 100 fichiers en 60 secondes
Avec -t : 100 fichiers en 15 secondes (4× plus rapide)
```

---

## 🔍 Option `-s` (Subshell)

### **Rôle**
Restaure dans `/tmp/` pour **prévisualiser** avant de restaurer pour de vrai.

### **Syntaxe**
```bash
./src/snapfile.sh -s restore <dossier> --id <ID>
```

### **Comment ça fonctionne**
1. Au lieu de restaurer dans le dossier original
2. Restaure dans `/tmp/snapfile_preview/`
3. Vous pouvez **vérifier** les fichiers
4. Si OK → restaurer pour de vrai sans `-s`

### **Utilisation**
```bash
# 1. Voir les snapshots disponibles
./src/snapfile.sh log /tmp/mon_projet

# 2. Prévisualiser le snapshot 3
./src/snapfile.sh -s restore /tmp/mon_projet --id 20260511142345

# Sortie :
Mode prévisualisation : restauration dans /tmp/snapfile_preview/mon_projet
Restauration terminée : 10 fichier(s) restauré(s)
Destination : /tmp/snapfile_preview/mon_projet

# 3. Vérifier les fichiers
ls /tmp/snapfile_preview/mon_projet/
cat /tmp/snapfile_preview/mon_projet/fichier1.txt

# 4. Si OK, restaurer pour de vrai
./src/snapfile.sh restore /tmp/mon_projet --id 20260511142345
```

### **Implémentation**
- **Parser :** `src/lib/options.sh` ligne 34-36
- **Traitement :** `src/lib/commands.sh` ligne 318-327

```bash
if [[ "$OPT_SUBSHELL" -eq 1 ]]; then
    dest_dir="/tmp/snapfile_preview/${dir_name}"
    echo "Mode prévisualisation : restauration dans $dest_dir"
else
    dest_dir="$TARGET_DIR"
    # Demande confirmation
fi
```

### **Compatible avec**
- `restore` uniquement
- Peut être combiné avec `-l`

### **Quand l'utiliser**
- Vous n'êtes pas sûr du contenu du snapshot
- Vous voulez vérifier avant d'écraser les fichiers actuels
- Restauration prudente (recommandé)

---

## 📝 Option `-l <chemin>` (Log)

### **Rôle**
Définit un **répertoire personnalisé** pour les logs au lieu de `/var/log/snapfile/`.

### **Syntaxe**
```bash
./src/snapfile.sh -l <chemin> <commande> <dossier>
```

### **Comment ça fonctionne**
1. Au lieu d'écrire dans `/var/log/snapfile/history.log`
2. Écrit dans `<chemin>/snapfile.log`
3. Utile pour organiser les logs par projet

### **Utilisation**
```bash
# Logs dans un dossier personnalisé
./src/snapfile.sh -l ~/mes_logs save /tmp/mon_projet

# Vérifier le log
cat ~/mes_logs/snapfile.log

# Sortie :
2026-05-11-14-23-45: zakaria: INFOS: COMMAND: save /tmp/mon_projet
2026-05-11-14-23-46: zakaria: INFOS: SNAPSHOT_CREATED id=20260511142345 files=10
```

### **Implémentation**
- **Parser :** `src/lib/options.sh` ligne 37-39
- **Utilisation :** Automatique via `$LOG_FILE` dans `log_event()`

```bash
# Parser
l)
    LOG_FILE="${OPTARG}/snapfile.log"
    ;;

# Utilisation dans log_event()
echo "$log_entry" | tee -a "$LOG_FILE"
```

### **Compatible avec**
- Toutes les commandes (`init`, `save`, `log`, `restore`)

### **Quand l'utiliser**
- Logs par projet
- Logs dans un dossier accessible sans sudo
- Organisation personnalisée des logs

### **Exemples**
```bash
# Logs par projet
./src/snapfile.sh -l ~/projet_A/logs save /tmp/projet_A
./src/snapfile.sh -l ~/projet_B/logs save /tmp/projet_B

# Logs dans le dossier courant
./src/snapfile.sh -l . save /tmp/mon_projet
# → ./snapfile.log
```

---

## 🗑️ Option `-r` (Reset)

### **Rôle**
Supprime **TOUT** (snapshots, objets, index, logs) et repart de zéro.

### **Syntaxe**
```bash
sudo ./src/snapfile.sh -r
```

### **Comment ça fonctionne**
1. Vérifie que vous êtes **root** (sudo)
2. Demande confirmation **"OUI"** (en majuscules)
3. Supprime `~/.snapfile/`
4. Supprime `/var/log/snapfile/`

### **Utilisation**
```bash
# Réinitialiser complètement
sudo ./src/snapfile.sh -r

# Sortie :
⚠️  ATTENTION : Cette opération va supprimer TOUS les snapshots !
   Dépôt à purger  : ~/.snapfile
   Logs à effacer  : /var/log/snapfile/

Êtes-vous sûr ? (tapez 'OUI' pour confirmer) : OUI

✓ Dépôt ~/.snapfile supprimé
✓ Logs /var/log/snapfile/ supprimés
✓ Réinitialisation terminée avec succès
```

### **Implémentation**
- **Parser :** `src/lib/options.sh` ligne 40-42
- **Traitement :** `src/snapfile.sh` ligne 70-72
- **Fonction :** `src/lib/reset.sh` ligne 16-50

```bash
# Vérification sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        die 105 "L'option -r nécessite sudo"
    fi
}

# Suppression
rm -rf "$SNAPFILE_DIR"
rm -rf "/var/log/snapfile"
```

### **Protections**
1. ✅ Nécessite `sudo` (erreur 105 sinon)
2. ✅ Demande confirmation "OUI" (annulable)
3. ✅ Log de l'opération avant suppression

### **Compatible avec**
- Aucune commande (utilisée seule)

### **Quand l'utiliser**
- Repartir de zéro
- Libérer de l'espace disque
- Désinstallation de SnapFile
- Tests et développement

### **⚠️ ATTENTION**
Cette opération est **irréversible** ! Tous les snapshots seront perdus.

---

## 🔗 Combinaisons d'Options

### **Combinaisons Valides**

| Combinaison | Résultat | Cas d'usage |
|-------------|----------|-------------|
| `-f -t` | Fork + Thread | Gros projet : arrière-plan + rapide |
| `-f -l ~/logs` | Fork + logs | Arrière-plan avec logs personnalisés |
| `-t -l ~/logs` | Thread + logs | Rapide avec logs personnalisés |
| `-f -t -l ~/logs` | Les trois | **OPTIMAL** pour gros projets |
| `-s -l ~/logs` | Subshell + logs | Prévisualisation avec logs |

### **Exemples de Combinaisons**

```bash
# Optimal pour gros projet
./src/snapfile.sh -f -t -l ~/logs save /tmp/gros_projet
# → Arrière-plan + Parallèle + Logs personnalisés

# Restauration prudente avec logs
./src/snapfile.sh -s -l ~/logs restore /tmp/projet --id 20260511142345
# → Prévisualisation + Logs personnalisés
```

---

## 💡 Exemples Pratiques

### **Scénario 1 : Petit Projet (< 50 fichiers)**

```bash
# Simple et direct
./src/snapfile.sh init
./src/snapfile.sh save /tmp/petit_projet
./src/snapfile.sh log /tmp/petit_projet
```

**Temps :** ~5 secondes  
**Options :** Aucune nécessaire

---

### **Scénario 2 : Projet Moyen (50-200 fichiers)**

```bash
# Avec thread pour accélérer
./src/snapfile.sh init
./src/snapfile.sh -t save /tmp/projet_moyen
```

**Temps :** ~10 secondes (au lieu de 30)  
**Options :** `-t` (compression parallèle)

---

### **Scénario 3 : Gros Projet (> 200 fichiers)**

```bash
# Optimal : fork + thread + logs
./src/snapfile.sh init
./src/snapfile.sh -f -t -l ~/logs save /tmp/gros_projet

# Terminal libéré immédiatement
# Suivre la progression :
tail -f ~/logs/snapfile.log
```

**Temps :** ~20 secondes (en arrière-plan)  
**Options :** `-f -t -l` (toutes les optimisations)

---

### **Scénario 4 : Restauration Prudente**

```bash
# 1. Voir les snapshots
./src/snapfile.sh log /tmp/mon_projet

# 2. Prévisualiser
./src/snapfile.sh -s restore /tmp/mon_projet --id 20260511142345

# 3. Vérifier
ls /tmp/snapfile_preview/mon_projet/

# 4. Restaurer pour de vrai
./src/snapfile.sh restore /tmp/mon_projet --id 20260511142345
```

**Options :** `-s` (prévisualisation)

---

### **Scénario 5 : Organisation par Projet**

```bash
# Projet A avec ses logs
./src/snapfile.sh -l ~/projet_A/logs save /tmp/projet_A

# Projet B avec ses logs
./src/snapfile.sh -l ~/projet_B/logs save /tmp/projet_B

# Chaque projet a ses propres logs séparés
```

**Options :** `-l` (logs personnalisés)

---

### **Scénario 6 : Nettoyage Complet**

```bash
# Supprimer tout et recommencer
sudo ./src/snapfile.sh -r
# Taper "OUI"

# Réinitialiser
./src/snapfile.sh init
```

**Options :** `-r` (reset)

---

## 📊 Tableau Récapitulatif

| Option | Argument | Commandes | Rôle | Fichier Implémentation |
|--------|----------|-----------|------|------------------------|
| `-h` | Non | Aucune | Aide | `options.sh` + `utils.sh` |
| `-f` | Non | `save` | Arrière-plan | `options.sh` + `commands.sh` + `fork_worker.c` |
| `-t` | Non | `save` | Parallèle | `options.sh` + `commands.sh` + `thread_worker.c` |
| `-s` | Non | `restore` | Prévisualisation | `options.sh` + `commands.sh` |
| `-l` | Oui | Toutes | Logs personnalisés | `options.sh` + `utils.sh` |
| `-r` | Non | Aucune | Reset | `options.sh` + `reset.sh` |

---

## 🎯 Résumé

**6 options disponibles :**
- `-h` → Aide
- `-f` → Arrière-plan
- `-t` → Parallèle
- `-s` → Prévisualisation
- `-l` → Logs personnalisés
- `-r` → Reset complet

**Combinaison optimale pour gros projets :**
```bash
./src/snapfile.sh -f -t -l ~/logs save /tmp/projet
```

---

## 📞 Support

Pour plus d'informations :
- Manuel complet : `./src/snapfile.sh -h`
- Compatibilité : `docs/zakaria/COMPATIBILITE_OPTIONS_COMMANDES.md`
- Workflow : `docs/zakaria/WORKFLOW_INIT.md`
- Vérification : `docs/zakaria/VERIFICATION_OPTIONS.md`

---

*Dernière mise à jour : 11 mai 2026*
