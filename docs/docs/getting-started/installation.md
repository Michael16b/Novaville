---
sidebar_position: 2
---

# Installation

Ce guide vous accompagnera dans l'installation et la configuration de l'environnement de développement Novaville.

## Installation avec Docker (Recommandé)

La méthode la plus simple est d'utiliser Docker Compose :

### 1. Cloner le dépôt

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/Novaville.git
cd Novaville
```

### 2. Configurer les variables d'environnement

```bash
cp .env.example .env
```

Éditez le fichier `.env` et configurez les variables nécessaires :

```env
# Base de données
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

### 3. Lancer les services

```bash
docker-compose up -d
```

### 4. Appliquer les migrations

```bash
docker-compose exec backend python manage.py migrate
```

### 5. Créer un superutilisateur

```bash
docker-compose exec backend python manage.py createsuperuser
```

### 6. Accéder à l'application

- **Backend API** : http://localhost:8000
- **Admin Django** : http://localhost:8000/admin
- **Frontend** : http://localhost:3000 (si configuré)

## Installation manuelle

### Backend

#### 1. Créer un environnement virtuel

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
```

#### 2. Installer les dépendances

```bash
pip install -r requirements.txt
```

#### 3. Configurer la base de données

Créez une base PostgreSQL et configurez les variables d'environnement.

#### 4. Appliquer les migrations

```bash
python manage.py migrate
```

#### 5. Lancer le serveur de développement

```bash
python manage.py runserver
```

### Frontend

#### 1. Installer les dépendances Flutter

```bash
cd frontend
flutter pub get
```

#### 2. Configurer l'URL de l'API

Éditez `lib/config/environment.dart` :

```dart
class Environment {
  static const String apiUrl = 'http://localhost:8000';
}
```

#### 3. Lancer l'application

```bash
# Pour Android
flutter run

# Pour iOS
flutter run -d ios

# Pour Web
flutter run -d chrome
```

## Vérification de l'installation

Une fois l'installation terminée, vérifiez que tout fonctionne :

1. Accédez à http://localhost:8000/api/ - vous devriez voir la page d'accueil de l'API
2. Accédez à http://localhost:8000/admin - vous devriez pouvoir vous connecter
3. Testez l'API avec :

```bash
curl http://localhost:8000/api/health/
```

## Problèmes courants

### Port déjà utilisé

Si le port 8000 est déjà utilisé :

```bash
# Modifier le port dans docker-compose.yml ou
python manage.py runserver 8080
```

### Erreur de connexion à la base de données

Vérifiez que PostgreSQL est bien démarré et que les identifiants sont corrects.

### Problèmes avec Flutter

Assurez-vous d'avoir la dernière version du SDK :

```bash
flutter upgrade
flutter doctor
```

## Prochaines étapes

Continuez avec le guide de [Configuration](./configuration) pour personnaliser votre environnement.
