---
sidebar_position: 2
---

# Local Deployment

This document explains how to deploy and run Novaville completely locally on your machine using Docker Compose.

## Prerequisites

- **Docker Desktop** (or Docker + Docker Compose)
  - Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - macOS: [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Linux: [Docker](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/install/)
- **Git**: to clone the repository
- **Minimum 4 GB RAM** available (Docker)
- **Ports 8000, 80, 5432 free** on your machine

Verify installation:

```bash
docker --version
docker compose version
```

---

## 1. Clone and prepare the project

```bash
# Clone the repository
git clone https://github.com/Michael16b/Novaville.git
cd Novaville

# Copy environment file
cp .env.example .env

# (Optional) Customize .env if needed
# Default values work for local development
```

**Minimal `.env` for development**:

```bash
# Django
DEBUG=True
DJANGO_SECRET_KEY=local-development-key-not-for-production
JWT_SIGNING_KEY=local-jwt-key-not-for-production

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=novaville
DB_USER=novaville_user
DB_PASSWORD=novaville_password
DB_HOST=postgres
DB_PORT=5432

# Django superuser
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@localhost
DJANGO_SUPERUSER_PASSWORD=admin123

# Frontend API
API_URL=http://localhost:8000
```

---

## 2. Start services with Docker Compose

### Complete startup (all services)

```bash
# Start all services in background
docker compose up -d --build
```

**This starts:**
- ✅ PostgreSQL (database)
- ✅ Backend Django (REST API)
- ✅ Frontend Flutter (web)
- ✅ Nginx (reverse proxy)

**Wait 10-15 seconds** for services to start and migrations to run.

### Alternative: verbose startup (see logs)

```bash
# Start without detaching (-d) to see logs in real time
docker compose up --build
```

Press `Ctrl+C` to stop (containers also stop).

---

## 3. Verify everything works

### Check service status

```bash
# See running containers
docker compose ps
```

You should see:
```
CONTAINER ID   IMAGE                        STATUS
xxxxx          novaville-backend:latest     Up 2 minutes
xxxxx          novaville-frontend:latest    Up 2 minutes
xxxxx          bitnami-postgresql:15        Up 2 minutes
```

### Test service access

**Frontend (Flutter Web)**:
```
http://localhost:80
```

**Backend API**:
```
http://localhost:8000/api/
```

**Swagger/OpenAPI (interactive documentation)**:
```
http://localhost:8000/api/docs/
```

**Django Admin**:
```
http://localhost:8000/admin/
```
- Username: `admin`
- Password: `admin123`

---

## 4. Run migrations and initialize data

Migrations run **automatically** on startup (if `MIGRATE=1` in `.env`).

Verify manually:

```bash
# Check migration status
docker compose exec backend python manage.py showmigrations

# Run migrations if needed
docker compose exec backend python manage.py migrate

# Create superuser if needed
docker compose exec backend python manage.py createsuperuser
```

---

## 5. Run tests locally

### Backend (Django/Python)

```bash
# Run all tests
docker compose exec backend pytest

# Run a specific test file
docker compose exec backend pytest tests/test_auth.py -v

# Run with code coverage
docker compose exec backend pytest --cov=. --cov-report=html
```

### Frontend (Flutter/Dart)

```bash
# Go to frontend directory
cd frontend

# Run unit tests
flutter test

# Run app in development mode (web)
flutter run -d chrome --web-port 3000
```

---

## 6. Development with auto-reload

### Backend Django

```bash
# Django server auto-reloads on code changes
# Access at http://localhost:8000
```

### Frontend Flutter

For active frontend development, use Flutter's **hot reload**:

```bash
cd frontend

# Run in development mode on Chrome
flutter run -d chrome --web-port 3000

# Press 'r' in terminal for hot reload
# Press 'q' to stop
```

---

## 7. Access service logs

### All services

```bash
# See logs from all services
docker compose logs -f

# See last 50 lines
docker compose logs --tail 50
```

### Specific service

```bash
# Backend logs
docker compose logs -f backend

# Database logs
docker compose logs -f postgres

# Frontend logs
docker compose logs -f frontend
```

Press `Ctrl+C` to stop tailing logs.

---

## 8. Modify code and see changes

### Backend (Django)

```bash
# 1. Modify a file in backend/
# 2. Changes are auto-detected
# 3. Refresh http://localhost:8000 to see changes
```

### Frontend (Flutter)

```bash
# 1. Modify a file in frontend/lib/
# 2. Press 'r' in Flutter terminal for hot reload
# 3. See changes immediately in browser
```

### Database (model changes)

```bash
# 1. Modify a model in backend/core/models.py
# 2. Create a migration
docker compose exec backend python manage.py makemigrations

# 3. Apply the migration
docker compose exec backend python manage.py migrate

# 4. Refresh the API
```

---

## 9. Stop services

### Stop services (keep data)

```bash
# Stop all containers
docker compose stop
```

### Stop and remove containers

```bash
# Stop and remove containers (data persists in volumes)
docker compose down
```

### Full cleanup (warning: deletes data)

```bash
# Stop, remove containers, networks, and volumes
docker compose down -v
```

---

## 10. Common troubleshooting

### Error: "Port 8000 is already in use"

```bash
# Find process using port 8000
lsof -i :8000

# Kill the process (on Windows, use Task Manager)
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Error: "PostgreSQL connection refused"

```bash
# Verify PostgreSQL container is running
docker compose ps postgres

# Restart PostgreSQL
docker compose restart postgres

# Check logs
docker compose logs postgres
```

### Error: "Database does not exist"

```bash
# Remove database volume and restart
docker compose down -v
docker compose up -d --build
```

### Error: "Module not found" (Python)

```bash
# Reinstall Python dependencies
docker compose exec backend pip install -r requirements.txt

# Or rebuild backend image
docker compose build --no-cache backend
```

### Frontend blank/not loading

```bash
# Clear browser cache (Ctrl+Shift+Delete)
# Or open in incognito mode

# Check frontend logs
docker compose logs frontend

# Restart frontend container
docker compose restart frontend
```

---

## 11. Access the database

### Connect to PostgreSQL directly

```bash
# Open PostgreSQL terminal
docker compose exec postgres psql -U novaville_user -d novaville

# Useful PostgreSQL commands
\dt                    # List all tables
\d table_name          # Show table structure
SELECT * FROM table;   # SQL query
\q                     # Quit
```

### Via pgAdmin (web interface)

You can add a pgAdmin service to `docker-compose.yml` to manage PostgreSQL via web interface:

```yaml
pgadmin:
  image: dpage/pgadmin4:latest
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@localhost
    PGADMIN_DEFAULT_PASSWORD: admin
  ports:
    - "5050:80"
```

Then access `http://localhost:5050`.

---

## 12. Quick reference

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | `http://localhost:80` | N/A |
| Backend API | `http://localhost:8000/api/` | N/A |
| Swagger/OpenAPI | `http://localhost:8000/api/docs/` | N/A |
| Django Admin | `http://localhost:8000/admin/` | admin / admin123 |
| PostgreSQL | `localhost:5432` | novaville_user / novaville_password |

---

## See also

- [Developer Onboarding](../dev-onboarding.md) — Flutter and Docker installation
- [Internal Guides](./internal-guides.md) — Team procedures
- [Azure Deployment](./azure-deployment.md) — Production deployment
