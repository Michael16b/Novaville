---
sidebar_position: 2
---

# Déploiement local

Ce document explique comment déployer et lancer Novaville complètement en local sur votre machine, avec Docker Compose.

## Prérequis

- **Docker Desktop** (ou Docker + Docker Compose)
  - Windows : [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - macOS : [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Linux : [Docker](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/install/)
- **Git** : pour cloner le dépôt
- **Minimum 4 Go de RAM** disponible (Docker)
- **Port 8000, 80, 5432 libres** sur votre machine

Vérifiez l'installation :

```bash
docker --version
docker compose version
```

---

## 1. Cloner et préparer le projet

```bash
# Cloner le dépôt
git clone https://github.com/Michael16b/Novaville.git
cd Novaville

# Copier le fichier d'environnement
cp .env.example .env

# (Optionnel) Adapter .env si vous avez des configurations personnalisées
# Les valeurs par défaut conviennent pour le développement local
```

**Contenu du `.env` minimal pour le développement** :

```bash
# Django
DEBUG=True
DJANGO_SECRET_KEY=local-development-key-not-for-production
JWT_SIGNING_KEY=local-jwt-key-not-for-production

# Base de données
DB_ENGINE=django.db.backends.postgresql
DB_NAME=novaville
DB_USER=novaville_user
DB_PASSWORD=novaville_password
DB_HOST=postgres
DB_PORT=5432

# Superuser Django
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@localhost
DJANGO_SUPERUSER_PASSWORD=admin123

# API Frontend
API_URL=http://localhost:8000
```

---

## 2. Démarrer les services avec Docker Compose

### Démarrage complet (tous les services)

```bash
# Démarrer tous les services en arrière-plan
docker compose up -d --build
```

**Cela démarre :**
- ✅ PostgreSQL (base de données)
- ✅ Backend Django (API REST)
- ✅ Frontend Flutter (web)
- ✅ Nginx (reverse proxy)

**Attendez 10-15 secondes** le temps que les services démarrent et que les migrations s'exécutent.

### Alternative : démarrage en mode verbose (voir les logs)

```bash
# Démarrer sans détacher (-d) pour voir les logs en temps réel
docker compose up --build
```

Appuyez sur `Ctrl+C` pour arrêter (les conteneurs s'arrêtent aussi).

---

## 3. Vérifier que tout fonctionne

### Vérifier l'état des services

```bash
# Voir les conteneurs en cours d'exécution
docker compose ps
```

Vous devriez voir :
```
CONTAINER ID   IMAGE                        STATUS
xxxxx          novaville-backend:latest     Up 2 minutes
xxxxx          novaville-frontend:latest    Up 2 minutes
xxxxx          bitnami-postgresql:15        Up 2 minutes
```

### Tester l'accès aux services

**Frontend (Flutter Web)** :
```
http://localhost:80
```

**Backend API** :
```
http://localhost:8000/api/
```

**Swagger/OpenAPI** (documentation interactive) :
```
http://localhost:8000/api/docs/
```

**Django Admin** :
```
http://localhost:8000/admin/
```
- Username : `admin`
- Password : `admin123`

---

## 4. Exécuter les migrations et initialiser les données

Les migrations s'exécutent **automatiquement** au démarrage (si `MIGRATE=1` dans `.env`).

Vérifier manuellement :

```bash
# Vérifier l'état des migrations
docker compose exec backend python manage.py showmigrations

# Exécuter les migrations si besoin
docker compose exec backend python manage.py migrate

# Créer un superuser si besoin
docker compose exec backend python manage.py createsuperuser
```

---

## 5. Exécuter les tests en local

### Backend (Django/Python)

```bash
# Exécuter tous les tests
docker compose exec backend pytest

# Exécuter un fichier de test spécifique
docker compose exec backend pytest tests/test_auth.py -v

# Exécuter avec couverture de code
docker compose exec backend pytest --cov=. --cov-report=html
```

### Frontend (Flutter/Dart)

```bash
# Accéder au répertoire frontend
cd frontend

# Lancer les tests unitaires
flutter test

# Lancer l'application en mode développement (web)
flutter run -d chrome --web-port 3000
```

---

## 6. Développement avec rechargement automatique

### Backend Django

```bash
# Le serveur Django se recharge automatiquement lors des modifications de code
# Il est accessible à http://localhost:8000
```

### Frontend Flutter

Pour le développement actif du frontend, utilisez le **hot reload** de Flutter :

```bash
cd frontend

# Lancer en mode développement sur Chrome
flutter run -d chrome --web-port 3000

# Appuyez sur 'r' dans le terminal pour hot reload
# Appuyez sur 'q' pour arrêter
```

---

## 7. Accéder aux logs des services

### Tous les services

```bash
# Voir les logs de tous les services
docker compose logs -f

# Voir les 50 dernières lignes
docker compose logs --tail 50
```

### Service spécifique

```bash
# Logs du backend
docker compose logs -f backend

# Logs de la base de données
docker compose logs -f postgres

# Logs du frontend
docker compose logs -f frontend
```

Appuyez sur `Ctrl+C` pour arrêter de suivre les logs.

---

## 8. Modifier le code et voir les changements

### Backend (Django)

```bash
# 1. Modifier un fichier dans backend/
# 2. Les changements sont détectés automatiquement
# 3. Rafraîchir http://localhost:8000 pour voir les changements
```

### Frontend (Flutter)

```bash
# 1. Modifier un fichier dans frontend/lib/
# 2. Appuyer sur 'r' dans le terminal Flutter pour hot reload
# 3. Voir les changements immédiatement dans le navigateur
```

### Base de données (modifications de modèles)

```bash
# 1. Modifier un modèle dans backend/core/models.py
# 2. Créer une migration
docker compose exec backend python manage.py makemigrations

# 3. Appliquer la migration
docker compose exec backend python manage.py migrate

# 4. Rafraîchir l'API
```

---

## 9. Arrêter les services

### Arrêter les services (en gardant les données)

```bash
# Arrêter tous les conteneurs
docker compose stop
```

### Arrêter et supprimer les conteneurs

```bash
# Arrêter et supprimer les conteneurs (les données persistent dans les volumes)
docker compose down
```

### Nettoyer complètement (attention : supprime les données)

```bash
# Arrêter, supprimer conteneurs, réseaux, et volumes
docker compose down -v
```

---

## 10. Dépannage courant

### Erreur : "Port 8000 is already in use"

```bash
# Trouver le processus utilisant le port 8000
lsof -i :8000

# Tuer le processus (sur Windows, utiliser le Task Manager)
kill -9 <PID>

# Ou changer le port dans docker-compose.yml
```

### Erreur : "PostgreSQL connection refused"

```bash
# Vérifier que le conteneur PostgreSQL est en cours d'exécution
docker compose ps postgres

# Redémarrer PostgreSQL
docker compose restart postgres

# Vérifier les logs
docker compose logs postgres
```

### Erreur : "Database does not exist"

```bash
# Supprimer le volume de la base de données et redémarrer
docker compose down -v
docker compose up -d --build
```

### Erreur : "Module not found" (Python)

```bash
# Réinstaller les dépendances Python
docker compose exec backend pip install -r requirements.txt

# Ou reconstruire l'image backend
docker compose build --no-cache backend
```

### Frontend blanc/ne charge pas

```bash
# Vider le cache du navigateur (Ctrl+Shift+Delete)
# Ou ouvrir en mode incognito

# Vérifier les logs du frontend
docker compose logs frontend

# Redémarrer le conteneur frontend
docker compose restart frontend
```

---

## 11. Accès à la base de données

### Accéder à PostgreSQL directement

```bash
# Se connecter au terminal PostgreSQL
docker compose exec postgres psql -U novaville_user -d novaville

# Quelques commandes PostgreSQL utiles
\dt                    # Lister toutes les tables
\d table_name          # Afficher la structure d'une table
SELECT * FROM table;   # Requête SQL
\q                     # Quitter
```

### Via pgAdmin (interface web)

Vous pouvez ajouter un service pgAdmin au `docker-compose.yml` pour gérer PostgreSQL via une interface web :

```yaml
pgadmin:
  image: dpage/pgadmin4:latest
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@localhost
    PGADMIN_DEFAULT_PASSWORD: admin
  ports:
    - "5050:80"
```

Puis accéder à `http://localhost:5050`.

---

## 12. Ressources pratiques

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | `http://localhost:80` | N/A |
| Backend API | `http://localhost:8000/api/` | N/A |
| Swagger/OpenAPI | `http://localhost:8000/api/docs/` | N/A |
| Django Admin | `http://localhost:8000/admin/` | admin / admin123 |
| PostgreSQL | `localhost:5432` | novaville_user / novaville_password |

---

## Voir aussi

- [Developer Onboarding](../dev-onboarding.md) — Installation de Flutter et Docker
- [Internal Guides](./internal-guides.md) — Procédures pour équipe
- [Azure Deployment](./azure-deployment.md) — Déploiement en production
