---
sidebar_position: 4
---

# Déploiement sur Azure

Ce document explique comment configurer le déploiement automatique de Novaville sur Azure via GitHub Actions.

## Architecture de déploiement

Le workflow CI/CD (`.github/workflows/deploy_docker_azure.yml`) :

1. **Exécute les tests pré-déploiement** (Django, migrations, admin)
2. **Construit les images Docker** (backend, frontend) et les pousse vers Azure Container Registry (ACR)
3. **Déploie sur Azure App Service** en utilisant `docker-compose-azure.yml`
4. **Initialise/réinitialise le superuser** Django si nécessaire

Le déploiement se déclenche **automatiquement** lors d'un push sur `main` dès que tous les secrets GitHub Actions sont configurés.

---

## Secrets GitHub Actions requis

Les secrets doivent être configurés dans **Settings > Environments > Azure Cloud** sur votre dépôt GitHub.

### Secrets Azure Container Registry (ACR)

| Secret | Description | Exemple |
|--------|-------------|---------|
| `AZURE_ACR_NAME` | Nom du registre ACR (sans `.azurecr.io`) | `mynovaville` |
| `AZURE_ACR_USERNAME` | Utilisateur de connexion ACR | Voir ACR > Access keys |
| `AZURE_ACR_PASSWORD` | Mot de passe de connexion ACR | Voir ACR > Access keys |

### Secrets Azure (authentification)

| Secret | Description | Exemple |
|--------|-------------|---------|
| `AZURE_CREDENTIALS` | Credentials Azure (format JSON) | Voir section ci-dessous |

### Secrets Base de données

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DB_NAME` | Nom de la base de données PostgreSQL | `novaville_db` |
| `DB_USER` | Utilisateur PostgreSQL | `novaville_user` |
| `DB_PASSWORD` | Mot de passe PostgreSQL (généré sécurisé) | *(généré automatiquement)* |

### Secrets Django

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DJANGO_SECRET_KEY` | Clé secrète Django (32 caractères+) | *(généré via `python -c "import secrets; print(secrets.token_urlsafe(32))"`)* |
| `JWT_SIGNING_KEY` | Clé de signature JWT (32 caractères+) | *(même processus que DJANGO_SECRET_KEY)* |

### Secrets Superuser

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DJANGO_SUPERUSER_USERNAME` | Nom d'utilisateur admin | `admin` |
| `DJANGO_SUPERUSER_EMAIL` | Email du superuser | `admin@novaville.local` |
| `DJANGO_SUPERUSER_PASSWORD` | Mot de passe admin (généré sécurisé) | *(généré automatiquement)* |
| `DJANGO_RESET_ADMIN_ON_DEPLOY` | Réinitialiser l'admin à chaque déploiement? | `false` (recommandé) |

---

## Configuration étape par étape

### 1. Créer une Service Principal Azure

```bash
az ad sp create-for-rbac --name "Novaville-GitHub" --role contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}
```

La sortie fournit `AZURE_CREDENTIALS` au format JSON :

```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

Copier la sortie entière (au format JSON) dans le secret `AZURE_CREDENTIALS`.

### 2. Configurer Azure Container Registry (ACR)

```bash
# Créer l'ACR
az acr create --resource-group Novaville --name mynovaville --sku Basic

# Récupérer les credentials
az acr credential show --name mynovaville
```

Récupérer et configurer :
- `AZURE_ACR_NAME` = le nom du registre
- `AZURE_ACR_USERNAME` = `username` de la sortie ci-dessus
- `AZURE_ACR_PASSWORD` = `password` de la sortie ci-dessus

### 3. Créer/configurer App Service Azure

```bash
# Créer le plan App Service
az appservice plan create --name NovavillePlan --resource-group Novaville --sku B2

# Créer l'App Service
az webapp create --name NovavilleApp --resource-group Novaville \
  --plan NovavillePlan --deployment-container-image-name-user-provided
```

### 4. Générer les clés secrètes

```bash
# Générer DJANGO_SECRET_KEY et JWT_SIGNING_KEY (32 chars+)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Générer DB_PASSWORD et DJANGO_SUPERUSER_PASSWORD
python -c "import secrets; print(secrets.token_urlsafe(20))"
```

