---
sidebar_position: 2
---

# Refresh Token

Obtenez un nouveau token d'accès en utilisant le token de rafraîchissement.

## Endpoint

```http
POST /api/v1/auth/token/refresh/
```

## Authentification

Aucune authentification requise (utilise le refresh token).

## Corps de la requête

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `refresh` | string | ✅ | Token de rafraîchissement JWT |

### Exemple

```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

## Réponse

### Succès (200 OK)

```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

### Erreur (401 Unauthorized) - Token invalide

```json
{
  "error": {
    "code": "token_invalid",
    "message": "Le token de rafraîchissement est invalide ou expiré"
  }
}
```

## Exemples de code

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

## Gestion automatique du token

### Intercepteur HTTP (Dart/Flutter)

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expiré, tentative de rafraîchissement
      try {
        final newToken = await refreshAccessToken(storedRefreshToken);
        // Sauvegarder le nouveau token
        await saveAccessToken(newToken);
        
        // Réessayer la requête originale
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final response = await dio.fetch(opts);
        return handler.resolve(response);
      } catch (e) {
        // Échec du rafraîchissement, déconnecter l'utilisateur
        await logout();
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }
}
```

## Durée de vie des tokens

| Token | Durée de vie | Utilisation |
|-------|-------------|-------------|
| Access Token | 60 minutes | Authentification des requêtes API |
| Refresh Token | 24 heures | Obtenir de nouveaux access tokens |

## Stratégie de rafraîchissement

### Rafraîchissement proactif (Recommandé)

Rafraîchissez le token **avant** son expiration :

```javascript
// Décoder le token pour obtenir l'expiration
function getTokenExpiration(token) {
  const payload = JSON.parse(atob(token.split('.')[1]));
  return payload.exp * 1000; // Convertir en millisecondes
}

// Rafraîchir 5 minutes avant l'expiration
function scheduleTokenRefresh(accessToken, refreshToken) {
  const expirationTime = getTokenExpiration(accessToken);
  const refreshTime = expirationTime - (5 * 60 * 1000); // 5 minutes avant
  const delay = refreshTime - Date.now();
  
  if (delay > 0) {
    setTimeout(async () => {
      const newToken = await refreshAccessToken(refreshToken);
      scheduleTokenRefresh(newToken, refreshToken);
    }, delay);
  }
}
```

### Rafraîchissement réactif

Rafraîchissez le token après avoir reçu une erreur 401 (voir exemple d'intercepteur ci-dessus).

## Sécurité

### Bonnes pratiques

1. **Stockage sécurisé** : Stockez le refresh token de manière ultra-sécurisée
2. **Une seule fois** : Chaque refresh token ne peut être utilisé qu'une seule fois
3. **Rotation** : À chaque rafraîchissement, un nouveau refresh token est fourni (optionnel, selon configuration)
4. **Révocation** : Les tokens peuvent être révoqués côté serveur

### Quand redemander la connexion

Si le refresh token est également expiré ou invalide, l'utilisateur doit se reconnecter via [Login](./login).

## Voir aussi

- [Login](./login) - Authentification utilisateur
- [Configuration JWT](../../getting-started/configuration#jwt) - Configuration des tokens
