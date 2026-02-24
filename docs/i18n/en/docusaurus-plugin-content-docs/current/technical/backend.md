---
sidebar_position: 2
---

# Backend (Django)

Documentation technique du backend Novaville.

## Vue d'ensemble

Le backend est construit avec **Django 4.x** et **Django REST Framework** pour fournir une API REST complète.

## Technologies

- **Framework** : Django 4.2+
- **API** : Django REST Framework 3.14+
- **Base de données** : PostgreSQL 14+
- **Authentification** : JWT (djangorestframework-simplejwt)
- **CORS** : django-cors-headers
- **Tests** : pytest + pytest-django

## Structure du projet

```
backend/
├── manage.py                # Script de gestion Django
├── requirements.txt         # Dépendances Python
├── pytest.ini              # Configuration pytest
├── Dockerfile              # Image Docker
├── config/                 # Configuration Django
│   ├── settings.py        # Settings principal
│   ├── urls.py            # URLs racine
│   ├── middleware.py      # Middlewares personnalisés
│   ├── wsgi.py            # WSGI config
│   └── asgi.py            # ASGI config
├── core/                   # Application core
│   ├── models.py          # Modèles métier
│   ├── admin.py           # Admin Django
│   └── db/                # Organisation DB
│       ├── models/        # Modèles par domaine
│       └── enums/         # Énumérations
├── api/                    # API REST
│   └── v1/
│       ├── urls.py
│       ├── auth.py        # Endpoints d'auth
│       ├── permissions.py # Permissions customisées
│       ├── serializers/   # Serializers DRF
│       └── viewsets/      # ViewSets DRF
├── application/            # Logique métier
│   └── services/          # Services métier
├── domain/                 # Entités du domaine
├── infrastructure/         # Infrastructure
│   └── repositories/      # Repositories
└── tests/                  # Tests
    ├── conftest.py        # Fixtures pytest
    ├── test_api_*.py      # Tests API
    └── fixtures/          # Données de test
```

## Modèles de données

### User

Modèle utilisateur personnalisé basé sur `AbstractUser`.

```python
class User(AbstractUser):
    email = models.EmailField(unique=True)
    role = models.CharField(
        max_length=20,
        choices=UserRole.choices,
        default=UserRole.CITIZEN
    )
    phone_number = models.CharField(max_length=20, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

### Report

Signalements citoyens.

```python
class Report(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    category = models.ForeignKey(Category, on_delete=models.PROTECT)
    status = models.CharField(
        max_length=20,
        choices=ReportStatus.choices,
        default=ReportStatus.PENDING
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    address = models.CharField(max_length=255, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

### Event

Événements citoyens.

```python
class Event(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True)
    max_participants = models.IntegerField(null=True, blank=True)
    organizer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='organized_events')
    participants = models.ManyToManyField(User, through='EventParticipant', related_name='events')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

## API REST

### Serializers

Les serializers DRF transforment les modèles en JSON et vice-versa.

```python
class ReportSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = Report
        fields = ['id', 'title', 'description', 'category', 'category_name', 
                  'status', 'latitude', 'longitude', 'address', 'author', 
                  'created_at', 'updated_at']
        read_only_fields = ['id', 'author', 'created_at', 'updated_at']
```

### ViewSets

Les ViewSets gèrent les opérations CRUD.

```python
class ReportViewSet(viewsets.ModelViewSet):
    queryset = Report.objects.select_related('author', 'category').all()
    serializer_class = ReportSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filterset_fields = ['status', 'category']
    search_fields = ['title', 'description', 'address']
    ordering_fields = ['created_at', 'updated_at']
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
```

### Permissions

Permissions personnalisées pour contrôler l'accès.

```python
class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.author == request.user
```

## Services métier

Architecture en couches avec des services pour la logique métier complexe.

```python
class ReportService:
    @staticmethod
    def create_report(user, data):
        """Crée un rapport avec validation et notifications"""
        report = Report.objects.create(
            author=user,
            **data
        )
        
        # Géocodage inverse si nécessaire
        if not report.address and report.latitude and report.longitude:
            report.address = GeocodingService.reverse_geocode(
                report.latitude, 
                report.longitude
            )
            report.save()
        
        # Notification aux administrateurs
        NotificationService.notify_admins_new_report(report)
        
        return report
```

## Tests

### Configuration pytest

```python
# conftest.py
import pytest
from rest_framework.test import APIClient
from core.models import User

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def user(db):
    return User.objects.create_user(
        email='test@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User'
    )

@pytest.fixture
def authenticated_client(api_client, user):
    api_client.force_authenticate(user=user)
    return api_client
```

### Tests d'API

```python
# test_api_reports.py
import pytest
from rest_framework import status

@pytest.mark.django_db
class TestReportAPI:
    def test_list_reports(self, api_client):
        response = api_client.get('/api/v1/reports/')
        assert response.status_code == status.HTTP_200_OK
    
    def test_create_report_authenticated(self, authenticated_client):
        data = {
            'title': 'Nid-de-poule',
            'description': 'Grand trou sur la route',
            'category': 1,
            'latitude': 48.8566,
            'longitude': 2.3522
        }
        response = authenticated_client.post('/api/v1/reports/', data)
        assert response.status_code == status.HTTP_201_CREATED
```

## Commandes de gestion

Django permet de créer des commandes personnalisées.

```python
# management/commands/send_daily_summary.py
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = 'Envoie le résumé quotidien aux administrateurs'
    
    def handle(self, *args, **options):
        # Logique de la commande
        self.stdout.write(self.style.SUCCESS('Résumé envoyé'))
```

Utilisation :

```bash
python manage.py send_daily_summary
```

## Performance

### Optimisation des requêtes

```python
# Mauvais : N+1 queries
reports = Report.objects.all()
for report in reports:
    print(report.author.name)  # Query pour chaque report

# Bon : 2 queries total
reports = Report.objects.select_related('author').all()
for report in reports:
    print(report.author.name)
```

### Cache

```python
from django.core.cache import cache

def get_public_events():
    events = cache.get('public_events')
    if events is None:
        events = Event.objects.filter(is_public=True).all()
        cache.set('public_events', events, 3600)  # 1 heure
    return events
```

### Index de base de données

```python
class Report(models.Model):
    # ...
    
    class Meta:
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['author', '-created_at']),
        ]
```

## Sécurité

### Validation des entrées

```python
class ReportSerializer(serializers.ModelSerializer):
    def validate_latitude(self, value):
        if not -90 <= value <= 90:
            raise serializers.ValidationError("Latitude invalide")
        return value
```

### Rate Limiting

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour'
    }
}
```

## Déploiement

### Variables d'environnement

```python
# settings.py
import os
from pathlib import Path

SECRET_KEY = os.getenv('SECRET_KEY')
DEBUG = os.getenv('DEBUG', 'False') == 'True'
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '').split(',')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('POSTGRES_DB'),
        'USER': os.getenv('POSTGRES_USER'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD'),
        'HOST': os.getenv('POSTGRES_HOST', 'localhost'),
        'PORT': os.getenv('POSTGRES_PORT', '5432'),
    }
}
```

### Migrations

```bash
# Créer une migration
python manage.py makemigrations

# Appliquer les migrations
python manage.py migrate

# Voir l'état des migrations
python manage.py showmigrations
```

## Ressources

- [Documentation Django](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Guide de sécurité Django](https://docs.djangoproject.com/en/stable/topics/security/)
