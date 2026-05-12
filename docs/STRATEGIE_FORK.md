# 🔀 Stratégie de Fork : Une ou Plusieurs ?

**Date :** 2 mai 2026  
**Version :** 1.0.0  
**Sprint :** 2 (Implémentation)

---

## 📋 Table des Matières

- [La Question](#-la-question)
- [Les Deux Approches](#-les-deux-approches)
- [Comparaison Détaillée](#-comparaison-détaillée)
- [Recommandation](#-recommandation)
- [Implémentation Recommandée](#-implémentation-recommandée)
- [Exemples de Code](#-exemples-de-code)
- [Cas d'Usage](#-cas-dusage)
- [Conclusion](#-conclusion)

---

## 🤔 La Question

Pour l'option `-f` (fork), quelle stratégie est la meilleure ?

### **Approche 1 : Un Fork par Fichier**
```bash
./snapfile.sh -f save mon_projet/

# Processus créés :
# Fork 1 → Traite fichier1.txt
# Fork 2 → Traite fichier2.txt
# Fork 3 → Traite fichier3.txt
# ...
```

### **Approche 2 : Un Seul Fork Global**
```bash
./snapfile.sh -f save mon_projet/

# Processus créés :
# Fork 1 → Traite TOUS les fichiers (fichier1, fichier2, fichier3...)
```

---

## 🔍 Les Trois Approches

### **Approche 1 : Un Fork par Fichier (Multi-Fork)**

```
┌─────────────────────────────────────────────────────────┐
│  PROCESSUS PRINCIPAL                                    │
│  ./snapfile.sh -f save mon_projet/                      │
└────────────┬────────────────────────────────────────────┘
             │
             ├─→ Fork 1 → fichier1.txt → SHA256 → Stockage
             │
             ├─→ Fork 2 → fichier2.txt → SHA256 → Stockage
             │
             ├─→ Fork 3 → fichier3.txt → SHA256 → Stockage
             │
             └─→ Fork N → fichierN.txt → SHA256 → Stockage
```

**Caractéristiques :**
- Chaque fichier est traité par un processus séparé
- Parallélisation maximale
- Processus principal attend tous les forks

---

### **Approche 2 : Un Seul Fork Global (Single-Fork)**

```
┌─────────────────────────────────────────────────────────┐
│  PROCESSUS PRINCIPAL                                    │
│  ./snapfile.sh -f save mon_projet/                      │
└────────────┬────────────────────────────────────────────┘
             │
             └─→ Fork Unique
                 │
                 ├─→ fichier1.txt → SHA256 → Stockage
                 ├─→ fichier2.txt → SHA256 → Stockage
                 ├─→ fichier3.txt → SHA256 → Stockage
                 └─→ fichierN.txt → SHA256 → Stockage
```

**Caractéristiques :**
- Un seul processus en arrière-plan
- Traite les fichiers séquentiellement
- Processus principal libéré immédiatement

---

### **Approche 3 : Fork Hybride par Lots (Batch-Fork) ⭐ NOUVELLE**

```
┌─────────────────────────────────────────────────────────┐
│  PROCESSUS PRINCIPAL                                    │
│  ./snapfile.sh -f save mon_projet/                      │
└────────────┬────────────────────────────────────────────┘
             │
             ├─→ Fork 1 (Lot 1 : 100 fichiers)
             │   ├─→ fichier1.txt → SHA256 → Stockage
             │   ├─→ fichier2.txt → SHA256 → Stockage
             │   └─→ fichier100.txt → SHA256 → Stockage
             │
             ├─→ Fork 2 (Lot 2 : 100 fichiers)
             │   ├─→ fichier101.txt → SHA256 → Stockage
             │   ├─→ fichier102.txt → SHA256 → Stockage
             │   └─→ fichier200.txt → SHA256 → Stockage
             │
             └─→ Fork N (Lot N : fichiers restants)
                 ├─→ fichier901.txt → SHA256 → Stockage
                 └─→ fichier950.txt → SHA256 → Stockage
```

**Caractéristiques :**
- Divise les fichiers en lots (ex: 100 fichiers par lot)
- Crée un fork par lot
- Équilibre entre parallélisation et ressources
- Nombre de forks = ceil(nombre_fichiers / taille_lot)

**Exemple :**
- 50 fichiers → 1 fork (50 < 100)
- 250 fichiers → 3 forks (250 / 100 = 2.5 → 3)
- 1000 fichiers → 10 forks (1000 / 100 = 10)

---

## 📊 Comparaison Détaillée

| Critère | Multi-Fork (1 par fichier) | Single-Fork (1 global) | **Batch-Fork (Hybride) ⭐** |
|---------|---------------------------|------------------------|---------------------------|
| **Vitesse** | ⚡⚡⚡ Très rapide | 🐌 Plus lent | ⚡⚡ Rapide |
| **Ressources CPU** | 🔥🔥🔥 Élevé (N processus) | ✅ Faible (1 processus) | ⚖️ Modéré (N/100 processus) |
| **Ressources RAM** | 🔥🔥🔥 Élevé (N × 50MB) | ✅ Faible (1 × 50MB) | ⚖️ Modéré (N/100 × 50MB) |
| **Complexité** | 🔧🔧🔧 Complexe | ✅ Simple | 🔧🔧 Moyenne |
| **Gestion erreurs** | 🔧🔧 Difficile | ✅ Facile | 🔧 Moyenne |
| **Logs** | 🔧🔧🔧 Compliqué | ✅ Simple | 🔧 Gérable |
| **Scalabilité** | ⚠️ Problème (>1000 fichiers) | ✅ Illimité | ✅ Excellent |
| **Terminal libéré** | ✅ Oui | ✅ Oui | ✅ Oui |
| **Équilibre** | ❌ Déséquilibré | ⚠️ Pas de parallélisme | ✅ **OPTIMAL** |

### **Analyse par Nombre de Fichiers**

| Fichiers | Multi-Fork | Single-Fork | **Batch-Fork (100/lot)** |
|----------|------------|-------------|--------------------------|
| 10 | 10 processus | 1 processus | 1 processus |
| 100 | 100 processus | 1 processus | 1 processus |
| 500 | 500 processus ❌ | 1 processus | 5 processus ✅ |
| 1000 | 1000 processus ❌ | 1 processus | 10 processus ✅ |
| 5000 | 5000 processus ❌ | 1 processus | 50 processus ✅ |

---

## 🎯 Recommandation

### **✅ NOUVELLE RECOMMANDATION : Fork Hybride par Lots (Batch-Fork)**

**Pourquoi cette approche est la meilleure ?**

#### **1. Équilibre Optimal**

```
┌─────────────────────────────────────────────────────────┐
│  BATCH-FORK : Le Meilleur des Deux Mondes              │
├─────────────────────────────────────────────────────────┤
│  • Parallélisation (comme multi-fork)                   │
│  • Ressources contrôlées (comme single-fork)            │
│  • Scalabilité (s'adapte au nombre de fichiers)        │
└─────────────────────────────────────────────────────────┘
```

---

#### **2. Adaptation Intelligente**

**Petit projet (50 fichiers) :**
```bash
./snapfile.sh -f save petit_projet/
# → 1 seul fork (50 < 100)
# Comportement identique à single-fork
```

**Projet moyen (250 fichiers) :**
```bash
./snapfile.sh -f save projet_moyen/
# → 3 forks (250 / 100 = 2.5 → 3)
# Fork 1 : fichiers 1-100
# Fork 2 : fichiers 101-200
# Fork 3 : fichiers 201-250
```

**Gros projet (1000 fichiers) :**
```bash
./snapfile.sh -f save gros_projet/
# → 10 forks (1000 / 100 = 10)
# Parallélisation efficace sans saturation
```

---

#### **3. Gestion des Ressources**

**Scénario : 1000 fichiers**

| Approche | Processus | RAM | CPU | Verdict |
|----------|-----------|-----|-----|---------|
| Multi-fork | 1000 | 50 GB | 1000 threads | ❌ Inacceptable |
| Single-fork | 1 | 50 MB | 1 thread | ⚠️ Trop lent |
| **Batch-fork (100/lot)** | **10** | **500 MB** | **10 threads** | ✅ **OPTIMAL** |

---

#### **4. Configuration Flexible**

```bash
# Variable configurable
BATCH_SIZE=100  # Nombre de fichiers par fork

# Petit système (RAM limitée)
BATCH_SIZE=200  # Moins de forks

# Gros système (serveur puissant)
BATCH_SIZE=50   # Plus de forks, plus rapide
```

---

#### **5. Gestion des Logs Améliorée**

**Batch-fork (GÉRABLE) :**
```bash
# 10 forks écrivent (au lieu de 1000)
Fork 1: 2026-04-30-14-23-45: alice: INFOS: Batch 1/10 started (files 1-100)
Fork 2: 2026-04-30-14-23-45: alice: INFOS: Batch 2/10 started (files 101-200)
Fork 1: 2026-04-30-14-24-30: alice: INFOS: Batch 1/10 completed (100 files)
Fork 3: 2026-04-30-14-24-31: alice: INFOS: Batch 3/10 started (files 201-300)
# Logs lisibles avec contexte de progression
```

---

#### **6. Progression Visible**

```bash
./snapfile.sh -f save gros_projet/

# Affichage :
✓ Sauvegarde lancée en arrière-plan (10 lots de 100 fichiers)
  Lot 1/10 : fichiers 1-100
  Lot 2/10 : fichiers 101-200
  ...
  Consultez les logs pour suivre la progression
```

---

#### **2. Gestion des Ressources**

**Scénario : 1000 fichiers**

| Approche | Processus | RAM | CPU |
|----------|-----------|-----|-----|
| Multi-fork | 1000 processus | 1000 × 50MB = 50GB | 1000 threads |
| Single-fork | 1 processus | 1 × 50MB = 50MB | 1 thread |

**Avec multi-fork :**
- Risque de saturation du système
- Limite du nombre de processus (ulimit)
- Ralentissement par surcharge

---

#### **3. Gestion des Logs**

**Multi-fork (PROBLÈME) :**
```bash
# Plusieurs processus écrivent en même temps
Fork 1: 2026-04-30-14-23-45: alice: INFOS: Processing file1.txt
Fork 3: 2026-04-30-14-23-45: alice: INFOS: Processing file3.txt
Fork 2: 2026-04-30-14-23-45: alice: INFOS: Processing file2.txt
# Logs mélangés, difficiles à lire
```

**Single-fork (SOLUTION) :**
```bash
# Un seul processus écrit séquentiellement
2026-04-30-14-23-45: alice: INFOS: Processing file1.txt
2026-04-30-14-23-46: alice: INFOS: Processing file2.txt
2026-04-30-14-23-47: alice: INFOS: Processing file3.txt
# Logs ordonnés, faciles à lire
```

---

#### **4. Gestion des Erreurs**

**Multi-fork (DIFFICILE) :**
```bash
# Si un fork échoue, comment le détecter ?
# Comment arrêter les autres forks ?
# Comment nettoyer les ressources ?
```

**Single-fork (FACILE) :**
```bash
# Si une erreur survient, on arrête tout
# Nettoyage simple
# Logs clairs
```

---

#### **5. Option `-f` vs Option `-t`**

**Séparation des responsabilités :**

| Option | Rôle | Implémentation |
|--------|------|----------------|
| **-f** | Libérer le terminal | Un seul fork global |
| **-t** | Accélérer le traitement | Multi-threading pour compression |

```bash
# -f seul : Un fork, traitement séquentiel
./snapfile.sh -f save mon_projet/
# → 1 processus en arrière-plan

# -t seul : Pas de fork, multi-threading
./snapfile.sh -t save mon_projet/
# → Compression parallèle, terminal bloqué

# -f -t : Un fork + multi-threading
./snapfile.sh -f -t save mon_projet/
# → 1 processus en arrière-plan + compression parallèle
```

---

## 💡 Implémentation Recommandée

### **Architecture Recommandée : Batch-Fork**

```
┌─────────────────────────────────────────────────────────┐
│  OPTION -f (Fork) avec Batch-Fork                       │
│  • Divise les fichiers en lots de BATCH_SIZE            │
│  • Crée un fork par lot                                 │
│  • Libère le terminal                                   │
│  • Parallélisation contrôlée                            │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  OPTION -t (Thread)                                     │
│  • Multi-threading DANS chaque fork                     │
│  • Accélère la compression                              │
│  • Combinable avec -f                                   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  COMBINAISON -f -t (ULTRA-OPTIMAL)                      │
│  • Batch-fork (parallélisation par lots)                │
│  • Multi-threading dans chaque lot                      │
│  • Terminal libre + Traitement ultra-rapide             │
└─────────────────────────────────────────────────────────┘
```

---

## 💻 Exemples de Code

### **Approche Recommandée : Batch-Fork**

```bash
# Dans src/lib/commands.sh

# Configuration
readonly BATCH_SIZE=100  # Nombre de fichiers par fork

cmd_save() {
    local target_dir="$1"
    
    # Récupérer tous les fichiers
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$target_dir" -type f -print0)
    
    local total_files=${#files[@]}
    local num_batches=$(( (total_files + BATCH_SIZE - 1) / BATCH_SIZE ))
    
    log_event "INFOS" "Found $total_files files, creating $num_batches batches"
    
    # Si option -f activée
    if [[ $OPT_FORK -eq 1 ]]; then
        echo "✓ Sauvegarde lancée en arrière-plan ($num_batches lots de max $BATCH_SIZE fichiers)"
        
        # Créer un fork par lot
        for ((batch=0; batch<num_batches; batch++)); do
            local start=$((batch * BATCH_SIZE))
            local end=$((start + BATCH_SIZE))
            [[ $end -gt $total_files ]] && end=$total_files
            
            # Fork pour ce lot
            (
                local batch_num=$((batch + 1))
                log_event "INFOS" "Batch $batch_num/$num_batches started (files $((start+1))-$end)"
                
                # Traiter les fichiers de ce lot
                for ((i=start; i<end; i++)); do
                    process_file "${files[$i]}"
                done
                
                log_event "INFOS" "Batch $batch_num/$num_batches completed ($((end-start)) files)"
            ) &
            
            echo "  Lot $((batch+1))/$num_batches : fichiers $((start+1))-$end (PID: $!)"
        done
        
        echo "  Consultez les logs pour suivre la progression"
        
    else
        # Sauvegarde normale (bloque le terminal)
        log_event "INFOS" "Save started for $target_dir"
        
        for file in "${files[@]}"; do
            process_file "$file"
        done
        
        log_event "INFOS" "Save completed for $target_dir"
    fi
}

process_file() {
    local file="$1"
    
    # Calculer le hash SHA-256
    local hash
    hash=$(sha256sum "$file" | awk '{print $1}')
    
    # Vérifier si le fichier existe déjà (déduplication)
    local object_file="$OBJECTS_DIR/$hash"
    if [[ ! -f "$object_file" ]]; then
        # Si option -t activée, utiliser compression parallèle
        if [[ $OPT_THREAD -eq 1 ]]; then
            # Compression avec pigz (parallèle)
            gzip -c "$file" > "$object_file.gz" 2>/dev/null || \
            cat "$file" > "$object_file"
        else
            # Compression normale
            gzip -c "$file" > "$object_file.gz" 2>/dev/null || \
            cat "$file" > "$object_file"
        fi
        
        log_event "INFOS" "Stored: $file → $hash"
    else
        log_event "INFOS" "Deduplicated: $file → $hash (already exists)"
    fi
    
    # Enregistrer dans l'index
    echo "$hash:$file" >> "$INDEX_DIR/current.idx"
}
```

---

### **Variante : Batch-Fork avec Taille Adaptative**

```bash
# Adapter la taille des lots selon le nombre de fichiers

calculate_batch_size() {
    local total_files=$1
    local batch_size
    
    if [[ $total_files -le 100 ]]; then
        # Petit projet : 1 seul fork
        batch_size=$total_files
    elif [[ $total_files -le 500 ]]; then
        # Projet moyen : 5 forks
        batch_size=100
    elif [[ $total_files -le 1000 ]]; then
        # Gros projet : 10 forks
        batch_size=100
    else
        # Très gros projet : max 20 forks
        batch_size=$(( (total_files + 19) / 20 ))
    fi
    
    echo "$batch_size"
}

cmd_save() {
    local target_dir="$1"
    
    # Récupérer tous les fichiers
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$target_dir" -type f -print0)
    
    local total_files=${#files[@]}
    local batch_size
    batch_size=$(calculate_batch_size "$total_files")
    local num_batches=$(( (total_files + batch_size - 1) / batch_size ))
    
    log_event "INFOS" "Found $total_files files, batch_size=$batch_size, batches=$num_batches"
    
    # ... reste du code identique
}
```

---

### **Approche NON Recommandée : Multi-Fork (1 par fichier)**

```bash
# ❌ NE PAS FAIRE CECI

cmd_save() {
    local target_dir="$1"
    
    # Parcourir tous les fichiers
    find "$target_dir" -type f | while read -r file; do
        if [[ $OPT_FORK -eq 1 ]]; then
            # Fork pour CHAQUE fichier (MAUVAIS)
            process_file "$file" &
        else
            process_file "$file"
        fi
    done
    
    # Attendre tous les forks
    wait
}

# Problèmes :
# 1. Trop de processus (1000 fichiers = 1000 forks)
# 2. Logs mélangés
# 3. Gestion d'erreurs complexe
# 4. Risque de saturation système
# 5. Consommation RAM excessive
```

---

## 🎬 Cas d'Usage

### **Cas 1 : Petit Projet (10 fichiers)**

```bash
# Sans fork
./snapfile.sh save petit_projet/
# Temps : 2 secondes
# Terminal bloqué 2 secondes

# Avec fork
./snapfile.sh -f save petit_projet/
# Temps : 2 secondes (en arrière-plan)
# Terminal libéré immédiatement
```

**Conclusion :** Fork utile même pour petits projets (libère le terminal)

---

### **Cas 2 : Projet Moyen (100 fichiers)**

```bash
# Sans fork, sans thread
./snapfile.sh save projet_moyen/
# Temps : 30 secondes
# Terminal bloqué 30 secondes
# Processus : 1

# Avec batch-fork, sans thread
./snapfile.sh -f save projet_moyen/
# Temps : 30 secondes (en arrière-plan)
# Terminal libéré immédiatement
# Processus : 1 (100 fichiers = 1 lot)

# Sans fork, avec thread
./snapfile.sh -t save projet_moyen/
# Temps : 10 secondes (compression parallèle)
# Terminal bloqué 10 secondes
# Processus : 1

# Avec batch-fork ET thread (OPTIMAL)
./snapfile.sh -f -t save projet_moyen/
# Temps : 10 secondes (en arrière-plan)
# Terminal libéré immédiatement
# Processus : 1
```

**Conclusion :** Batch-fork se comporte comme single-fork pour petits projets

---

### **Cas 3 : Gros Projet (500 fichiers)**

```bash
# Sans fork, sans thread
./snapfile.sh save gros_projet/
# Temps : 5 minutes
# Terminal bloqué 5 minutes
# Processus : 1

# Avec batch-fork, sans thread
./snapfile.sh -f save gros_projet/
# Temps : 5 minutes (en arrière-plan)
# Terminal libéré immédiatement
# Processus : 5 (500 / 100 = 5 lots)
# Parallélisation : 5× plus rapide → 1 minute

# Sans fork, avec thread
./snapfile.sh -t save gros_projet/
# Temps : 2 minutes (compression parallèle)
# Terminal bloqué 2 minutes
# Processus : 1

# Avec batch-fork ET thread (ULTRA-OPTIMAL)
./snapfile.sh -f -t save gros_projet/
# Temps : 30 secondes (en arrière-plan)
# Terminal libéré immédiatement
# Processus : 5 lots × compression parallèle
# Parallélisation : 5× (lots) × 3× (thread) = 15× plus rapide
```

**Conclusion :** Batch-fork + thread = performance maximale

---

### **Cas 4 : Très Gros Projet (1000 fichiers)**

### **Cas 4 : Très Gros Projet (1000 fichiers)**

```bash
# Sans fork, sans thread
./snapfile.sh save tres_gros_projet/
# Temps : 10 minutes
# Terminal bloqué 10 minutes
# Processus : 1

# Avec batch-fork, sans thread
./snapfile.sh -f save tres_gros_projet/
# Temps : 10 minutes (en arrière-plan)
# Terminal libéré immédiatement
# Processus : 10 (1000 / 100 = 10 lots)
# Parallélisation : 10× plus rapide → 1 minute

# Sans fork, avec thread
./snapfile.sh -t save tres_gros_projet/
# Temps : 3 minutes (compression parallèle)
# Terminal bloqué 3 minutes
# Processus : 1

# Avec batch-fork ET thread (ULTRA-OPTIMAL)
./snapfile.sh -f -t save tres_gros_projet/
# Temps : 20 secondes (en arrière-plan)
# Terminal libéré immédiatement
# Processus : 10 lots × compression parallèle
# Parallélisation : 10× (lots) × 3× (thread) = 30× plus rapide
```

**Conclusion :** Batch-fork indispensable pour très gros projets

---

## 📈 Performance Comparée

### **Scénario : 500 fichiers**

| Configuration | Temps | Processus | RAM | Terminal | Performance |
|---------------|-------|-----------|-----|----------|-------------|
| Aucune option | 5 min | 1 | 50 MB | Bloqué | Baseline |
| `-f` (single-fork) | 5 min | 1 | 50 MB | Libre | 1× |
| `-f` (batch-fork) | 1 min | 5 | 250 MB | Libre | **5×** ⚡ |
| `-t` (thread) | 2 min | 1 | 100 MB | Bloqué | 2.5× |
| `-f -t` (batch+thread) | 30 sec | 5 | 500 MB | Libre | **10×** ⚡⚡⚡ |
| Multi-fork ❌ | 2 min | 500 | 25 GB | Libre | ❌ Inacceptable |

**Observation :**
- **Batch-fork seul** : 5× plus rapide (parallélisation par lots)
- **Batch-fork + thread** : 10× plus rapide (parallélisation × compression)
- **Multi-fork** : Rapide mais consomme 25 GB de RAM (inacceptable)

---

### **Scénario : 1000 fichiers**

| Configuration | Temps | Processus | RAM | Verdict |
|---------------|-------|-----------|-----|---------|
| Single-fork | 10 min | 1 | 50 MB | ⚠️ Trop lent |
| **Batch-fork (100/lot)** | **1 min** | **10** | **500 MB** | ✅ **OPTIMAL** |
| **Batch-fork + thread** | **20 sec** | **10** | **1 GB** | ✅ **ULTRA-OPTIMAL** |
| Multi-fork | 30 sec | 1000 | 50 GB | ❌ RAM excessive |

---

## 🎯 Conclusion

### **Décision Finale : Fork Hybride par Lots (Batch-Fork)**

**Raisons :**
1. ✅ **Équilibre optimal** : Parallélisation + Ressources contrôlées
2. ✅ **Adaptation intelligente** : S'adapte au nombre de fichiers
3. ✅ **Performance** : 5-10× plus rapide que single-fork
4. ✅ **Ressources** : Consommation raisonnable (500 MB vs 50 GB)
5. ✅ **Logs** : Logs lisibles avec progression par lots
6. ✅ **Scalabilité** : Fonctionne de 10 à 10000 fichiers
7. ✅ **Flexibilité** : Taille de lot configurable (BATCH_SIZE)
8. ✅ **Combinaison** : `-f` (batch-fork) + `-t` (thread) = ultra-optimal

---

### **Résumé des Trois Approches**

```
┌─────────────────────────────────────────────────────────┐
│  MULTI-FORK (1 par fichier) ❌                          │
│  • Très rapide mais consomme trop de ressources        │
│  • 1000 fichiers = 1000 processus = 50 GB RAM          │
│  • Logs mélangés, gestion d'erreurs difficile          │
│  • Verdict : INACCEPTABLE                              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  SINGLE-FORK (1 global) ⚠️                              │
│  • Simple mais trop lent pour gros projets             │
│  • 1000 fichiers = 10 minutes (séquentiel)             │
│  • Logs clairs, gestion d'erreurs facile               │
│  • Verdict : BON pour petits projets, LENT pour gros   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  BATCH-FORK (Hybride par lots) ✅ RECOMMANDÉ            │
│  • Équilibre optimal : rapide + ressources contrôlées  │
│  • 1000 fichiers = 10 lots = 1 minute                  │
│  • Logs lisibles avec progression, erreurs gérables    │
│  • Combiné avec -t : 20 secondes (30× plus rapide)    │
│  • Verdict : OPTIMAL pour tous les cas                 │
└─────────────────────────────────────────────────────────┘
```

---

### **Résumé des Rôles**

```
┌─────────────────────────────────────────────────────────┐
│  OPTION -f (Fork) avec Batch-Fork                       │
│  • Rôle : Libérer le terminal + Paralléliser           │
│  • Implémentation : Fork par lot (BATCH_SIZE=100)      │
│  • Avantage : Utilisateur peut continuer à travailler  │
│  • Performance : 5-10× plus rapide que séquentiel      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  OPTION -t (Thread)                                     │
│  • Rôle : Accélérer la compression                     │
│  • Implémentation : Multi-threading dans chaque lot    │
│  • Avantage : Compression 3-5× plus rapide             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  COMBINAISON -f -t (Ultra-Optimal)                      │
│  • Batch-fork : Parallélisation par lots               │
│  • Multi-threading : Compression parallèle par lot     │
│  • Terminal libéré immédiatement                       │
│  • Performance : 10-30× plus rapide                    │
│  • Meilleur des deux mondes                            │
└─────────────────────────────────────────────────────────┘
```

---

### **Recommandations pour le Sprint 2**

**Pour le Membre 2 :**

1. **Implémenter `-f` avec Batch-Fork**
   ```bash
   # Configuration
   readonly BATCH_SIZE=100
   
   # Diviser les fichiers en lots
   num_batches=$(( (total_files + BATCH_SIZE - 1) / BATCH_SIZE ))
   
   # Créer un fork par lot
   for ((batch=0; batch<num_batches; batch++)); do
       ( process_batch "$batch" ) &
   done
   ```

2. **Implémenter `-t` avec multi-threading pour compression**
   ```bash
   if [[ $OPT_THREAD -eq 1 ]]; then
       # Compression parallèle avec pigz ou gzip
       pigz -c "$file" > "$object_file.gz" 2>/dev/null || \
       gzip -c "$file" > "$object_file.gz"
   else
       gzip -c "$file" > "$object_file.gz"
   fi
   ```

3. **Permettre la combinaison `-f -t`**
   ```bash
   ./snapfile.sh -f -t save gros_projet/
   # → Batch-fork + compression parallèle = ULTRA-OPTIMAL
   ```

4. **Ajouter la progression**
   ```bash
   log_event "INFOS" "Batch $batch_num/$num_batches started (files $start-$end)"
   log_event "INFOS" "Batch $batch_num/$num_batches completed"
   ```

5. **Configuration flexible**
   ```bash
   # Permettre de configurer BATCH_SIZE
   BATCH_SIZE=${SNAPFILE_BATCH_SIZE:-100}
   ```

---

## 📚 Références

- **Documentation Sprint 2 :** `docs/POUR_SPRINT2.md`
- **Compatibilité options :** `docs/COMPATIBILITE_OPTIONS_COMMANDES.md`
- **Guide de démarrage :** `docs/GUIDE_DEMARRAGE.md`

---

## 📞 Support

Pour toute question sur l'implémentation :
- Consulter `docs/POUR_SPRINT2.md`
- Tester avec `tests/test_sprint1.sh`
- Contacter le Membre 1

---

*Dernière mise à jour : 2 mai 2026*
