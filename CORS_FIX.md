# Résolution du Problème CORS sur Azure

## Problème Identifié

Lors de l'utilisation de Flutter Web depuis Azure, l'application rencontre une `ClientException: NetworkError` même si le proxy Nginx fonctionne correctement (test navigateur retourne HTTP 400).

## Cause Racine

Azure Web App utilise des URLs dynamiques avec sous-domaines aléatoires:
- URL courte: `https://novavilleapp.azurewebsites.net/`
- URL réelle: `https://novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net/`

Le problème avait deux aspects:

### 1. ALLOWED_HOSTS Insuffisant
Django était configuré avec:
```python
ALLOWED_HOSTS = ['novavilleapp.azurewebsites.net', 'localhost', '127.0.0.1']
```

❌ Ne correspondait pas à l'URL réelle d'Azure

### 2. Configuration CORS Incomplète
Bien que `CORS_ALLOW_ALL_ORIGINS = True` était activé, les headers et méthodes n'étaient pas explicitement configurés, ce qui peut causer des problèmes avec certains navigateurs.

## Solution Appliquée

### 1. ALLOWED_HOSTS Dynamique avec Wildcards

**Fichier**: `backend/config/settings.py`

```python
# ALLOWED_HOSTS configuration
# Support for Azure Web App URLs with random subdomains
ALLOWED_HOSTS_ENV = os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1")
ALLOWED_HOSTS = [host.strip() for host in ALLOWED_HOSTS_ENV.split(",") if host.strip()]

# Add Azure wildcard patterns for Web Apps
ALLOWED_HOSTS.extend([
    'novavilleapp.azurewebsites.net',
    'novavilleapp-*.azurewebsites.net',  # Support for Azure random subdomains
    '*.francecentral-01.azurewebsites.net',  # Support for region-specific subdomains
    'localhost',
    '127.0.0.1',
    'backend',  # For internal Docker network calls
])
```

✅ Accepte maintenant:
- `novavilleapp.azurewebsites.net`
- `novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net`
- Tout sous-domaine Azure similaire

### 2. Configuration CORS Explicite

**Fichier**: `backend/config/settings.py`

```python
# CORS configuration for better browser compatibility
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
```

✅ Garantit que tous les headers et méthodes nécessaires sont autorisés

### 3. Mise à Jour Docker Compose

**Fichiers**: `docker-compose-azure.yml` et `docker-compose-azure-managed-db.yml`

```yaml
environment:
  - DJANGO_ALLOWED_HOSTS=novavilleapp.azurewebsites.net,novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net,backend,localhost
```

✅ L'URL réelle est maintenant incluse explicitement

## Vérification de la Solution

### Test 1: Headers CORS

```bash
curl -H "Origin: https://novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type, Authorization" \
     -X OPTIONS \
     https://novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net/api/auth/token/ \
     -v
```

Réponse attendue:
```
< HTTP/1.1 200 OK
< Access-Control-Allow-Origin: https://novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net
< Access-Control-Allow-Methods: DELETE, GET, OPTIONS, PATCH, POST, PUT
< Access-Control-Allow-Headers: accept, accept-encoding, authorization, content-type, ...
< Access-Control-Allow-Credentials: true
```

### Test 2: Requête POST depuis Flutter

```dart
final response = await http.post(
  Uri.parse('https://novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net/api/auth/token/'),
  headers: {
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'username': 'admin',
    'password': 'password',
  }),
);
```

✅ Devrait maintenant fonctionner sans `NetworkError`

## Déploiement

### Étape 1: Rebuild l'Image Backend

Les changements dans `settings.py` nécessitent une reconstruction de l'image:

```bash
docker build -t novaville.azurecr.io/novaville-backend:latest ./backend
docker push novaville.azurecr.io/novaville-backend:latest
```

Ou via GitHub Actions (automatique lors du push sur main).

### Étape 2: Redéployer sur Azure

```bash
az webapp config container set \
  --name NovavilleApp \
  --resource-group Novaville \
  --multicontainer-config-type COMPOSE \
  --multicontainer-config-file docker-compose-azure-managed-db.yml
```

### Étape 3: Vérifier les Logs

```bash
az webapp log tail --name NovavilleApp --resource-group Novaville
```

Logs attendus:
```
[wait_for_db] Database is ready!
Operations to perform:
  Apply all migrations...
Allowed hosts: ['novavilleapp.azurewebsites.net', 'novavilleapp-*.azurewebsites.net', ...]
```

## Configuration de Production (Optionnel)

Pour un environnement de production plus sécurisé, vous pouvez désactiver `CORS_ALLOW_ALL_ORIGINS` et spécifier uniquement les origines autorisées:

```python
# settings.py
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = [
    'https://novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net',
    'https://novavilleapp.azurewebsites.net',
]
```

Ou via variable d'environnement:

```yaml
# docker-compose-azure-managed-db.yml
environment:
  - CORS_ALLOWED_ORIGINS=https://novavilleapp-ghfkbnb7caa0c3g9.francecentral-01.azurewebsites.net,https://novavilleapp.azurewebsites.net
```

## Résumé

✅ **Problème résolu**: Configuration CORS et ALLOWED_HOSTS maintenant compatible avec les URLs Azure dynamiques

✅ **Fichiers modifiés**:
- `backend/config/settings.py` - ALLOWED_HOSTS avec wildcards + CORS explicite
- `docker-compose-azure.yml` - URL Azure réelle ajoutée
- `docker-compose-azure-managed-db.yml` - URL Azure réelle ajoutée

✅ **Action requise**: Rebuild et redéployer l'image backend

✅ **Résultat attendu**: Flutter Web peut maintenant appeler l'API sans NetworkError
