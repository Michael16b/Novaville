# Novaville Platform

A citizen participation and reporting platform built with Django (Backend), Flutter (Frontend), and PostgreSQL.

> **📚 Full documentation available in English at http://localhost:3000**
>
> **Quick start:** `bash control-center.sh` → Choose option 1

## Quick Start - Launch Documentation

```bash
# Interactive menu (easiest)
bash control-center.sh

# Or direct Docker
cd docs && docker-compose up -d

# Then access: http://localhost:3000 (English) or /fr (French)
```

---

## UniCity - Citizen Platform for Novaville

## 📋 About the Project

### Context

This project was developed as part of a challenge organized by **TALENTIA**, a digital innovation consulting firm and partner to local authorities. The goal is to create a citizen application for the city of **Novaville** (25,000 inhabitants), designed to strengthen citizen participation and improve communication between residents, associations, and elected officials.

### Objectives

The **UniCity** application addresses the following needs:
- **Citizen reports**: allow residents to report issues (roads, lighting, cleanliness)
- **Surveys & public consultations**: facilitate democratic participation
- **Participatory agenda**: centralize events from the city and local associations
- **Citizen discussion**: integration with the town hall's social media
- **Back-office**: management interface for elected officials and municipal agents

### Technical Specifications

- **Responsive** application: accessible on PC, tablet, and smartphone
- **Authentication**: two profiles (Citizen / Elected Official-Municipal Agent)
- **Security & GDPR**: compliant personal data management
- **User experience**: simple interface accessible to all audiences (including elderly people)
- **Scalability**: architecture allowing the addition of new features

---

## 🏗️ Technical Architecture

### Technology Stack

#### Backend
- **Framework**: Django 5.0+ with Django REST Framework
- **Database**: PostgreSQL 15
- **Authentication**: JWT (djangorestframework-simplejwt)
- **API Documentation**: drf-spectacular (OpenAPI/Swagger)
- **Web Server**: Gunicorn
- **Testing**: pytest

#### Frontend
- **Framework**: Flutter (Web, iOS, Android)
- **Architecture**: BLoC (Business Logic Component)
- **State Management**: flutter_bloc + equatable
- **HTTP Client**: http package
- **Secure Storage**: flutter_secure_storage
- **Configuration**: flutter_dotenv

#### Infrastructure
- **Containerization**: Docker + Docker Compose
- **Web Server**: Nginx (for frontend)
- **Deployment**: Compatible with Azure Web App / VM / OVH

---

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Git

### Development Environment Setup

1. **Clone the repository**
```bash
git clone https://github.com/Michael16b/Novaville.git
cd Novaville
```

2. **Configure environment variables**

Create a `.env` file at the root. The secrets below are required:
```env
DB_PORT=5432
DB_HOST=postgres
DB_NAME=novaville_db
DB_USER=novaville_user
DB_PASSWORD=YOUR_SECURE_PASSWORD
DJANGO_SECRET_KEY=CHANGE_ME_TO_AT_LEAST_32_CHARS
JWT_SIGNING_KEY=CHANGE_ME_TO_AT_LEAST_32_CHARS
API_URL=http://localhost:8000
```

3. **Launch the application with Docker Compose**
```bash
# Build and start all services
docker compose up -d --build

# Check services status
docker compose ps

# Follow logs
docker compose logs -f
```

4. **Create a Django superuser** (if needed)
```bash
docker compose exec backend python manage.py createsuperuser
```

Or use the default credentials configured in `docker-compose.yml`:
- Username: `admin`
- Email: `admin@example.com`
- Password: `ChangeMe123`

5. **Access the application**

- **Frontend**: http://localhost:80
- **Backend API**: http://localhost:8000
- **API Documentation (Swagger)**: http://localhost:8000/api/docs/
- **Django Admin**: http://localhost:8000/admin/

6. **Stop the services**
```bash
docker compose down

# With volume removal (data deleted)
docker compose down --volumes
```

### GitHub Secrets (CI/CD)

