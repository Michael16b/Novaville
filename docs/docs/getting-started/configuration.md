---
sidebar_position: 3
---

# Configuration

Ce guide couvre la configuration avancée de Novaville.

## Configuration du Backend

### Variables d'environnement

Le fichier `.env` contient toutes les variables de configuration. Voici les principales :

#### Base de données

```env
POSTGRES_DB=novaville
POSTGRES_USER=novaville
POSTGRES_PASSWORD=votre_mot_de_passe_securise
POSTGRES_HOST=db
POSTGRES_PORT=5432
```

#### Django

```env
SECRET_KEY=votre_cle_secrete_django
DEBUG=False  # Toujours False en production
ALLOWED_HOSTS=votre-domaine.com,www.votre-domaine.com
CSRF_TRUSTED_ORIGINS=https://votre-domaine.com
```

#### CORS

```env
CORS_ALLOWED_ORIGINS=https://votre-domaine.com,https://app.votre-domaine.com
```

#### JWT

```env
JWT_ACCESS_TOKEN_LIFETIME=60  # en minutes
JWT_REFRESH_TOKEN_LIFETIME=1440  # en minutes (24h)
```

### Configuration Django

Le fichier `config/settings.py` contient la configuration principale.

## Configuration du Frontend

### Variables d'environnement

Le fichier `lib/config/environment.dart` :

```dart
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
```

### Compilation avec variables

```bash
# Développement
flutter run --dart-define=API_URL=http://localhost:8000

# Production
flutter build apk \
  --dart-define=API_URL=https://api.votre-domaine.com \
  --dart-define=PRODUCTION=true
```

## Configuration de la base de données

### PostgreSQL

Recommandations de configuration :

```sql
-- Créer la base de données
CREATE DATABASE novaville;

-- Créer l'utilisateur
CREATE USER novaville WITH PASSWORD 'votre_mot_de_passe';

-- Accorder les privilèges
GRANT ALL PRIVILEGES ON DATABASE novaville TO novaville;

-- Extensions recommandées
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- Si utilisation de données géographiques
```

## Configuration Docker

### docker-compose.yml

Le fichier `docker-compose.yml` définit les services :

```yaml
version: '3.8'

services:
  db:
    image: postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

  backend:
    build: ./backend
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - ./backend:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
```

## Configuration de sécurité

### En production

Assurez-vous de :

1. **Désactiver DEBUG**
   ```python
   DEBUG = False
   ```

2. **Configurer SECRET_KEY de manière sécurisée**
   ```bash
   python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   ```

3. **Configurer ALLOWED_HOSTS**
   ```python
   ALLOWED_HOSTS = ['votre-domaine.com', 'www.votre-domaine.com']
   ```

4. **Activer HTTPS**
   ```python
   SECURE_SSL_REDIRECT = True
   SESSION_COOKIE_SECURE = True
   CSRF_COOKIE_SECURE = True
   ```

5. **Configurer les en-têtes de sécurité**
   ```python
   SECURE_HSTS_SECONDS = 31536000
   SECURE_HSTS_INCLUDE_SUBDOMAINS = True
   SECURE_HSTS_PRELOAD = True
   ```

## Sauvegarde et restauration

### Sauvegarde de la base de données

```bash
docker-compose exec db pg_dump -U novaville novaville > backup.sql
```

### Restauration

```bash
docker-compose exec -T db psql -U novaville novaville < backup.sql
```

## Prochaines étapes

Consultez la [Documentation Technique](../technical/architecture) pour comprendre l'architecture du système.
