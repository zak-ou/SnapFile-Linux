# 📦 Rapport de Livraison - Sprint 2

## 📄 Informations Générales
*   **Projet** : SnapFile
*   **Livrable** : Sprint 2 (Backend & Parallélisme)
*   **Responsable** : Doha (Membre 2)
*   **Date** : 4 mai 2026

---

## 🚀 Fonctionnalités Livrées
1.  **Moteur de Snapshot** : Logique complète de sauvegarde avec déduplication.
2.  **Gestionnaire de Parallélisme C** :
    *   Worker Fork (`fork_worker`) : Parallélisation par processus.
    *   Worker Thread (`thread_worker`) : Parallélisation par threads (pthread).
3.  **Système de Verrouillage** : Utilisation de `flock` pour éviter les race conditions.
4.  **Déduplication Intelligente** : Stockage basé sur le hash SHA-256 avec compression Gzip.

---

## ⚠️ Codes d'Erreur du Système
Conformément aux spécifications du projet, voici la table des codes d'erreur implémentés :

| Code | Signification | Cause possible |
| :--- | :--- | :--- |
| **100** | Option non reconnue | Utilisation d'un flag non supporté (ex: `-z`). |
| **101** | Paramètre manquant | Oubli du chemin du dossier cible. |
| **102** | Dépôt non initialisé | Tentative de log/restore sans snapshots existants. |
| **103** | Version introuvable | L'ID de snapshot fourni n'existe pas. |
| **104** | Espace disque insuffisant | Moins de 50 Mo disponibles sur la partition. |
| **105** | Permission refusée | L'option `-r` (reset) nécessite les droits `sudo`. |
| **106** | Échec de compilation | `gcc` est absent ou erreur dans le code C des workers. |
| **107** | Erreur système | Échec de création des fichiers temporaires (`mktemp`). |
| **108** | Interruption | Le processus a été arrêté manuellement (Ctrl+C). |

---

## 🔧 Instructions pour le Membre 3
Pour le Sprint 3 (Commandes `log` et `restore`), vous devrez :
1.  Utiliser les fichiers `.meta` générés par le Sprint 2 pour lister les snapshots.
2.  Lire le contenu des fichiers meta pour retrouver les hashs dans `~/.snapfile/objects/`.
3.  Utiliser `gunzip` pour restaurer les fichiers originaux.

---
*Ce document constitue le rapport officiel de fin de sprint pour le Membre 2.*
