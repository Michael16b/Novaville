---
sidebar_position: 2
---

# Installation

This guide walks you through installing and configuring the Novaville development environment.

## Install with Docker (Recommended)

The simplest path is via Docker Compose:

### 1. Clone the repo

```bash
git clone https://github.com/Michael16b/Novaville.git
cd Novaville
```

### 2. Set environment variables

```bash
cp .env.example .env
```

Edit `.env` and set the required variables:

```env
# Database
POSTGRES_DB=novaville
POSTGRES_USER=novaville
POSTGRES_PASSWORD=your_secure_password

# Django
SECRET_KEY=your_secret_key_here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Frontend
API_URL=http://localhost:8000
```

### 3. Start services

```bash
docker-compose up -d
```

### 4. Run migrations

```bash
docker-compose exec backend python manage.py migrate
```

### 5. Create a superuser

```bash
docker-compose exec backend python manage.py createsuperuser
```

### 6. Access the app

- **Backend API**: http://localhost:8000
- **Django Admin**: http://localhost:8000/admin
- **Frontend**: http://localhost:3000 (if enabled)

## Manual install

### Backend

#### 1. Create a virtualenv

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
```

#### 2. Install dependencies

```bash
pip install -r requirements.txt
```

#### 3. Configure the database

Create a PostgreSQL database and set your env variables.

#### 4. Run migrations

```bash
python manage.py migrate
```

#### 5. Start the dev server

```bash
python manage.py runserver
```

### Frontend

#### 1. Install Flutter dependencies

```bash
cd frontend
flutter pub get
```

#### 2. Set the API URL

Edit `lib/config/environment.dart`:

```dart
class Environment {
  static const String apiUrl = 'http://localhost:8000';
}
```

#### 3. Run the app

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## Verify the install

After install, verify everything works:

1. Go to http://localhost:8000/api/ — API landing should load
2. Go to http://localhost:8000/admin — you should be able to sign in
3. Test the API:

```bash
curl http://localhost:8000/api/health/
```

## Common issues

### Port already in use

If port 8000 is taken:

```bash
# Modifier le port dans docker-compose.yml ou
python manage.py runserver 8080
```

### Database connection error

Ensure PostgreSQL is running and credentials are correct.

### Flutter issues

Make sure you have the latest SDK:

```bash
flutter upgrade
flutter doctor
```

## Next steps

Continue with [Configuration](./configuration) to tailor your environment.
