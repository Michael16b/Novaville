# Backend Django - skeleton

Structure générée automatiquement. Remplacez `project_name` par le nom réel et complétez les fichiers `config/settings.py`, `manage.py`, etc.

## Lancer le projet en Docker (développement)

Pré-requis:
- Docker & Docker Compose

1) Construire et démarrer les services (backend + postgres + frontend):

```powershell
# depuis la racine du repo (où est docker-compose.yml)
docker compose up -d --build
```

2) Vérifier les logs et l'état des services:

```powershell
docker compose ps
docker compose logs -f backend
docker compose logs -f postgres
```

3) Créer un superuser Django (interactif):

```powershell
docker compose exec backend python manage.py createsuperuser
```

4) (Optionnel) Créer automatiquement un superuser au démarrage (dev uniquement):

Dans `docker-compose.yml`, ou en export d'environnement, définir:

- `DJANGO_CREATE_SUPERUSER=1`
- `DJANGO_ADMIN_USER` (ex: admin)
- `DJANGO_ADMIN_EMAIL` (ex: admin@example.com)
- `DJANGO_ADMIN_PASSWORD` (ex: ChangeMe123)

L'entrypoint détectera ces variables et créera le superuser si absent.

Voici un exemple en PowerShell (à faire après lancement des services):

```powershell
docker compose exec backend python manage.py shell -c "from django.contrib.auth import get_user_model; U=get_user_model(); U.objects.create_superuser('admin','admin@example.com','ChangeMe123')"
```

5) Accéder à l'admin Django:

Ouvre http://localhost:8000/admin/ et connecte-toi avec le superuser.

6) Stopper les services:

```powershell
docker compose down --volumes
```

Notes:
- Les identifiants par défaut utilisés dans les exemples sont uniquement pour le développement.
- En production, utilise des secrets sécurisés et ne publie pas le port Postgres sur l'hôte.

## Modes : développement vs production

Ce projet supporte deux modes de fonctionnement :

