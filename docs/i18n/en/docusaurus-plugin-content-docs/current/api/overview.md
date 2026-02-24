---
sidebar_position: 1
---

# API Overview

The Novaville REST API lets you interact with the platform programmatically.

## Base URL

- **Development**: `http://localhost:8000/api/v1/`
- **Production**: `https://api.novaville.com/api/v1/`

## Authentication

The API uses **JWT (JSON Web Tokens)**.

### Get a token

```http
POST /api/v1/auth/login/
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "votre_mot_de_passe"
}
```

**Response:**

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "Jean",
    "last_name": "Dupont",
    "role": "citizen"
  }
}
```

### Use the token

Include the access token in the `Authorization` header:

```http
GET /api/v1/events/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

### Refresh the token

Access tokens expire after 60 minutes. Use the refresh token to get a new one:

```http
POST /api/v1/auth/token/refresh/
Content-Type: application/json

{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response:**

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

## Response format

### Success

```json
{
  "data": { /* votre données */ },
  "message": "Succès",
  "status": 200
}
```

### Paginated list

```json
{
  "count": 42,
  "next": "http://api.example.org/accounts/?page=3",
  "previous": "http://api.example.org/accounts/?page=1",
  "results": [
    { /* objet 1 */ },
    { /* objet 2 */ }
  ]
}
```

### Error

```json
{
  "error": {
    "code": "validation_error",
    "message": "Les données fournies sont invalides",
    "details": {
      "email": ["Ce champ est requis."]
    }
  },
  "status": 400
}
```

## HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created |
| 204 | No Content | Success, no body |
| 400 | Bad Request | Invalid data |
| 401 | Unauthorized | Not authenticated |
| 403 | Forbidden | Not allowed |
| 404 | Not Found | Missing resource |
| 500 | Internal Server Error | Server error |

## Pagination

Lists are paginated by default (25 items/page).

### Pagination params

- `page`: Page number (default 1)
- `page_size`: Items per page (max 100)

**Exemple :**

```http
GET /api/v1/events/?page=2&page_size=50
```

## Filtering

Use query params to filter results.

**Exemple :**

```http
GET /api/v1/reports/?status=open&category=infrastructure
```

## Sorting

Use `ordering` to sort results.

**Exemple :**

```http
GET /api/v1/events/?ordering=-created_at  # Décroissant
GET /api/v1/events/?ordering=title        # Croissant
```

## Search

Use `search` for text queries.

**Exemple :**

```http
GET /api/v1/reports/?search=nid-de-poule
```

## Rate limiting

- **Authenticated**: 1000 req/hour
- **Unauthenticated**: 100 req/hour

Les limites sont indiquées dans les en-têtes de réponse :

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Main resources

### Authentication
- [Login](./auth/login) — User authentication
- [Refresh Token](./auth/refresh-token) — Refresh the token

### Users
- [List users](./users/list)
- [Create user](./users/create)
- [Update user](./users/update)
- [Delete user](./users/delete)

### Événements
- [Liste des événements](./events/list)
- [Créer un événement](./events/create)
- [Modifier un événement](./events/update)
- [Supprimer un événement](./events/delete)

### Rapports
- [Liste des rapports](./reports/list)
- [Créer un rapport](./reports/create)
- [Modifier un rapport](./reports/update)
- [Supprimer un rapport](./reports/delete)

## Versions de l'API

L'API est versionnée dans l'URL. La version actuelle est **v1**.

- `/api/v1/` - Version actuelle (stable)

Les anciennes versions seront maintenues pendant au moins 12 mois après la sortie d'une nouvelle version majeure.

## Support

Pour toute question ou problème avec l'API :

1. Consultez la documentation complète
2. Vérifiez les [exemples de code](https://github.com/Michael16b/Novaville/tree/main/examples)
3. Ouvrez une issue sur [GitHub](https://github.com/YOUR_GITHUBMichael16b_USERNAME/Novaville/issues)

## Outils recommandés

- **Postman** : [Collection Postman](https://www.postman.com/)
- **Bruno** : Voir `/api/Novaville/` pour les requêtes pré-configurées
- **curl** : Exemples fournis dans chaque endpoint

## Changelog

Consultez les [Notes de version](/blog) pour voir les dernières modifications de l'API.