If you deploy from GitHub Actions, add these secrets in the repository settings:

- `DJANGO_SECRET_KEY`
- `JWT_SIGNING_KEY`

Keep your existing Azure secrets (`AZURE_*`) as they are.

If you use the "Azure Cloud" GitHub Environment, store these secrets there and make sure the workflow targets that environment so the secrets are injected at deploy time.

---

## � Documentation

### Complete Documentation Site

A comprehensive documentation site built with **Docusaurus** is available, covering:

- **📘 Getting Started Guide** - Installation, configuration, and setup
- **🔧 Technical Documentation** - Architecture, backend, frontend, database
- **🌐 API Reference** - Complete REST API documentation with examples
- **📗 User Manual** - End-user guide for the application

#### Accessing the Documentation

- **Online**: `https://Michael16b.github.io/Novaville/` (after deployment)
- **Locally with npm**:
  ```bash
  cd docs
  npm install
  npm start
  # Visit http://localhost:3000
  ```
- **With Docker**:
  ```bash
  # From docs folder
  cd docs && docker-compose up -d
  
  # From project root with profile
  docker-compose --profile docs up -d
  
  # Visit http://localhost:3000
  ```

#### Multi-language Support

The documentation supports multiple languages:
- 🇫🇷 **French (fr)** - Default language
- 🇬🇧 **English (en)** - Configured (translations in progress)

Access different languages:
- French: `http://localhost:3000/`
- English: `http://localhost:3000/en/`

A language selector is available in the navigation bar.

#### Documentation Structure

```
docs/
├── getting-started/     # Installation & configuration guides
├── technical/          # Architecture & technical details
├── api/                # REST API endpoints reference
├── user-manual/        # End-user guides
└── blog/               # Release notes & updates
```

For more information, see:
- [DOCUMENTATION_GUIDE.md](DOCUMENTATION_GUIDE.md) - How to use and contribute to the documentation
- [DOCUMENTATION_STATUS.md](DOCUMENTATION_STATUS.md) - Current status and roadmap
- [docs/DOCKER_GUIDE.md](docs/DOCKER_GUIDE.md) - Docker deployment guide
- [docs/I18N_GUIDE.md](docs/I18N_GUIDE.md) - Multi-language translation guide
- [docs/TODO_DOCUMENTATION.md](docs/TODO_DOCUMENTATION.md) - Files to create

---

## �📚 Backend API Documentation

The interactive API documentation is automatically generated with **drf-spectacular** and accessible via Swagger UI.

### Accessing the Documentation

Once services are started:
- **Swagger UI** (interactive): http://localhost:8000/api/docs/
- **ReDoc** (read-only): http://localhost:8000/api/redoc/
- **OpenAPI JSON Schema**: http://localhost:8000/api/schema/

### Using Swagger UI

1. Go to http://localhost:8000/api/docs/
2. Explore available endpoints organized by tags
3. Test endpoints directly from the interface:
   - Click on an endpoint
   - Click "Try it out"
   - Fill in required parameters
   - Click "Execute"
4. For protected endpoints, authenticate:
   - Get a token via `/api/auth/token/`
   - Click "Authorize" at the top of the page
   - Enter: `Bearer <your_token>`

---

## 🎨 Flutter Frontend

### Architecture

The frontend uses the **BLoC** (Business Logic Component) architecture to separate business logic from the user interface:

```
lib/
├── main.dart                    # Application entry point
├── app/                         # Application configuration
├── config/                      # Configuration (routes, themes)
├── constants/                   # Global constants
├── core/                        # Cross-cutting features
├── design_systems/              # Design system (reusable widgets)
├── features/                    # Features by module
│   └── [feature]/
│       ├── data/               # Models and repositories
│       ├── domain/             # Business logic
│       └── presentation/       # UI (BLoC + Widgets)
└── ui/                         # Shared UI components
```

### Frontend-Only Development

If you want to work only on the frontend:

```bash
cd frontend

# Install dependencies
flutter pub get

# Run in development mode (hot reload)
flutter run -d chrome --web-port 3000

# Build for web
flutter build web
```

