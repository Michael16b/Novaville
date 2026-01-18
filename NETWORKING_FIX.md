# Fix du Routing API Frontend → Backend sur Azure

## Problème Identifié

Lors du déploiement sur Azure Web App for Containers avec multi-containers, le frontend Flutter ne pouvait pas atteindre l'API backend:

```
AuthRepositoryImpl.login error: ClientException: NetworkError when attempting to fetch resource., 
uri=https://novavilleapp.azurewebsites.net/api/auth/token/
```

## Cause Racine

Dans Azure Web App for Containers:
- Seul **UN** port est exposé publiquement (défini par le premier container avec `ports:`)
- Le frontend écoute sur le port 80 (exposé publiquement)
- Le backend écoute sur le port 8000 (interne uniquement)
- **AUCUN** reverse proxy n'était configuré pour router `/api/` vers le backend

### Architecture AVANT le Fix ❌

```
Internet
   │
   │ HTTPS
   ▼
┌──────────────────────────────────────┐
│  novavilleapp.azurewebsites.net     │
│  (Port 80 uniquement exposé)        │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│   Frontend Container (Nginx)        │
│   - Sert les fichiers Flutter       │
│   - Port 80                          │
│   - ❌ Pas de proxy vers backend    │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│   Backend Container (Django)        │
│   - API sur /api/                    │
│   - Port 8000 (INACCESSIBLE)        │
│   - ❌ Pas de route publique        │
└──────────────────────────────────────┘

Résultat: NetworkError sur /api/auth/token/
```

### Architecture APRÈS le Fix ✅

```
Internet
   │
   │ HTTPS
   ▼
┌──────────────────────────────────────┐
│  novavilleapp.azurewebsites.net     │
│  (Port 80 exposé)                    │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│   Frontend Container (Nginx)        │
│   - Sert les fichiers Flutter       │
│   - Port 80                          │
│   ✅ Proxy configuré:                │
│      • /api/* → backend:8000        │
│      • /admin/* → backend:8000      │
│      • /static/* → backend:8000     │
│      • /media/* → backend:8000      │
└──────────────┬───────────────────────┘
               │ Réseau Docker
               │ (novaville-net)
               ▼
┌──────────────────────────────────────┐
│   Backend Container (Django)        │
│   - API sur /api/                    │
│   - Port 8000 (interne)              │
│   ✅ Accessible via nom: backend    │
└──────────────────────────────────────┘

Résultat: ✅ Toutes les requêtes /api/ fonctionnent
```

## Modifications Apportées

### 1. Frontend Dockerfile - Configuration Nginx

Ajout du reverse proxy dans `/frontend/Dockerfile`:

```nginx
# Proxy pour les requêtes API vers le backend Django
location /api/ {
  proxy_pass http://backend:8000;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
  
  # Timeout settings
  proxy_connect_timeout 60s;
  proxy_send_timeout 60s;
  proxy_read_timeout 60s;
}
```

### 2. Docker Compose - Configuration Réseau

**docker-compose-azure.yml et docker-compose-azure-managed-db.yml**:

```yaml
services:
  backend:
    expose:
      - "8000"  # Interne uniquement, pas publique
    networks:
      - novaville-net
    environment:
      - DJANGO_ALLOWED_HOSTS=novavilleapp.azurewebsites.net,backend,localhost

  frontend:
    ports:
      - "80:80"  # SEUL port exposé publiquement
    networks:
      - novaville-net
    depends_on:
      - backend

networks:
  novaville-net:
    driver: bridge
```

### 3. Django Settings - ALLOWED_HOSTS

```python
DJANGO_ALLOWED_HOSTS=novavilleapp.azurewebsites.net,backend,localhost
```

Cela permet à Django d'accepter les requêtes:
- Depuis `novavilleapp.azurewebsites.net` (public)
- Depuis `backend` (appels internes entre containers)
- Depuis `localhost` (tests locaux)

## Flux de Requête Complet

### Exemple: Login depuis le Frontend Flutter

```
1. Flutter App envoie:
   POST https://novavilleapp.azurewebsites.net/api/auth/token/
   
2. Azure route vers Frontend Container (port 80)
   
3. Nginx dans Frontend détecte /api/ et proxy vers:
   → http://backend:8000/api/auth/token/
   
4. Backend Django reçoit la requête avec:
   Host: novavilleapp.azurewebsites.net
   X-Forwarded-For: [IP client]
   X-Forwarded-Proto: https
   
5. Django vérifie ALLOWED_HOSTS: ✅
   
6. Django traite et retourne:
   {
     "access": "jwt_token...",
     "refresh": "refresh_token...",
     "user": {...}
   }
   
7. Nginx retourne la réponse au Flutter App
   
8. ✅ Succès!
```

## Actions Requises pour Déployer le Fix

### Étape 1: Rebuild les Images Docker

Les images doivent être reconstruites avec la nouvelle configuration Nginx:

```bash
# Le workflow GitHub Actions le fait automatiquement lors du push sur main
git push origin main
```

Ou manuellement:
```bash
docker build -t novaville.azurecr.io/novaville-frontend:latest ./frontend
docker push novaville.azurecr.io/novaville-frontend:latest
```

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
Frontend: 127.0.0.1 - - "POST /api/auth/token/ HTTP/1.1" 200
Backend: "POST /api/auth/token/ HTTP/1.1" 200 1234
```

## Test de Validation

### Depuis le Frontend Flutter

```dart
// Devrait maintenant fonctionner sans NetworkError
final response = await authRepository.login(
  username: 'admin',
  password: 'password',
);
```

### Depuis curl

```bash
curl -X POST https://novavilleapp.azurewebsites.net/api/auth/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"ChangeMe123"}'
```

Réponse attendue:
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com"
  }
}
```

## Résumé

✅ **Problème résolu**: Frontend peut maintenant communiquer avec le backend via Nginx reverse proxy

✅ **Fichiers modifiés**:
- `frontend/Dockerfile` - Ajout configuration proxy Nginx
- `docker-compose-azure.yml` - Mise à jour réseau et ALLOWED_HOSTS
- `docker-compose-azure-managed-db.yml` - Mise à jour réseau et ALLOWED_HOSTS

✅ **Action requise**: Rebuild et redéployer les images Docker

✅ **Résultat attendu**: Toutes les requêtes `/api/` fonctionnent correctement
