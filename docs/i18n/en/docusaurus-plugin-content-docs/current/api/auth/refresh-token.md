---
sidebar_position: 2
---

# Refresh Token

Obtain a new access token using the refresh token.

## Endpoint

```http
POST /api/v1/auth/token/refresh/
```

## Authentication

Not required (you use the refresh token instead).

## Request body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `refresh` | string | ✅ | JWT refresh token |

### Example

```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

## Response

### Success (200 OK)

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

### Error (401 Unauthorized) - Invalid token

```json
{
  "error": {
    "code": "token_invalid",
    "message": "The refresh token is invalid or expired"
  }
}
```

## Code examples

### JavaScript

```javascript
async function refreshAccessToken(refreshToken) {
  const response = await fetch('https://api.novaville.com/api/v1/auth/token/refresh/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      refresh: refreshToken,
    }),
  });

  if (!response.ok) {
    throw new Error('Failed to refresh token');
  }

  const data = await response.json();
  return data.access;
}
```

### Python

```python
import requests

def refresh_access_token(refresh_token):
    url = 'https://api.novaville.com/api/v1/auth/token/refresh/'
    payload = {'refresh': refresh_token}
    
    response = requests.post(url, json=payload)
    response.raise_for_status()
    
    return response.json()['access']
```

### Dart

```dart
Future<String> refreshAccessToken(String refreshToken) async {
  final response = await dio.post(
    'https://api.novaville.com/api/v1/auth/token/refresh/',
    data: {'refresh': refreshToken},
  );
  
  return response.data['access'];
}
```

## Automatic token handling

### HTTP interceptor (Dart/Flutter)

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Access token expired, attempt refresh
      try {
        final newToken = await refreshAccessToken(storedRefreshToken);
        await saveAccessToken(newToken);
        
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final response = await dio.fetch(opts);
        return handler.resolve(response);
      } catch (e) {
        await logout();
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }
}
```

## Token lifetime

| Token | Lifetime | Usage |
|-------|----------|-------|
| Access Token | 60 minutes | Authenticate API requests |
| Refresh Token | 24 hours | Obtain new access tokens |

## Refresh strategy

### Proactive refresh (recommended)

Refresh **before** expiration:

```javascript
function getTokenExpiration(token) {
  const payload = JSON.parse(atob(token.split('.')[1]));
  return payload.exp * 1000;
}

function scheduleTokenRefresh(accessToken, refreshToken) {
  const expirationTime = getTokenExpiration(accessToken);
  const refreshTime = expirationTime - (5 * 60 * 1000); // 5 minutes before
  const delay = refreshTime - Date.now();
  
  if (delay > 0) {
    setTimeout(async () => {
      const newToken = await refreshAccessToken(refreshToken);
      scheduleTokenRefresh(newToken, refreshToken);
    }, delay);
  }
}
```

### Reactive refresh

Refresh after receiving a 401 response (see interceptor example above).

## Security

### Good practices

1. **Secure storage**: Keep the refresh token in highly secure storage
2. **Single use**: Each refresh token should only be used once
3. **Rotation**: Issue a new refresh token on each refresh (optional, based on server config)
4. **Revocation**: Tokens can be revoked on the server side

### When to ask for login again

If the refresh token is also expired or invalid, prompt the user to log in again via [Login](./login).

## See also

- [Login](./login) — User authentication
- [JWT configuration](../../getting-started/configuration#jwt)