**Note**: Make sure the backend is running on http://localhost:8000

---

## 🔧 Development

### Project Structure

```
Novaville/
├── backend/                     # Django REST API
│   ├── api/                    # API entry points (v1)
│   ├── application/            # Application services
│   ├── config/                 # Django configuration
│   ├── core/                   # Database models
│   ├── domain/                 # Business logic
│   ├── infrastructure/         # Repositories
│   └── tests/                  # Unit and integration tests
├── frontend/                    # Flutter application
│   ├── lib/                    # Dart source code
│   └── web/                    # Web assets
├── api/                        # API tests (Bruno)
└── docker-compose.yml          # Services orchestration
```

### Useful Commands

#### Backend

```bash
# Access Django shell
docker compose exec backend python manage.py shell

# Create migrations
docker compose exec backend python manage.py makemigrations

# Apply migrations
docker compose exec backend python manage.py migrate

# Collect static files
docker compose exec backend python manage.py collectstatic --noinput

# Run tests
docker compose exec backend pytest

# Access container shell
docker compose exec backend bash
```

#### Database

```bash
# Access PostgreSQL shell
docker compose exec postgres psql -U novaville_user -d novaville_db

# Create a backup
docker compose exec postgres pg_dump -U novaville_user novaville_db > backup.sql

# Restore a backup
docker compose exec -T postgres psql -U novaville_user novaville_db < backup.sql
```

#### Frontend

```bash
# Rebuild frontend
docker compose up -d --build frontend

# Frontend logs
docker compose logs -f frontend
```

---

## 📦 Production Deployment

### Option 1: Standard Docker Deployment

Use the `docker-compose.yml` file on any VPS server (OVH, DigitalOcean, etc.)

**Steps:**

1. Install Docker and Docker Compose on the server
2. Clone the repository
3. Configure production environment variables:
   - Change `POSTGRES_PASSWORD` and `DB_PASSWORD`
   - Set a secure `DJANGO_SECRET_KEY`
   - Configure `ALLOWED_HOSTS` in Django
   - Set `DEBUG=False`
4. Start services:
```bash
docker compose -f docker-compose.yml up -d --build
```

### Option 2: Azure Deployment

See the detailed guide: [AZURE_DEPLOYMENT.md](AZURE_DEPLOYMENT.md)

**Two modes available:**
- **Azure Web App with containers**: simple deployment with `docker-compose-azure.yml`
- **Azure Database for PostgreSQL** (recommended): managed database, automatic backups, high availability

### Production Configuration

#### Backend

Essential environment variables:

```env
# Django
DEBUG=False
DJANGO_SECRET_KEY=<secure_secret_key>
ALLOWED_HOSTS=your-domain.com,www.your-domain.com

# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=novaville_db
DB_USER=novaville_user
DB_PASSWORD=<secure_password>

# Superuser (automatic creation)
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@novaville.fr
DJANGO_SUPERUSER_PASSWORD=<secure_admin_password>

# CORS (adjust according to your frontend domain)
CORS_ALLOWED_ORIGINS=https://your-domain.com
```

#### Frontend

Build frontend with production URL:

```bash
cd frontend
flutter build web --release --dart-define=API_URL=https://api.your-domain.com
```

---

## 🧪 Testing

### Backend Tests

```bash
# Run all tests
docker compose exec backend pytest

# Run with verbosity
docker compose exec backend pytest -v

# Run a specific test
docker compose exec backend pytest tests/test_auth.py

# With code coverage
docker compose exec backend pytest --cov=. --cov-report=html
```

### Frontend Tests

