---
sidebar_position: 1
---

# Login

Authenticate a user and obtain a JWT token.

## Endpoint

```http
POST /api/v1/auth/login/
```

## Authentication

Not required.

## Request body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | ✅ | User email |
| `password` | string | ✅ | Password |

### Example

```json
{
  "email": "jane.doe@example.com",
  "password": "MyStrongPassword123!"
}
```

## Response

### Success (200 OK)

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "jane.doe@example.com",
    "first_name": "Jane",
    "last_name": "Doe",
    "role": "citizen",
    "avatar": "https://api.novaville.com/media/avatars/user1.jpg",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### Error (400 Bad Request) - Invalid credentials

```json
{
  "error": {
    "code": "invalid_credentials",
    "message": "Email or password is incorrect"
  }
}
```

### Error (400 Bad Request) - Missing data

```json
{
  "error": {
    "code": "validation_error",
    "message": "Invalid data",
    "details": {
      "email": ["This field is required."],
      "password": ["This field is required."]
    }
  }
}
```

### Error (429 Too Many Requests) - Too many attempts

```json
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Too many login attempts. Please try again in 15 minutes."
  }
}
```

## Response schema

### User object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique user id |
| `email` | string | Email address |
| `first_name` | string | First name |
| `last_name` | string | Last name |
| `role` | string | Role: `citizen`, `admin`, `agent` |
| `avatar` | string \| null | Avatar URL |
| `created_at` | string (ISO 8601) | Account creation date |

## JWT tokens

### Access token

- **Lifetime**: 60 minutes
- **Usage**: Include in `Authorization: Bearer <token>` for authenticated requests

### Refresh token

- **Lifetime**: 24 hours
- **Usage**: Obtain a new access token via `/api/v1/auth/token/refresh/`

## Code examples

### cURL

```bash
curl -X POST https://api.novaville.com/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "jane.doe@example.com",
    "password": "MyStrongPassword123!"
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
    email: 'jane.doe@example.com',
    password: 'MyStrongPassword123!',
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
    'email': 'jane.doe@example.com',
    'password': 'MyStrongPassword123!'
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
      'email': 'jane.doe@example.com',
      'password': 'MyStrongPassword123!',
    },
  );
  
  final accessToken = response.data['access'];
  print('Token: $accessToken');
} catch (e) {
  print('Error: $e');
}
```

## Security

### Good practices

1. **Secure storage**: Store tokens securely (Keychain on iOS, Keystore on Android)
2. **HTTPS only**: Never send credentials over insecure transport
3. **No cleartext storage**: Never store the password in plain text
4. **Error handling**: Handle errors without leaking sensitive details

### Rate limiting

- **Maximum**: 5 attempts per IP every 15 minutes
- **After 5 failures**: The account is temporarily locked for 15 minutes

## Authentication flow

```
┌─────────┐                      ┌─────────┐
│ Client  │                      │  API    │
└────┬────┘                      └────┬────┘
     │                                │
     ├─── POST /auth/login/ ─────────>│
     │    {email, password}            │
     │                                │
     │                          ┌──────┴──────┐
     │                          │ Verify       │
     │                          │ credentials  │
     │                          └──────┬──────┘
     │                                │
     │<─── 200 OK ────────────────────┤
     │    {access, refresh, user}     │
     │                                │
     ├─── GET /events/ ───────────────>│
     │    Authorization: Bearer <token>│
     │                                │
     │<─── 200 OK ────────────────────┤
     │    {events}                    │
     │                                │
```

## See also

- [Refresh Token](./refresh-token) — Refresh the access token
- [Authentication](../../getting-started/configuration#jwt) — JWT configuration