- Développement (mode par défaut)
	- Conçu pour le dev local avec accès rapide : `ENABLE_ADMIN=1`, création automatique ou manuelle d'un superuser, port Postgres éventuellement exposé pour outils locaux.
	- Commande typique :

	```powershell
	docker compose up -d --build
	```

	- Variables utiles (dev) :
		- `DJANGO_CREATE_SUPERUSER=1` pour créer automatiquement un superuser (idempotent)
		- `DJANGO_ADMIN_USER`, `DJANGO_ADMIN_EMAIL`, `DJANGO_ADMIN_PASSWORD`
		- `ENABLE_ADMIN=1` (par défaut)
		- `ADMIN_ALLOWED_IPS` (optionnel pour restreindre l'accès en dev)

- Production (mode sécurisé)
	- Ne pas exposer l'admin publiquement et ne pas mapper le port Postgres sur l'hôte.
	- Définir `ENABLE_ADMIN=0` pour **ne pas** inclure les routes `/admin/` dans `urls.py`.
	- Gérer les secrets via un secret manager ou variables d'environnement non commitées (`DJANGO_SECRET_KEY`, `DATABASE_URL`, etc.).
	- Exemple d'actions à faire en prod :
		- Définir `ENABLE_ADMIN=0` dans l'environnement de déploiement.
		- Placer l'admin derrière un VPN / auth proxy si une interface d'administration est nécessaire pour les opérateurs.
		- Ne pas exposer le port Postgres (supprimer `ports: - "5432:5432"` pour le service `postgres`).
		- Mettre `DEBUG=False`, renseigner `ALLOWED_HOSTS` correctement.

### Exemple : override compose pour le développement
Créez un fichier `docker-compose.override.yml` (non commité) contenant par exemple :

```yaml
services:
	backend:
		environment:
			- DJANGO_CREATE_SUPERUSER=1
			- DJANGO_ADMIN_USER=admin
			- DJANGO_ADMIN_EMAIL=admin@example.com
			- DJANGO_ADMIN_PASSWORD=ChangeMe123
			- ENABLE_ADMIN=1
	postgres:
		ports:
			- "5432:5432" # seulement en dev

```

Pour lancer avec cet override (docker compose le charge automatiquement) :

```powershell
docker compose up -d --build
```

### Exemple : variables d'environnement pour la production
Stockez les variables sensibles dans votre système de secrets et veillez à ne pas exposer l'admin.

Variables importantes : `DJANGO_SECRET_KEY`, `DATABASE_URL` (ou `DB_HOST/DB_USER/DB_PASSWORD`), `ENABLE_ADMIN=0`, `DJANGO_DEBUG=False`, `ALLOWED_HOSTS`.

---

Si tu veux, je peux ajouter un `docker-compose.override.yml.example` et un `.env.example` dans le repo pour faciliter la mise en place locale. Veux-tu que je les crée ?

## Documentation API (OpenAPI / Swagger)

Nous utilisons `drf-spectacular` pour générer automatiquement un schéma OpenAPI et exposer une interface Swagger.

- Schéma OpenAPI (JSON) : `GET /api/schema/`
- Swagger UI (navigateur interactif) : `GET /api/docs/`

Ces routes sont activées si `drf-spectacular` est installé (inclus dans `requirements.txt`). Si tu préfères restreindre l'accès à la doc en prod, tu peux positionner ces routes derrière un proxy ou conditionner leur activation via une variable d'environnement.

Exemple pour tester localement:

```powershell
curl http://localhost:8000/api/schema/ | jq .
start http://localhost:8000/api/docs/
```

URLs utiles pour la documentation OpenAPI/Swagger:

- Schema JSON OpenAPI : `http://localhost:8000/api/schema/`
- Swagger UI interactive : `http://localhost:8000/api/docs/`

Ces routes sont exposées uniquement si `ENABLE_API_DOCS` est activé (par défaut en dev). En production vous pouvez définir `ENABLE_API_DOCS=0` pour ne pas publier la documentation publique.

## Déploiement Azure

### 📘 Guide Complet de Déploiement

Consultez **[AZURE_DEPLOYMENT.md](../AZURE_DEPLOYMENT.md)** à la racine du projet pour un guide détaillé des options de déploiement:

- **Option 1**: Azure Web App avec conteneurs multi-containers (PostgreSQL + Backend conteneurisés)
- **Option 2**: Azure Database for PostgreSQL (service géré) + Backend conteneurisé ✅ **Recommandé**

Le guide inclut:
- Instructions pas-à-pas pour chaque option
- Configuration des variables d'environnement
- Règles de firewall et sécurité
- Dépannage et vérification

### Résumé Rapide - Option 2 (Recommandé)

Si vous utilisez **Azure Database for PostgreSQL** (service géré):

1. Utilisez `docker-compose-azure-managed-db.yml` au lieu de `docker-compose-azure.yml`
2. Configurez ces variables dans Azure App Service Configuration:
   ```
   DB_HOST=novavillesql.postgres.database.azure.com
   DB_PORT=5432
   DB_NAME=novavilledb
   DB_USER=novaville_admin@novavillesql
   DB_PASSWORD=votre_mot_de_passe
   DJANGO_SECRET_KEY=votre_cle_secrete
   ```

### Mécanismes de Résilience

Le déploiement inclut des protections multi-niveaux contre les erreurs de connexion:

1. **Script de retry `wait_for_db.py`**: Tente de se connecter avec des retries configurables (60 tentatives × 3s par défaut pour Azure)
2. **Restart policy**: Le service redémarre automatiquement en cas d'échec
3. **Logging détaillé**: Pour faciliter le debugging des problèmes de connexion

## Authentification JWT (login)

Nous utilisons `djangorestframework-simplejwt` pour l'authentification par JWT. Endpoints disponibles :

- Obtenir tokens + info utilisateur : `POST /api/v1/auth/token/` (body: `username`, `password`)
- Rafraîchir le token d'accès : `POST /api/v1/auth/token/refresh/` (body: `refresh`)

Exemple `curl` pour obtenir un token :

```powershell
curl -X POST http://localhost:8000/api/v1/auth/token/ -H "Content-Type: application/json" -d '{"username":"admin","password":"ChangeMe123"}' | jq .
```

Réponse typique :

```json
{
	"refresh": "<refresh_token>",
	"access": "<access_token>",
	"user": {
		"id": 1,
		"username": "admin",
		"email": "admin@example.com",
		"first_name": "",
		"last_name": ""
	}
}
```

Utilisation du token pour appeler une API protégée :

```powershell
curl -H "Authorization: Bearer <access_token>" http://localhost:8000/api/v1/items/
```

Exemple de rafraîchissement :

```powershell
curl -X POST http://localhost:8000/api/v1/auth/token/refresh/ -H "Content-Type: application/json" -d '{"refresh":"<refresh_token>"}' | jq .
```

Si tu veux, je peux aussi :
- Ajouter une route `me/` qui retourne les informations de l'utilisateur connecté.
- Ajouter des tests d'intégration pour l'auth (tokens, accès aux endpoints protégés).