```bash
cd frontend

# Run all tests
flutter test

# Tests with coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

---

## 🔐 Security and GDPR

### Personal Data Management

The application collects and processes the following data:
- User identity (name, email)
- Report locations
- Survey responses

**Security measures:**
- JWT authentication with refresh tokens
- Hashed passwords (Django PBKDF2)
- HTTPS required in production
- Strictly configured CORS
- Network isolation of containers

### Sensitive Variables

⚠️ **Never commit secrets to Git**

Create a local `.env` file (added to `.gitignore`) for development.

In production, use:
- Server environment variables
- Azure Key Vault
- Kubernetes Secrets
- Equivalent solutions depending on your infrastructure

---

## 🗂️ Deployment Procedure for a New Client

### Customization Steps

1. **Clone the project**
```bash
git clone https://github.com/Michael16b/Novaville.git <your_city_name>
cd <your_city_name>
```

2. **Customize branding**
   - Logo: replace `frontend/assets/images/logo.png`
   - Application name: modify `frontend/pubspec.yaml`
   - Slogan: configure in application settings
   - Colors: adjust `frontend/lib/config/theme.dart`

3. **Configure the database**
   - Modify credentials in `docker-compose.yml`
   - Or use an external database

4. **Configure environment variables**
```env
# .env
DB_NAME=newcity_db
DB_USER=newcity_user
DB_PASSWORD=<secure_password>
DJANGO_SECRET_KEY=<unique_secret_key>
```

5. **Build and deploy**
```bash
docker compose up -d --build
```

6. **Initialize data**
```bash
# Create an administrator
docker compose exec backend python manage.py createsuperuser

# (Optional) Load demo data
docker compose exec backend python manage.py loaddata initial_data.json
```

7. **Configure domain name**
   - Point DNS to your server
   - Configure a reverse proxy (nginx/Apache) with SSL/TLS
   - Update `ALLOWED_HOSTS` in Django

---

## 📖 Developer Guide

### First Launch

1. **Start the development environment**
```bash
docker compose up -d --build
```

2. **Verify everything works**
   - Backend: http://localhost:8000
   - Frontend: http://localhost:80
   - API Docs: http://localhost:8000/api/docs/

3. **Access the API documentation**

The interactive Swagger documentation is available at:
👉 **http://localhost:8000/api/docs/**

This interface allows you to:
- Discover all available endpoints
- View request and response schemas
- Test endpoints directly from the browser
- Download the OpenAPI schema

### Modifying the Homepage UI

**Example: Change theme colors**

1. Open `frontend/lib/config/theme.dart`
2. Modify the theme colors:
```dart
primaryColor: Color(0xFF2196F3),  // Blue
accentColor: Color(0xFF4CAF50),   // Green
```

3. Automatic hot reload (if `flutter run` is active)
   Otherwise, rebuild the frontend:
```bash
cd frontend
flutter build web
# Or rebuild the container
docker compose up -d --build frontend
```

**Example: Modify homepage text**

1. Open `frontend/lib/features/home/presentation/pages/home_page.dart`
2. Modify the desired text
3. Reload the application

### Adding a New API Endpoint

1. **Create the model** in `backend/core/db/models.py`
```python
class NewModel(models.Model):
    name = models.CharField(max_length=255)
    # ...
```

2. **Create a serializer** in `backend/api/v1/serializers/`
```python
from rest_framework import serializers

class NewModelSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewModel
        fields = '__all__'
```

3. **Create a viewset** in `backend/api/v1/viewsets/`
```python
from rest_framework import viewsets

class NewModelViewSet(viewsets.ModelViewSet):
    queryset = NewModel.objects.all()
    serializer_class = NewModelSerializer
```

4. **Register the URL** in `backend/api/v1/urls.py`
```python
router.register(r'new-models', NewModelViewSet)
```

5. **Create and apply migrations**
```bash
docker compose exec backend python manage.py makemigrations
docker compose exec backend python manage.py migrate
```

6. **Check in documentation**: http://localhost:8000/api/docs/

---

## 📱 Frontend Operation

### Data Flow - BLoC Architecture

```
User Interaction → Widget → Event → BLoC → Repository → API
                                      ↓
                              State → Widget Update