### 5. Configurer les secrets GitHub

1. Aller à votre dépôt GitHub → **Settings > Environments**
2. Créer un environment nommé **`Azure Cloud`**
3. Ajouter chaque secret (voir tableau ci-dessus)

Exemple (screenshot) :
```
AZURE_ACR_NAME = mynovaville
AZURE_ACR_USERNAME = username
AZURE_ACR_PASSWORD = password
AZURE_CREDENTIALS = { "clientId": "...", ... }
DB_NAME = novaville_db
DB_USER = novaville_user
DB_PASSWORD = GeneratedSecurePassword123!
DJANGO_SECRET_KEY = GeneratedKey_xyz_abc
JWT_SIGNING_KEY = GeneratedKey_def_ghi
DJANGO_SUPERUSER_USERNAME = admin
DJANGO_SUPERUSER_EMAIL = admin@novaville.local
DJANGO_SUPERUSER_PASSWORD = GeneratedAdminPassword456!
DJANGO_RESET_ADMIN_ON_DEPLOY = false
```

---

## Workflow automatique

Une fois les secrets configurés, le déploiement s'effectue comme suit :

```
Push sur main
    ↓
[1] Exécuter les tests pré-déploiement (Django, migrations, admin)
    ├─ Django system check
    ├─ Check missing migrations
    ├─ ensure_admin tests
    └─ Production config tests
    ↓
[2] Construire et pousser les images Docker
    ├─ Backend → ACR
    ├─ Frontend → ACR
    └─ PostgreSQL Bitnami → ACR
    ↓
[3] Déployer sur App Service
    ├─ Vérifier que DJANGO_SUPERUSER_PASSWORD est défini
    ├─ Configurer les app settings Azure
    ├─ Déployer docker-compose-azure.yml
    └─ Initialiser l'admin Django
    ↓
✅ Déploiement complet (accès via AZURE_APP_URL)
```

### Points clés

- ⚠️ **Les tests doivent passer** pour que le déploiement continue
- 🔒 **Tous les secrets sont chiffrés** et inaccessibles hors de GitHub Actions
- 🔄 **Le déploiement se déclenche automatiquement** à chaque push sur `main`
- 📧 **L'admin Django est créé/réinitialisé** au démarrage du backend si `DJANGO_RESET_ADMIN_ON_DEPLOY=true`

---

## Vérification post-déploiement

```bash
# Vérifier que l'App Service est en ligne
curl https://NovavilleApp.azurewebsites.net/api/

# Vérifier les logs
az webapp log tail --name NovavilleApp --resource-group Novaville

# Se connecter au superuser Django
# Accéder à https://NovavilleApp.azurewebsites.net/admin/
# Utiliser DJANGO_SUPERUSER_USERNAME et DJANGO_SUPERUSER_PASSWORD
```

---

## Dépannage

### Erreur : "DJANGO_SUPERUSER_PASSWORD secret is not set"

**Solution** : Configurer `DJANGO_SUPERUSER_PASSWORD` dans l'environment `Azure Cloud` sur GitHub.

### Le déploiement échoue aux tests pré-déploiement

**Solution** : Les tests Django, migrations ou admin échouent. Vérifier localement :

```bash
docker compose up -d
docker compose exec backend pytest backend/tests/test_production_config.py -v
```

### Les images ne sont pas poussées vers ACR

**Solution** : Vérifier `AZURE_ACR_NAME`, `AZURE_ACR_USERNAME`, `AZURE_ACR_PASSWORD` dans les secrets GitHub.

### L'App Service ne démarre pas

**Solution** : Vérifier les logs Azure :

```bash
az webapp log tail --name NovavilleApp --resource-group Novaville --provider docker
```

---

## Voir aussi

- [Internal Guides](./internal-guides) — procédures d'installation et première setup
- [Architecture](./architecture) — vue globale de l'application
- [GitHub Actions workflow](https://github.com/Michael16b/Novaville/blob/main/.github/workflows/deploy_docker_azure.yml)
