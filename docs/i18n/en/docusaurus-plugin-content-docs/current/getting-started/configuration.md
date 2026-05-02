---
sidebar_position: 3
---

# Configuration
 
# Configuration

This guide covers advanced configuration of Novaville.

## Backend configuration

### Environment variables

The `.env` file holds the main configuration variables. Key ones:

#### Database

```env
POSTGRES_DB=novaville
POSTGRES_USER=novaville
POSTGRES_PASSWORD=your_secure_password
POSTGRES_HOST=db
POSTGRES_PORT=5432
```

#### Django

```env
SECRET_KEY=your_django_secret_key
DEBUG=False  # Always False in production
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
CSRF_TRUSTED_ORIGINS=https://your-domain.com
```

#### CORS

```env
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://app.your-domain.com
```

#### JWT

```env
JWT_ACCESS_TOKEN_LIFETIME=60  # minutes
JWT_REFRESH_TOKEN_LIFETIME=1440  # minutes (24h)
```

### Django settings

Primary configuration lives in `config/settings.py`.

## Frontend configuration

### Environment variables

In `lib/config/environment.dart`:

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

### Build with variables

```bash
# Development
flutter run --dart-define=API_URL=http://localhost:8000

# Production
flutter build apk \
  --dart-define=API_URL=https://api.your-domain.com \
  --dart-define=PRODUCTION=true
```

## Database configuration

### PostgreSQL

Recommended setup:

```sql
-- Create database
CREATE DATABASE novaville;

-- Create user
CREATE USER novaville WITH PASSWORD 'your_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE novaville TO novaville;

-- Recommended extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- If using geospatial data
```

## Docker configuration

### docker-compose.yml

The `docker-compose.yml` defines services:

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

## Security configuration

### In production

Ensure you:

1. **Disable DEBUG**
   ```python
   DEBUG = False
   ```

2. **Configure SECRET_KEY securely**
   ```bash
   python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   ```

3. **Set ALLOWED_HOSTS**
   ```python
   ALLOWED_HOSTS = ['your-domain.com', 'www.your-domain.com']
   ```

4. **Enable HTTPS**
   ```python
   SECURE_SSL_REDIRECT = True
   SESSION_COOKIE_SECURE = True
   CSRF_COOKIE_SECURE = True
   ```

5. **Set security headers**
   ```python
   SECURE_HSTS_SECONDS = 31536000
   SECURE_HSTS_INCLUDE_SUBDOMAINS = True
   SECURE_HSTS_PRELOAD = True
   ```

## Backup and restore

### Backup database

```bash
docker-compose exec db pg_dump -U novaville novaville > backup.sql
```

### Restore

```bash
docker-compose exec -T db psql -U novaville novaville < backup.sql
```

## Next steps

See [Technical documentation](../technical/architecture) to understand the system architecture.
