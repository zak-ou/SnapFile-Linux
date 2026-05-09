# 🔗 Compatibilité Options ↔ Commandes

**Date :** 2 mai 2026  
**Version :** 1.0.0

---

## 📋 Table des Matières

- [Réponse Rapide](#-réponse-rapide)
- [Tableau de Compatibilité](#-tableau-de-compatibilité)
- [Détails par Option](#-détails-par-option)
- [Détails par Commande](#-détails-par-commande)
- [Exemples Valides](#-exemples-valides)
- [Exemples Invalides](#-exemples-invalides)
- [Pourquoi Ces Restrictions ?](#-pourquoi-ces-restrictions-)
- [Résumé Visuel](#-résumé-visuel)

---

## ⚡ Réponse Rapide

**NON, toutes les options ne fonctionnent pas avec toutes les commandes !**

Certaines options ont du sens seulement avec certaines commandes :
- `-f` (fork) → Seulement avec `save` (sauvegarder en arrière-plan)
- `-t` (thread) → Seulement avec `save` (compression parallèle)
- `-s` (subshell) → Seulement avec `restore` (prévisualisation)
- `-l` (log) → Avec **toutes** les commandes
- `-h` (help) → Seule (pas besoin de commande)
- `-r` (reset) → Seule (pas besoin de commande)

---

## 📊 Tableau de Compatibilité

| Option | save | log | restore | Sans commande | Description |
|--------|------|-----|---------|---------------|-------------|
| **-h** | ❌ | ❌ | ❌ | ✅ | Affiche l'aide (seule) |
| **-f** | ✅ | ❌ | ❌ | ❌ | Fork (arrière-plan) |
| **-t** | ✅ | ❌ | ❌ | ❌ | Thread (parallèle) |
| **-s** | ❌ | ❌ | ✅ | ❌ | Subshell (prévisualisation) |
| **-l** | ✅ | ✅ | ✅ | ❌ | Log personnalisé |
| **-r** | ❌ | ❌ | ❌ | ✅ | Reset (seule) |

### **Légende :**
- ✅ = Compatible (a du sens)
- ❌ = Incompatible (n'a pas de sens)

---

## 🔧 Détails par Option

### **Option -h (Help)**

**Compatible avec :** Aucune commande (utilisée seule)

```bash
# ✅ VALIDE
./snapfile.sh -h

# ❌ INVALIDE (n'a pas de sens)
./snapfile.sh -h save mon_projet/
./snapfile.sh -h log mon_projet/
./snapfile.sh -h restore mon_projet/ --id 3
```

**Pourquoi ?**  
L'aide affiche le manuel complet et quitte immédiatement. Pas besoin de commande.

---

### **Option -f (Fork)**

**Compatible avec :** `save` uniquement

```bash
# ✅ VALIDE
./snapfile.sh -f save mon_projet/
# Sauvegarde en arrière-plan

# ❌ INVALIDE (n'a pas de sens)
./snapfile.sh -f log mon_projet/
# Pourquoi afficher les logs en arrière-plan ???

./snapfile.sh -f restore mon_projet/ --id 3
# Pourquoi restaurer en arrière-plan ???
```

**Pourquoi ?**  
- `save` peut prendre du temps (gros projets) → fork utile
- `log` est instantané → fork inutile
- `restore` doit être surveillé → fork dangereux

---

### **Option -t (Thread)**

**Compatible avec :** `save` uniquement

```bash
# ✅ VALIDE
./snapfile.sh -t save mon_projet/
# Compression parallèle des fichiers

# ❌ INVALIDE (n'a pas de sens)
./snapfile.sh -t log mon_projet/
# Pas de compression dans "log"

./snapfile.sh -t restore mon_projet/ --id 3
# La décompression est déjà optimisée
```

**Pourquoi ?**  
- `save` compresse des fichiers → parallélisation utile
- `log` lit juste des métadonnées → pas de compression
- `restore` décompresse (déjà optimisé) → thread inutile

---

### **Option -s (Subshell)**

**Compatible avec :** `restore` uniquement

```bash
# ✅ VALIDE
./snapfile.sh -s restore mon_projet/ --id 3
# Restaure dans /tmp/ pour prévisualiser

# ❌ INVALIDE (n'a pas de sens)
./snapfile.sh -s save mon_projet/
# Sauvegarder dans /tmp/ ??? Inutile !

./snapfile.sh -s log mon_projet/
# Afficher les logs dans /tmp/ ??? Absurde !
```

**Pourquoi ?**  
- `restore` modifie des fichiers → prévisualisation utile
- `save` ne modifie rien (crée juste un snapshot) → subshell inutile
- `log` ne modifie rien → subshell inutile

---

### **Option -l (Log personnalisé)**

**Compatible avec :** `save`, `log`, `restore` (toutes les commandes)

```bash
# ✅ VALIDE
./snapfile.sh -l ~/logs save mon_projet/
./snapfile.sh -l ~/logs log mon_projet/
./snapfile.sh -l ~/logs restore mon_projet/ --id 3
```

**Pourquoi ?**  
Toutes les commandes génèrent des logs → `-l` utile partout.

---

### **Option -r (Reset)**

**Compatible avec :** Aucune commande (utilisée seule)

```bash
# ✅ VALIDE
sudo ./snapfile.sh -r

# ❌ INVALIDE (n'a pas de sens)
sudo ./snapfile.sh -r save mon_projet/
# Reset ET save en même temps ??? Contradictoire !

sudo ./snapfile.sh -r log mon_projet/
# Reset ET log en même temps ??? Absurde !
```

**Pourquoi ?**  
Reset supprime tout et réinitialise. Pas de sens de faire autre chose en même temps.

---

## 📝 Détails par Commande

### **Commande : save**

**Options compatibles :** `-f`, `-t`, `-l`

```bash
# ✅ VALIDE
./snapfile.sh save mon_projet/
./snapfile.sh -f save mon_projet/
./snapfile.sh -t save mon_projet/
./snapfile.sh -l ~/logs save mon_projet/
./snapfile.sh -f -t save mon_projet/
./snapfile.sh -f -t -l ~/logs save mon_projet/

# ❌ INVALIDE
./snapfile.sh -s save mon_projet/     # -s est pour restore
./snapfile.sh -h save mon_projet/     # -h est seule
./snapfile.sh -r save mon_projet/     # -r est seule
```

---

### **Commande : log**

**Options compatibles :** `-l` uniquement

```bash
# ✅ VALIDE
./snapfile.sh log mon_projet/
./snapfile.sh -l ~/logs log mon_projet/

# ❌ INVALIDE
./snapfile.sh -f log mon_projet/      # Pas besoin de fork
./snapfile.sh -t log mon_projet/      # Pas de compression
./snapfile.sh -s log mon_projet/      # Pas de prévisualisation
./snapfile.sh -h log mon_projet/      # -h est seule
./snapfile.sh -r log mon_projet/      # -r est seule
```

---

### **Commande : restore**

**Options compatibles :** `-s`, `-l`

```bash
# ✅ VALIDE
./snapfile.sh restore mon_projet/ --id 3
./snapfile.sh -s restore mon_projet/ --id 3
./snapfile.sh -l ~/logs restore mon_projet/ --id 3
./snapfile.sh -s -l ~/logs restore mon_projet/ --id 3

# ❌ INVALIDE
./snapfile.sh -f restore mon_projet/ --id 3    # Pas besoin de fork
./snapfile.sh -t restore mon_projet/ --id 3    # Pas de compression
./snapfile.sh -h restore mon_projet/ --id 3    # -h est seule
./snapfile.sh -r restore mon_projet/ --id 3    # -r est seule
```

---

## ✅ Exemples Valides

### **Scénario 1 : Sauvegarde Simple**
```bash
./snapfile.sh save mon_projet/
```
**Options utilisées :** Aucune  
**Résultat :** Sauvegarde normale

---

### **Scénario 2 : Sauvegarde Rapide (Gros Projet)**
```bash
./snapfile.sh -f -t save gros_projet/
```
**Options utilisées :** `-f` (fork), `-t` (thread)  
**Résultat :** Sauvegarde en arrière-plan avec compression parallèle

---

### **Scénario 3 : Sauvegarde avec Logs Personnalisés**
```bash
./snapfile.sh -l ~/mes_logs save mon_projet/
```
**Options utilisées :** `-l` (log)  
**Résultat :** Sauvegarde avec logs dans `~/mes_logs/snapfile.log`

---

### **Scénario 4 : Sauvegarde Complète (Toutes Options)**
```bash
./snapfile.sh -f -t -l ~/logs save gros_projet/
```
**Options utilisées :** `-f`, `-t`, `-l`  
**Résultat :** Arrière-plan + Parallèle + Logs personnalisés

---

### **Scénario 5 : Consulter l'Historique**
```bash
./snapfile.sh log mon_projet/
```
**Options utilisées :** Aucune  
**Résultat :** Affiche tous les snapshots

---

### **Scénario 6 : Consulter avec Logs Personnalisés**
```bash
./snapfile.sh -l ~/logs log mon_projet/
```
**Options utilisées :** `-l`  
**Résultat :** Affiche les snapshots + log dans `~/logs/`

---

### **Scénario 7 : Restauration Normale**
```bash
./snapfile.sh restore mon_projet/ --id 3
```
**Options utilisées :** Aucune  
**Résultat :** Restaure directement le snapshot 3

---

### **Scénario 8 : Restauration Prudente (Prévisualisation)**
```bash
./snapfile.sh -s restore mon_projet/ --id 3
```
**Options utilisées :** `-s` (subshell)  
**Résultat :** Restaure dans `/tmp/` pour vérifier d'abord

---

### **Scénario 9 : Restauration avec Logs**
```bash
./snapfile.sh -s -l ~/logs restore mon_projet/ --id 3
```
**Options utilisées :** `-s`, `-l`  
**Résultat :** Prévisualisation + Logs personnalisés

---

### **Scénario 10 : Afficher l'Aide**
```bash
./snapfile.sh -h
```
**Options utilisées :** `-h` (seule)  
**Résultat :** Affiche le manuel complet

---

### **Scénario 11 : Réinitialisation Complète**
```bash
sudo ./snapfile.sh -r
```
**Options utilisées :** `-r` (seule)  
**Résultat :** Supprime tout et réinitialise

---

## ❌ Exemples Invalides

### **Erreur 1 : Fork avec log**
```bash
./snapfile.sh -f log mon_projet/
```
**Problème :** `log` est instantané, pas besoin de fork  
**Solution :** `./snapfile.sh log mon_projet/`

---

### **Erreur 2 : Thread avec restore**
```bash
./snapfile.sh -t restore mon_projet/ --id 3
```
**Problème :** `restore` ne compresse pas, thread inutile  
**Solution :** `./snapfile.sh restore mon_projet/ --id 3`

---

### **Erreur 3 : Subshell avec save**
```bash
./snapfile.sh -s save mon_projet/
```
**Problème :** `save` ne modifie rien, subshell inutile  
**Solution :** `./snapfile.sh save mon_projet/`

---

### **Erreur 4 : Help avec commande**
```bash
./snapfile.sh -h save mon_projet/
```
**Problème :** `-h` affiche l'aide et quitte, ignore la commande  
**Solution :** `./snapfile.sh -h` (seule)

---

### **Erreur 5 : Reset avec commande**
```bash
sudo ./snapfile.sh -r save mon_projet/
```
**Problème :** Reset supprime tout, contradictoire avec save  
**Solution :** `sudo ./snapfile.sh -r` (seule)

---

### **Erreur 6 : Combinaison Absurde**
```bash
./snapfile.sh -f -t -s save mon_projet/
```
**Problème :** `-s` (subshell) n'a pas de sens avec `save`  
**Solution :** `./snapfile.sh -f -t save mon_projet/`

---

## 🤔 Pourquoi Ces Restrictions ?

### **Raison 1 : Logique Fonctionnelle**

Chaque option a un **but spécifique** :
- `-f` → Libérer le terminal (utile pour `save` long)
- `-t` → Accélérer la compression (utile pour `save` seulement)
- `-s` → Prévisualiser avant modification (utile pour `restore` seulement)

---

### **Raison 2 : Éviter les Erreurs**

```bash
# Si on permettait -f avec log
./snapfile.sh -f log mon_projet/
# L'utilisateur pourrait penser que ça fait quelque chose
# Mais en réalité, ça ne change rien !
# → Confusion et fausses attentes
```

---

### **Raison 3 : Performance**

```bash
# Si on permettait -t avec log
./snapfile.sh -t log mon_projet/
# Ça lancerait des threads inutiles
# → Gaspillage de ressources
```

---

### **Raison 4 : Sécurité**

```bash
# Si on permettait -f avec restore
./snapfile.sh -f restore mon_projet/ --id 3
# La restauration se ferait en arrière-plan
# L'utilisateur ne verrait pas les erreurs potentielles
# → Risque de perte de données
```

---

## 🎯 Résumé Visuel

```
┌─────────────────────────────────────────────────────────┐
│  MATRICE DE COMPATIBILITÉ                               │
├─────────────────────────────────────────────────────────┤
│                                                          │
│         save    log    restore    seule                 │
│  -h     ❌      ❌      ❌         ✅                     │
│  -f     ✅      ❌      ❌         ❌                     │
│  -t     ✅      ❌      ❌         ❌                     │
│  -s     ❌      ❌      ✅         ❌                     │
│  -l     ✅      ✅      ✅         ❌                     │
│  -r     ❌      ❌      ❌         ✅                     │
│                                                          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  COMBINAISONS RECOMMANDÉES                              │
├─────────────────────────────────────────────────────────┤
│  save                                                    │
│  • Simple          : save mon_projet/                   │
│  • Rapide          : -f -t save gros_projet/            │
│  • Avec logs       : -l ~/logs save mon_projet/         │
│  • Complet         : -f -t -l ~/logs save gros_projet/  │
│                                                          │
│  log                                                     │
│  • Simple          : log mon_projet/                    │
│  • Avec logs       : -l ~/logs log mon_projet/          │
│                                                          │
│  restore                                                 │
│  • Direct          : restore mon_projet/ --id 3         │
│  • Prudent         : -s restore mon_projet/ --id 3      │
│  • Avec logs       : -l ~/logs restore mon_projet/ --id 3│
│  • Prudent + logs  : -s -l ~/logs restore ... --id 3    │
│                                                          │
│  Autres                                                  │
│  • Aide            : -h                                 │
│  • Reset           : sudo -r                            │
└─────────────────────────────────────────────────────────┘
```

---

## 📚 Règles à Retenir

### **Règle 1 : Options Spécifiques**
- `-f` et `-t` → Seulement avec `save`
- `-s` → Seulement avec `restore`

### **Règle 2 : Option Universelle**
- `-l` → Avec toutes les commandes

### **Règle 3 : Options Seules**
- `-h` et `-r` → Sans commande

### **Règle 4 : Combinaisons Logiques**
- Combinez seulement les options compatibles avec la commande
- Exemple : `-f -t save` ✅, mais pas `-f -s save` ❌

---

## 🔍 Comment Vérifier ?

### **Méthode 1 : Consulter ce Document**
Référez-vous au tableau de compatibilité ci-dessus.

---

### **Méthode 2 : Tester**
```bash
# Essayez la commande
./snapfile.sh -f log mon_projet/

# Si incompatible, le script devrait afficher un avertissement
# (à implémenter dans les sprints futurs)
```

---

### **Méthode 3 : Logique**
Demandez-vous : "Est-ce que cette option a du sens avec cette commande ?"

**Exemples :**
- "Fork avec log ?" → Non, log est instantané
- "Thread avec save ?" → Oui, save compresse des fichiers
- "Subshell avec restore ?" → Oui, pour prévisualiser

---

## 📞 Support

Pour plus d'informations :
- **Manuel complet :** `./snapfile.sh -h`
- **Différence options/commandes :** `docs/DIFFERENCE_OPTIONS_COMMANDES.md`
- **Pourquoi pas seulement options :** `docs/POURQUOI_PAS_SEULEMENT_OPTIONS.md`

---

*Dernière mise à jour : 2 mai 2026*
