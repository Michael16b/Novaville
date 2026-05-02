---
sidebar_position: 4
---

# Azure Deployment

This document explains how to set up automatic deployment of Novaville on Azure via GitHub Actions.

## Deployment architecture

The CI/CD workflow (`.github/workflows/deploy_docker_azure.yml`):

1. **Runs pre-deployment tests** (Django, migrations, admin)
2. **Builds Docker images** (backend, frontend) and pushes them to Azure Container Registry (ACR)
3. **Deploys to Azure App Service** using `docker-compose-azure.yml`
4. **Initializes/resets Django superuser** if needed

Deployment triggers **automatically** on every push to `main` once all GitHub Actions secrets are configured.

---

## GitHub Actions secrets required

Secrets must be configured in **Settings > Environments > Azure Cloud** on your GitHub repository.

### Azure Container Registry (ACR) secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_ACR_NAME` | ACR registry name (without `.azurecr.io`) | `mynovaville` |
| `AZURE_ACR_USERNAME` | ACR login username | See ACR > Access keys |
| `AZURE_ACR_PASSWORD` | ACR login password | See ACR > Access keys |

### Azure authentication secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_CREDENTIALS` | Azure credentials (JSON format) | See section below |

### Database secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `DB_NAME` | PostgreSQL database name | `novaville_db` |
| `DB_USER` | PostgreSQL user | `novaville_user` |
| `DB_PASSWORD` | PostgreSQL password (generate secure) | *(auto-generated)* |

### Django secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `DJANGO_SECRET_KEY` | Django secret key (32+ chars) | *(generated via `python -c "import secrets; print(secrets.token_urlsafe(32))"`)* |
| `JWT_SIGNING_KEY` | JWT signing key (32+ chars) | *(same method as DJANGO_SECRET_KEY)* |

### Superuser secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `DJANGO_SUPERUSER_USERNAME` | Admin username | `admin` |
| `DJANGO_SUPERUSER_EMAIL` | Admin email | `admin@novaville.local` |
| `DJANGO_SUPERUSER_PASSWORD` | Admin password (generate secure) | *(auto-generated)* |
| `DJANGO_RESET_ADMIN_ON_DEPLOY` | Reset admin on each deploy? | `false` (recommended) |

---

## Step-by-step setup

### 1. Create Azure Service Principal

```bash
az ad sp create-for-rbac --name "Novaville-GitHub" --role contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}
```

Output provides `AZURE_CREDENTIALS` in JSON format:

```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

Copy the entire output (JSON format) to the `AZURE_CREDENTIALS` secret.

### 2. Configure Azure Container Registry (ACR)

```bash
# Create ACR
az acr create --resource-group Novaville --name mynovaville --sku Basic

# Retrieve credentials
az acr credential show --name mynovaville
```

Configure:
- `AZURE_ACR_NAME` = registry name
- `AZURE_ACR_USERNAME` = `username` from above
- `AZURE_ACR_PASSWORD` = `password` from above

### 3. Create/configure Azure App Service

```bash
# Create App Service plan
az appservice plan create --name NovavillePlan --resource-group Novaville --sku B2

# Create App Service
az webapp create --name NovavilleApp --resource-group Novaville \
  --plan NovavillePlan --deployment-container-image-name-user-provided
```

### 4. Generate secret keys

```bash
# Generate DJANGO_SECRET_KEY and JWT_SIGNING_KEY (32+ chars)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate DB_PASSWORD and DJANGO_SUPERUSER_PASSWORD
python -c "import secrets; print(secrets.token_urlsafe(20))"
```

### 5. Configure GitHub secrets

1. Go to your GitHub repository → **Settings > Environments**
2. Create an environment named **`Azure Cloud`**
3. Add each secret (see table above)

Example (screenshot):
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

## Automatic workflow

Once secrets are configured, deployment works as follows:

```
Push to main
    ↓
[1] Run pre-deployment tests (Django, migrations, admin)
    ├─ Django system check
    ├─ Check missing migrations
    ├─ ensure_admin tests
    └─ Production config tests
    ↓
[2] Build and push Docker images
    ├─ Backend → ACR
    ├─ Frontend → ACR
    └─ PostgreSQL Bitnami → ACR
    ↓
[3] Deploy to App Service
    ├─ Verify DJANGO_SUPERUSER_PASSWORD is set
    ├─ Configure Azure app settings
    ├─ Deploy docker-compose-azure.yml
    └─ Initialize Django admin
    ↓
✅ Deployment complete (access via AZURE_APP_URL)
```

### Key points

- ⚠️ **Tests must pass** for deployment to continue
- 🔒 **All secrets are encrypted** and only accessible within GitHub Actions
- 🔄 **Deployment triggers automatically** on every push to `main`
- 📧 **Django admin is created/reset** on backend startup if `DJANGO_RESET_ADMIN_ON_DEPLOY=true`

---

## Post-deployment verification

```bash
# Check App Service is online
curl https://NovavilleApp.azurewebsites.net/api/

# Check logs
az webapp log tail --name NovavilleApp --resource-group Novaville

# Log in to Django admin
# Visit https://NovavilleApp.azurewebsites.net/admin/
# Use DJANGO_SUPERUSER_USERNAME and DJANGO_SUPERUSER_PASSWORD
```

---

## Troubleshooting

### Error: "DJANGO_SUPERUSER_PASSWORD secret is not set"

**Solution**: Configure `DJANGO_SUPERUSER_PASSWORD` in the `Azure Cloud` environment on GitHub.

### Deployment fails at pre-deployment tests

**Solution**: Django tests, migrations or admin initialization fail. Test locally:

```bash
docker compose up -d
docker compose exec backend pytest backend/tests/test_production_config.py -v
```

### Images not pushed to ACR

**Solution**: Check `AZURE_ACR_NAME`, `AZURE_ACR_USERNAME`, `AZURE_ACR_PASSWORD` in GitHub secrets.

### App Service fails to start

**Solution**: Check Azure logs:

```bash
az webapp log tail --name NovavilleApp --resource-group Novaville --provider docker
```

---

## See also

- [Internal Guides](./internal-guides) — installation procedures and first setup
- [Architecture](./architecture) — application overview
- [GitHub Actions workflow](https://github.com/Michael16b/Novaville/blob/main/.github/workflows/deploy_docker_azure.yml)
