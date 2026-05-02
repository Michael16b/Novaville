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
  "data": { /* your data */ },
  "message": "Success",
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
    { /* item 1 */ },
    { /* item 2 */ }
  ]
}
```

### Error

```json
{
  "error": {
    "code": "validation_error",
    "message": "Provided data is invalid",
    "details": {
      "email": ["This field is required."]
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
GET /api/v1/events/?ordering=-created_at  # descending
GET /api/v1/events/?ordering=title        # ascending
```

## Search

Use `search` for text queries.

**Exemple :**

```http
GET /api/v1/reports/?search=pothole
```

## Rate limiting

- **Authenticated**: 1000 req/hour
- **Unauthenticated**: 100 req/hour


Rate limits are indicated in the response headers:

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

### Events
- [List events](./events/list)
- [Create event](./events/create)
- [Update event](./events/update)
- [Delete event](./events/delete)

### Reports
- [List reports](./reports/list)
- [Create report](./reports/create)
- [Update report](./reports/update)
- [Delete report](./reports/delete)

## API versions

The API is versioned in the URL. Current version is **v1**.

- `/api/v1/` - current stable version

Older versions will be maintained for at least 12 months after the release of a new major version.

## Support

For API questions or issues:

1. Check the full documentation
2. Review the [code examples](https://github.com/Michael16b/Novaville/tree/main/examples)
3. Open an issue on [GitHub](https://github.com/Michael16b/Novaville/issues)

## Recommended tools

- **Postman**: [Postman collection](https://www.postman.com/)
- **Bruno**: see `/api/Novaville/` for pre-configured requests (repo `api/Novaville`)
- **OpenAPI / Swagger (backend)**: the backend exposes a full OpenAPI/Swagger UI (schemas, models, examples) available locally at `http://localhost:8000/api/docs/` when the backend is running — use it to inspect request/response models and examples.
- **curl**: examples available in each endpoint

## Changelog

See the [Release notes](/blog) for recent API changes.