```

### Example: Authentication

1. **User clicks "Login"**
2. The widget emits a `LoginRequested` event
3. The **BLoC** (`AuthBloc`) processes the event
4. The **repository** (`AuthRepository`) calls the backend API
5. The BLoC emits a new state (`AuthSuccess` or `AuthFailure`)
6. The widget rebuilds with the new state

### Adding a New Feature

1. **Create folder structure**
```bash
cd frontend/lib/features
mkdir -p new_feature/{data,domain,presentation}/{models,repositories,blocs,pages,widgets}
```

2. **Create data models** (`data/models/`)
3. **Create repository** (`data/repositories/`)
4. **Create BLoC** (`presentation/blocs/`)
5. **Create pages and widgets** (`presentation/pages/` and `presentation/widgets/`)
6. **Register dependencies** in the service locator (GetIt)

### API Configuration

The backend API URL is configured in:
- **Development**: `frontend/.env` → `API_URL=http://localhost:8000`
- **Production**: build argument `--dart-define=API_URL=https://api.production.com`

---

## 🧰 Development Tools

### API Testing with Bruno

The `api/Novaville/` folder contains a Bruno collection to test endpoints:

```bash
# Install Bruno: https://www.usebruno.com/

# Open the collection
bruno open api/Novaville/
```

Available environments:
- **local**: http://localhost:8000
- **azure**: Azure production URL

### Database

In development, PostgreSQL is accessible on `localhost:5432`:

```bash
# Connect via psql
psql -h localhost -U novaville_user -d novaville_db

# Or via a graphical client (DBeaver, pgAdmin)
Host: localhost
Port: 5432
Database: novaville_db
User: novaville_user
Password: YOUR_SECURE_PASSWORD
```

---

## 📋 Project Deliverables

In accordance with the specifications, this project includes:

- ✅ **Source code** of the application (backend + frontend)
- ✅ **Internal documentation** for development handover (this README)
- ✅ **Installation procedure** for the development environment
- ✅ **Modification guide** with examples (see "Developer Guide" section)
- ✅ **Deployment procedure** for a new client
- 📝 **User manual** (to be completed in `docs/user_manual.md`)
- 📝 **Application presentation** (to be created: brochure/video)
- 📝 **Project logbook** (to be maintained in `docs/project_logbook.md`)
- 📝 **Test plan** (to be completed in `docs/test_plan.md`)

---

## 🐛 Troubleshooting

### Backend Won't Start

```bash
# Check logs
docker compose logs backend

# Check that PostgreSQL is ready
docker compose logs postgres

# Recreate containers
docker compose down --volumes
docker compose up -d --build
```

### CORS Error on Frontend

Check CORS configuration in `backend/config/settings.py`:
```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost",
    "http://localhost:80",
    "http://localhost:3000",
]
```

See also: [CORS_FIX.md](CORS_FIX.md)

### Frontend Cannot Connect to Backend

1. Check API URL in `frontend/.env`
2. Verify backend is accessible: http://localhost:8000
3. Check browser logs (F12 → Console)

### Network Issues Between Containers

See: [NETWORKING_FIX.md](NETWORKING_FIX.md)

---

## 🤝 Contributing

### Git Workflow

```bash
# Create a branch for your feature
git checkout -b feature/feature-name

# Make your changes
git add .
git commit -m "Clear description of the change"

# Push the branch
git push origin feature/feature-name

# Create a Pull Request
```

### Code Standards

#### Backend (Python)
- PEP 8
- Docstrings for public functions
- Type hints recommended

#### Frontend (Dart/Flutter)
- Official Dart conventions
- Static analysis: `flutter analyze`
- Formatting: `flutter format .`

---

## 📞 Support

For any questions about the project:

**Instructor:** Nicolas MERCEREAU  
**Email:** nicolas.mercereau3@gmail.com

**Development Team:** BESILY Michaël, CRONIER Romain, JAN Charlène

---

## 📄 License

See [LICENSE](LICENSE)

---

## 🏆 TALENTIA Team

Project completed as part of Master 2 MIAGE 2026  
Module: "Development Process"

---

**Last updated**: February 2026