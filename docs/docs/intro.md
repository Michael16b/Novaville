---
sidebar_position: 1
---

# Bienvenue sur la documentation Novaville

Bienvenue sur la documentation complète de **Novaville**, plateforme de participation citoyenne. Cette doc suit l’UI du frontend (logo Novaville, palette, sections claires) et vous guide du premier lancement aux intégrations avancées.

## 📚 À propos

Pour chaque profil :

- **Développeurs** : architecture, API, exemples, sécurité
- **Ops** : déploiement Docker/Compose, variables d’environnement, supervision
- **Utilisateurs** : parcours UI aligné frontend, captures et étapes clés
- **Clients** : périmètre fonctionnel, roadmap, SLA indicatifs

## 🚀 Par où commencer ?

### Pour les développeurs

- [Guide de démarrage](getting-started/introduction) : setup local
- [Architecture](technical/architecture) : backend Django, frontend Flutter, PostgreSQL, auth JWT
- [API Overview](api/overview) : schémas, codes retour, pagination

### Pour les utilisateurs

- [Manuel utilisateur](user-manual/intro) : connexion, navigation, rapports
- UI cohérente avec le frontend : même logo, couleurs, wording

### Pour l’intégration API

- [Auth](api/auth/login) / [Refresh](api/auth/refresh-token) : exemples cURL, JS, Python, Dart

## 🏗️ Architecture

- **Backend** : Django REST + JWT, PostgreSQL
- **Frontend** : Flutter (mobile/web), thèmes alignés Novaville
- **Infra** : Docker/Compose (services api, front, docs, db)
- **Sécurité** : JWT, CORS, headers Nginx durcis

## 📖 Structure de la documentation

```
📁 Documentation
├── 📘 Guide de démarrage - Installation et configuration
├── 🔧 Documentation Technique - Architecture et détails techniques
├── 🌐 Documentation API - Endpoints REST et authentification
└── 📗 Manuel Utilisateur - Guide complet pour les utilisateurs finaux
```

## 🤝 Contribution

Cette documentation est maintenue et mise à jour régulièrement. Pour toute question ou suggestion, n'hésitez pas à ouvrir une issue sur le [dépôt GitHub](https://github.com/Michael16b/Novaville).

## 📝 Versions

Consultez les [Notes de version](/blog) pour voir les dernières mises à jour et améliorations.
