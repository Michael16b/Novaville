---
sidebar_position: 1
---

# Architecture

This page describes the overall architecture of the Novaville platform.

> See also the internal guide: [Internal Guides](./internal-guides) — installation procedures, first-steps and deployment playbook.

## Overview

Novaville follows a classic **three-tier architecture**:

```
┌─────────────────┐
│   Frontend      │  Flutter Mobile/Web App
│   (Flutter)     │
└────────┬────────┘
         │ HTTPS/REST
         │
┌────────▼────────┐
│   Backend       │  Django REST API
│   (Django)      │
└────────┬────────┘
         │ SQL
         │
┌────────▼────────┐
│   Database      │  PostgreSQL
│  (PostgreSQL)   │
└─────────────────┘
```

## Composants principaux

### 1. Frontend Mobile (Flutter)

Le frontend est une application **Flutter** qui fonctionne sur iOS, Android et Web.

**Structure :**
```
lib/
├── main.dart                 # Point d'entrée
├── app/                      # Configuration de l'app
├── config/                   # Configuration et constantes
├── core/                     # Fonctionnalités core
│   ├── network/             # Client HTTP, intercepteurs
│   ├── storage/             # Stockage local
│   └── auth/                # Gestion d'authentification
├── features/                # Fonctionnalités métier
│   ├── auth/
│   ├── events/
│   ├── reports/
│   └── surveys/
├── design_systems/          # Composants UI réutilisables
└── ui/                      # Écrans et widgets
```

**Technologies clé :**
- **State Management** : Riverpod / Provider
- **Navigation** : GoRouter
- **HTTP Client** : Dio
- **Storage** : SharedPreferences / Hive
- **Maps** : Google Maps / OpenStreetMap

### 2. Backend API (Django)

Le backend est une **API REST** construite avec Django et Django REST Framework.

**Structure :**
```
backend/
├── manage.py
├── config/                   # Configuration Django
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── core/                     # Modèles métier
│   ├── models.py
│   └── admin.py
├── api/                      # API REST
│   └── v1/
│       ├── serializers/
│       ├── viewsets/
│       ├── permissions.py
│       └── urls.py
├── application/              # Logique métier
│   └── services/
├── domain/                   # Entités du domaine
└── infrastructure/           # Repositories, services externes
    └── repositories/
```

**Architecture en couches (Clean Architecture) :**

1. **Presentation Layer** (`api/`) : Points d'entrée REST, serializers
2. **Application Layer** (`application/`) : Cas d'usage, orchestration
3. **Domain Layer** (`domain/`) : Entités métier, règles
4. **Infrastructure Layer** (`infrastructure/`) : Accès données, services externes

### 3. Base de données (PostgreSQL)

PostgreSQL est utilisé comme base de données principale.

**Modèles principaux :**

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   User      │────<│   Report     │>────│   Category  │
└─────────────┘     └──────────────┘     └─────────────┘
       │                    │
       │                    │
       ▼                    ▼
┌─────────────┐     ┌──────────────┐
│   Event     │     │   Comment    │
└─────────────┘     └──────────────┘
       │
       ▼
┌─────────────┐
│ Participant │
└─────────────┘
```

## Flux de données

### Authentification JWT

```
Client                    Backend                   Database
  │                         │                          │
  ├──POST /auth/login/──────>│                          │
  │                         ├──Verify credentials──────>│
  │                         │<─────User data───────────┤
  │<──JWT tokens────────────┤                          │
  │                         │                          │
  ├──GET /api/events/───────>│                          │
  │  (Authorization: Bearer) │                          │
  │                         ├──Verify JWT──────────────>│
  │                         ├──Query events────────────>│
  │                         │<─────Events data─────────┤
  │<──Events list───────────┤                          │
```

### Création d'un rapport

```
1. User submits report (text, images, location)
2. Frontend validates data
3. Upload images to storage
4. Send report data to API
5. Backend validates and saves to DB
6. Send notifications to admins
7. Return success response
```

## Principes architecturaux

### Backend

1. **Separation of Concerns** : Code organisé en couches distinctes
2. **Dependency Injection** : Utilisation de repositories injectés
3. **Single Responsibility** : Chaque classe a une seule responsabilité
4. **API Versioning** : `/api/v1/` pour faciliter l'évolution
5. **RESTful Design** : Respect des conventions REST

### Frontend

1. **Feature-based Structure** : Organisation par fonctionnalité
2. **Reactive Programming** : Utilisation de Streams et StateManagement
3. **Clean Architecture** : Séparation Data/Domain/Presentation
4. **Dependency Injection** : Utilisation de Riverpod providers
5. **Testability** : Code facilement testable

## Sécurité

### Authentification

- **JWT** (JSON Web Tokens) pour l'authentification stateless
- Token d'accès (courte durée) + Token de rafraîchissement
- Stockage sécurisé des tokens dans le client

### Autorisation

- **RBAC** (Role-Based Access Control)
- Permissions granulaires sur les endpoints
- Validation des permissions à chaque requête

### Données

- **HTTPS** obligatoire en production
- **CORS** configuré strictement
- **Sanitization** des entrées utilisateur
- **SQL Injection** : Protection via ORM Django
- **XSS** : Échappement automatique des outputs

## Performance

### Backend

- **Database Indexing** : Index sur les champs fréquemment recherchés
- **Query Optimization** : Utilisation de `select_related` et `prefetch_related`
- **Caching** : Redis pour le cache (optionnel)
- **Pagination** : Limiter les résultats des listes

### Frontend

- **Lazy Loading** : Chargement progressif des données
- **Image Optimization** : Compression et redimensionnement
- **State Management** : Éviter les reconstructions inutiles
- **Local Storage** : Cache local pour mode hors ligne

## Déploiement

### Conteneurisation

- **Docker** : Chaque service dans un conteneur
- **Docker Compose** : Orchestration pour le développement
- **Multi-stage builds** : Images optimisées pour la production

### CI/CD

- **GitHub Actions** : Tests automatiques et déploiement
- **Tests** : Exécution automatique à chaque push
- **Déploiement** : Automatique sur main branch

### Infrastructure

- **Azure** : Hébergement cloud
- **Azure Container Instances** : Conteneurs managés
- **Azure Database for PostgreSQL** : Base de données managée

## Monitoring et Logs

### Backend

- **Django Logging** : Logs structurés
- **Sentry** : Tracking des erreurs
- **Health Check Endpoint** : `/api/health/`

### Frontend

- **Crashlytics** : Rapports de crash (Firebase)
- **Analytics** : Suivi de l'utilisation

## Évolutions futures

### Court terme
- Ajout d'une API GraphQL en complément de REST
- Implémentation du mode hors ligne complet
- Notifications push

### Moyen terme
- Microservices pour certaines fonctionnalités
- Message Queue (RabbitMQ/Kafka) pour les tâches asynchrones
- WebSockets pour les notifications temps réel

### Long terme
- IA pour la classification automatique des rapports
- Analytics avancés avec BigData
- API publique pour partenaires
