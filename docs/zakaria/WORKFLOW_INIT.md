# 🚀 Workflow d'Initialisation — SnapFile

**Date :** 11 mai 2026  
**Version :** 1.1.0

---

## 📋 Nouveau Workflow Obligatoire

Depuis la version 1.1.0, l'utilisateur **doit obligatoirement** initialiser le dépôt avant la première utilisation.

---

## ✅ Étapes d'Utilisation

### **Étape 1 : Initialisation (obligatoire, une seule fois)**

```bash
./src/snapfile.sh init
```

**Résultat :**
```
✅ Dépôt SnapFile initialisé avec succès !

📁 Structure créée :
   ~/.snapfile/
   ├── objects/     (stockage des fichiers compressés)
   ├── snapshots/   (métadonnées des sauvegardes)
   └── index/       (index par projet)

Vous pouvez maintenant utiliser : ./snapfile.sh save <dossier>
```

---

### **Étape 2 : Utilisation normale**

```bash
# Sauvegarder un projet
./src/snapfile.sh save mon_projet/

# Voir l'historique
./src/snapfile.sh log mon_projet/

# Restaurer
./src/snapfile.sh restore mon_projet/ --id <ID>
```

---

## ❌ Si vous oubliez `init`

```bash
./src/snapfile.sh save mon_projet/
```

**Erreur affichée :**
```
❌ ERREUR : Le dépôt SnapFile n'est pas initialisé

Veuillez d'abord initialiser le dépôt avec :
  ./snapfile.sh init

❌ ERREUR 102: Dépôt non initialisé. Exécutez 'snapfile init' d'abord.
```

---

## 🔄 Vérifier l'État du Dépôt

```bash
./src/snapfile.sh init
```

**Si déjà initialisé :**
```
⚠️  Le dépôt SnapFile existe déjà : ~/.snapfile

Structure actuelle :
drwxr-xr-x  2 user user 4096 mai 11 14:23 objects
drwxr-xr-x  2 user user 4096 mai 11 14:23 snapshots
drwxr-xr-x  2 user user 4096 mai 11 14:23 index

Snapshots : 5 fichier(s)
Objets    : 12 fichier(s)
Index     : 2 fichier(s)
```

---

## 🗑️ Réinitialiser Complètement

```bash
sudo ./src/snapfile.sh -r
```

Supprime tout et vous devrez refaire `init`.

---

## 📊 Comparaison Ancien vs Nouveau

| | Ancien Comportement | Nouveau Comportement |
|--|---------------------|----------------------|
| **Première utilisation** | `save` initialise automatiquement | `init` obligatoire d'abord |
| **Avantage** | Plus rapide | Plus explicite et clair |
| **Erreur si oubli** | Aucune | Erreur 102 avec message clair |

---

## 💡 Pourquoi ce Changement ?

1. **Clarté** : L'utilisateur sait qu'il initialise un dépôt
2. **Contrôle** : L'utilisateur décide quand initialiser
3. **Pédagogie** : Meilleure compréhension du fonctionnement
4. **Standard** : Comme Git (`git init` avant `git add`)

---

## 🎯 Workflow Complet

```
┌─────────────────────────────────────────────────────────┐
│  INSTALLATION                                           │
├─────────────────────────────────────────────────────────┤
│  1. Cloner le projet                                    │
│  2. chmod +x src/snapfile.sh                            │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  INITIALISATION (une seule fois)                        │
├─────────────────────────────────────────────────────────┤
│  ./src/snapfile.sh init                                 │
│  → Crée ~/.snapfile/                                    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  UTILISATION QUOTIDIENNE                                │
├─────────────────────────────────────────────────────────┤
│  ./src/snapfile.sh save projet_A/                       │
│  ./src/snapfile.sh save projet_B/                       │
│  ./src/snapfile.sh log projet_A/                        │
│  ./src/snapfile.sh restore projet_A/ --id <ID>          │
└─────────────────────────────────────────────────────────┘
```

---

## 📞 Support

Pour toute question :
- Voir l'aide : `./src/snapfile.sh -h`
- Documentation : `docs/zakaria/`

---

*Dernière mise à jour : 11 mai 2026*
