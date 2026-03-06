---
sidebar_position: 1
---

# Login

Authentifiez un utilisateur et obtenez un JWT token.

## Endpoint

```http
POST /api/v1/auth/login/
```

## Authentification

Aucune authentification requise.

## Corps de la requête

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `email` | string | ✅ | Email de l'utilisateur |
| `password` | string | ✅ | Mot de passe |

### Exemple

```json
{
  "email": "jean.dupont@example.com",
  "password": "MonMotDePasse123!"
}
```

## Réponse

### Succès (200 OK)

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "jean.dupont@example.com",
    "first_name": "Jean",
    "last_name": "Dupont",
    "role": "citizen",
    "avatar": "https://api.novaville.com/media/avatars/user1.jpg",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### Erreur (400 Bad Request) - Identifiants invalides

```json
{
  "error": {
    "code": "invalid_credentials",
    "message": "Email ou mot de passe incorrect"
  }
}
```

### Erreur (400 Bad Request) - Données manquantes

```json
{
  "error": {
    "code": "validation_error",
    "message": "Données invalides",
    "details": {
      "email": ["Ce champ est requis."],
      "password": ["Ce champ est requis."]
    }
  }
}
```

### Erreur (429 Too Many Requests) - Trop de tentatives

```json
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Trop de tentatives de connexion. Réessayez dans 15 minutes."
  }
}
```

## Schema de réponse

### User Object

| Champ | Type | Description |
|-------|------|-------------|
| `id` | integer | Identifiant unique de l'utilisateur |
| `email` | string | Adresse email |
| `first_name` | string | Prénom |
| `last_name` | string | Nom de famille |
| `role` | string | Rôle : `citizen`, `admin`, `agent` |
| `avatar` | string \| null | URL de l'avatar |
| `created_at` | string (ISO 8601) | Date de création du compte |

## Tokens JWT

### Access Token

- **Durée de vie** : 60 minutes
- **Usage** : À inclure dans l'en-tête `Authorization: Bearer <token>` pour toutes les requêtes authentifiées

### Refresh Token

- **Durée de vie** : 24 heures
- **Usage** : Utilisé pour obtenir un nouveau access token via `/api/v1/auth/token/refresh/`

## Exemples de code

### cURL

```bash
curl -X POST https://api.novaville.com/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jean.dupont@example.com",
    "password": "MonMotDePasse123!"
  }'
```

### JavaScript (Fetch)

```javascript
const response = await fetch('https://api.novaville.com/api/v1/auth/login/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'jean.dupont@example.com',
    password: 'MonMotDePasse123!',
  }),
});

const data = await response.json();
console.log(data.access); // JWT access token
```

### Python (requests)

```python
import requests

url = 'https://api.novaville.com/api/v1/auth/login/'
payload = {
    'email': 'jean.dupont@example.com',
    'password': 'MonMotDePasse123!'
}

response = requests.post(url, json=payload)
data = response.json()
print(data['access'])  # JWT access token
```

### Dart (Flutter)

```dart
import 'package:dio/dio.dart';

final dio = Dio();

try {
  final response = await dio.post(
    'https://api.novaville.com/api/v1/auth/login/',
    data: {
      'email': 'jean.dupont@example.com',
      'password': 'MonMotDePasse123!',
    },
  );
  
  final accessToken = response.data['access'];
  print('Token: $accessToken');
} catch (e) {
  print('Error: $e');
}
```

## Sécurité

### Bonnes pratiques

1. **Stockage sécurisé** : Stockez les tokens de manière sécurisée (Keychain sur iOS, KeyStore sur Android)
2. **HTTPS uniquement** : N'envoyez jamais les identifiants sur une connexion non sécurisée
3. **Pas de stockage en clair** : Ne stockez jamais le mot de passe en clair
4. **Gestion des erreurs** : Gérez correctement les erreurs sans exposer d'informations sensibles

### Rate Limiting

- **Maximum** : 5 tentatives par IP toutes les 15 minutes
- **Après 5 échecs** : Le compte est temporairement bloqué pendant 15 minutes

## Flux d'authentification

```
┌─────────┐                      ┌─────────┐
│ Client  │                      │  API    │
└────┬────┘                      └────┬────┘
     │                                │
     ├─── POST /auth/login/ ─────────>│
     │    {email, password}            │
     │                                 │
     │                          ┌──────┴──────┐
     │                          │ Verify       │
     │                          │ credentials  │
     │                          └──────┬──────┘
     │                                 │
     │<─── 200 OK ────────────────────┤
     │    {access, refresh, user}     │
     │                                 │
     ├─── GET /events/ ───────────────>│
     │    Authorization: Bearer <token>│
     │                                 │
     │<─── 200 OK ────────────────────┤
     │    {events}                     │
     │                                 │
```

## Voir aussi

- [Refresh Token](./refresh-token) - Rafraîchir le token d'accès
- [Authentification](../../getting-started/configuration#jwt) - Configuration JWT
