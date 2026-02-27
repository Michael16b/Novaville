# Copilot Instructions for UniCity / Novaville

## Project Overview

**UniCity** is a citizen platform for the city of **Novaville** (25,000 inhabitants) built as part of a TALENTIA challenge. It allows residents to submit civic reports, respond to surveys, view the participatory agenda, and communicate with elected officials. A back-office module serves municipal agents and elected officials.

## Repository Structure

```
Novaville/
├── backend/          # Django REST API (Python)
├── frontend/         # Flutter application (Dart)
├── api/              # Bruno API test collection
└── docker-compose.yml
```

## Tech Stack

### Backend (`backend/`)
- **Python** with **Django 5+** and **Django REST Framework**
- **PostgreSQL 15** database
- **JWT authentication** via `djangorestframework-simplejwt`
- **API docs** auto-generated with `drf-spectacular` (OpenAPI/Swagger at `/api/docs/`)
- **Testing**: `pytest` + `pytest-django` + `factory-boy`

### Frontend (`frontend/`)
- **Flutter / Dart** targeting Web, iOS, and Android
- **BLoC** architecture (`flutter_bloc` + `equatable`)
- **go_router** for navigation
- **http** package for API calls; `flutter_secure_storage` for token storage
- Linting: `very_good_analysis`

### Infrastructure
- **Docker + Docker Compose** for local and production environments
- **Nginx** serves the Flutter web build
- Deployment guides: `AZURE_DEPLOYMENT.md`, `docker-compose-azure.yml`

## Development Environment

Start everything locally with:
```bash
docker compose up -d --build
```

Key service URLs:
- Frontend: http://localhost:80
- Backend API: http://localhost:8000
- Swagger UI: http://localhost:8000/api/docs/
- Django Admin: http://localhost:8000/admin/

Environment variables go in a root `.env` file (see `.env.example`). Never commit secrets.

## How to Build and Test

### Backend
```bash
# Run all tests (inside container)
docker compose exec backend pytest

# Run a specific test file
docker compose exec backend pytest tests/test_auth.py

# Run with coverage
docker compose exec backend pytest --cov=. --cov-report=html
```

Tests live in `backend/tests/`. Test settings are in `backend/pytest.ini`; Django settings module is `config.settings`.

### Frontend
```bash
cd frontend

# Analyze code (linter)
flutter analyze

# Format code
flutter format .

# Run unit/widget tests
flutter test

# Run in browser (dev mode)
flutter run -d chrome --web-port 3000
```

Tests live in `frontend/test/`. The project uses `very_good_analysis` for strict linting.

## Code Style and Conventions

### Python / Backend
- Follow **PEP 8**
- Add **docstrings** to all public functions and classes
- Use **type hints** throughout
- Keep business logic in `domain/`, data access in `infrastructure/`, HTTP layer in `api/`
- New models go in `backend/core/db/models.py`; add serializers in `backend/api/v1/serializers/` and viewsets in `backend/api/v1/viewsets/`
- Register new routers in `backend/api/v1/urls.py`
- Always create and apply migrations after model changes

### Dart / Flutter
- Follow official **Dart style guide** and **very_good_analysis** rules
- Use **BLoC** pattern: events and states in `presentation/blocs/`, repositories in `data/repositories/`
- Keep feature code under `frontend/lib/features/<feature_name>/` with sub-folders `data/`, `domain/`, `presentation/`
- Use `GetIt` for dependency injection
- API base URL is configured via `frontend/.env` (`API_URL`)

## Architecture Patterns

### Backend – Clean / Layered Architecture
```
api/        → HTTP layer (serializers, viewsets, routers)
application → Use-case / service layer
domain/     → Business rules and domain objects
infrastructure/ → Repository implementations, DB access
core/       → Shared models and base classes
```

### Frontend – Feature-Based BLoC
```
User Interaction → Widget → Event → BLoC → Repository → API
                                      ↓
                              State → Widget Update
```

## Security Notes
- Secrets (`DJANGO_SECRET_KEY`, `JWT_SIGNING_KEY`, `DB_PASSWORD`) must **never** be committed to source control
- Use the `.env` file locally (already in `.gitignore`)
- In CI/CD, store secrets as GitHub Actions secrets (see README › GitHub Secrets)
- Production requires `DEBUG=False`, configured `ALLOWED_HOSTS`, and HTTPS

## Workflow
- Branch from `main`, name branches `feature/<name>` or `fix/<name>`
- Write or update tests for every change
- Ensure `flutter analyze` and `pytest` pass before opening a PR
