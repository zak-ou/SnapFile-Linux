# ⏩ Passation - Vers le Sprint 3

## 📋 État des lieux
Le Sprint 2 a posé les bases solides du stockage et de l'exécution parallèle. Le Membre 3 peut désormais s'appuyer sur une structure de données stable.

## 🛠️ À implémenter au Sprint 3
Conformément au cahier des charges, les tâches suivantes sont à réaliser :

### 1. Commande `cmd_log()`
*   **Objectif** : Afficher l'historique des snapshots d'un dossier.
*   **Source** : Parcourir les fichiers `.meta` dans `~/.snapfile/snapshots/`.
*   **Filtre** : Ne montrer que les snapshots dont le `source_dir` correspond au dossier cible.
*   **Affichage** : Tableau formaté (ID | Date | Nombre de fichiers | Taille totale).

### 2. Commande `cmd_restore()`
*   **Objectif** : Restaurer un état précédent.
*   **Paramètre** : Doit accepter un `--id` obligatoire.
*   **Action** :
    1. Lire le fichier `.meta` correspondant à l'ID.
    2. Pour chaque ligne (chemin + hash), copier le fichier depuis `objects/` vers la destination.
    3. Utiliser `gunzip` pour décompresser.
*   **Option `-s`** : Si activée, restaurer dans un répertoire temporaire de prévisualisation au lieu d'écraser les fichiers actuels.

## 📎 Ressources disponibles
*   **Structure Meta** : `relative_path hash` (un par ligne).
*   **Emplacement Objets** : `~/.snapfile/objects/[hash].gz`.
*   **Outils recommandés** : `grep`, `awk`, `gunzip`.

---
*Bonne chance pour le Sprint 3 !*
