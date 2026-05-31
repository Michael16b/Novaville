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


## What is automated vs manual

**Automated (CI)**
- build and push images (backend, frontend)
- configure App Settings
- deploy App Service via `docker-compose-azure.yml`

**Optional (CI, manual trigger)**
- create Azure infra (RG, ACR, Storage, App Service, plan) via `create_infra`
- create PostgreSQL Flexible Server + firewall + database via `create_postgres`

**Manual (one-time)**
- create and update GitHub secrets
- choose Azure resource names (RG, Postgres server, storage)

**Checklist before redeploy**
- `AZURE_POSTGRES_SERVER_NAME` set
- `DB_NAME`, `DB_USER`, `DB_PASSWORD` set
- deploy workflow rerun after DB creation


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

**Azure PostgreSQL note**: `DB_USER` must be in the `user@server` format (e.g. `novaville_user@novaville-db-prod`).
`DB_HOST` should be `novaville-db-prod.postgres.database.azure.com`.

### Infrastructure secrets (PostgreSQL script)

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_POSTGRES_SERVER_NAME` | Flexible PostgreSQL server name | `novaville-db` |
| `AZURE_APP_NAME` | App Service name | `NovavilleApp` |
| `AZURE_RESOURCE_GROUP` | Target Resource Group | `Novaville` |
| `AZURE_LOCATION` | Azure region | `francecentral` |

### Infrastructure secrets (Azure infra script)

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_APP_SERVICE_PLAN_NAME` | App Service plan name | `NovavillePlan` |
| `AZURE_STORAGE_ACCOUNT_NAME` | Storage account name (unique) | `novavillestorage` |

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

### 2. Create Resource Group

```bash
az group create --name Novaville --location westeurope
```

### 3. Configure Azure Container Registry (ACR)

```bash
# Create ACR
az acr create --resource-group Novaville --name mynovaville --sku Basic

# Retrieve credentials
az acr credential show --name mynovaville
```

Configure:
- `AZURE_ACR_NAME` = registry name (e.g. `mynovaville`)
- `AZURE_ACR_USERNAME` = `username` from above
- `AZURE_ACR_PASSWORD` = `password` from above

### 4. Create PostgreSQL Database

**Option A: Azure Database for PostgreSQL (recommended for production)**

Use the repo Azure CLI script (no hardcoded values, everything comes from secrets):

```bash
bash scripts/create-azure-postgres.sh
```

On Windows (PowerShell):

```powershell
./scripts/create-azure-postgres.ps1
```

GitHub Actions example (run once):

```yaml
- name: Create Azure PostgreSQL (once)
  run: bash scripts/create-azure-postgres.sh
  env:
    AZURE_RESOURCE_GROUP: ${{ secrets.AZURE_RESOURCE_GROUP }}
    AZURE_LOCATION: ${{ secrets.AZURE_LOCATION }}
    AZURE_APP_NAME: ${{ secrets.AZURE_APP_NAME }}
    AZURE_POSTGRES_SERVER_NAME: ${{ secrets.AZURE_POSTGRES_SERVER_NAME }}
    DB_NAME: ${{ secrets.DB_NAME }}
    DB_USER: ${{ secrets.DB_USER }}
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

Required variables (GitHub secrets or local export):

```
AZURE_RESOURCE_GROUP
AZURE_LOCATION
AZURE_APP_NAME
AZURE_POSTGRES_SERVER_NAME
DB_NAME
DB_USER
DB_PASSWORD
```

The script:
- creates the server with the minimum SKU (`Standard_B1ms`)
- enables public access
- opens the firewall for App Service outbound IPs
- prints `DB_HOST` and the expected `DB_USER` format

Clean GitHub Actions run (recommended):
1) Go to GitHub > Actions > workflow "Build and Deploy Novaville - Multi-Container".
2) Click "Run workflow" and enable the `create_postgres` option.
3) The job creates the database, then the rest of the workflow proceeds.

After execution, update the `DB_HOST` and `DB_USER` secrets with the script output.

Once the Azure database is created, remove the Postgres service from the Azure compose and provide `DB_HOST`.

### 4b. Create Azure infrastructure (optional)

Use the Azure CLI script to create if missing:
- Resource Group
- App Service Plan
- App Service
- Container Registry (ACR)
- Storage Account

GitHub Actions run (recommended):
1) Go to GitHub > Actions > workflow "Build and Deploy Novaville - Multi-Container".
2) Click "Run workflow" and enable the `create_infra` option.

Local script:

```bash
bash scripts/create-azure-infra.sh
```

On Windows (PowerShell):

```powershell
./scripts/create-azure-infra.ps1
```

Configure secrets from the output:
- `DB_HOST`: `<server-name>.postgres.database.azure.com`
- `DB_USER`: `<user>@<server-name>`
- `DB_NAME`: your database name
- `DB_PASSWORD`: the admin password

**Option B: Container PostgreSQL (used in docker-compose-azure.yml)**

If using Bitnami PostgreSQL in a container (see `docker-compose-azure.yml`), simply generate credentials:

```bash
DB_NAME=novaville_db
DB_USER=novaville_user
DB_PASSWORD=$(python -c "import secrets; print(secrets.token_urlsafe(20))")
```

### 5. Create Azure App Service

```bash
# Create App Service plan (B2 = production, B1 = dev)
az appservice plan create \
  --name NovavillePlan \
  --resource-group Novaville \
  --sku B2 \
  --is-linux

# Create App Service
az webapp create \
  --name NovavilleApp \
  --resource-group Novaville \
  --plan NovavillePlan \
  --deployment-container-image-name-user-provided \
  --docker-registry-server-url "https://{AZURE_ACR_NAME}.azurecr.io"
```

### 6. Configure Docker in App Service

```bash
# Configure ACR registry credentials
az webapp config container set \
  --name NovavilleApp \
  --resource-group Novaville \
  --docker-custom-image-name "{AZURE_ACR_NAME}.azurecr.io/novaville-frontend:latest" \
  --docker-registry-server-url "https://{AZURE_ACR_NAME}.azurecr.io" \
  --docker-registry-server-user "{AZURE_ACR_USERNAME}" \
  --docker-registry-server-password "{AZURE_ACR_PASSWORD}"
```

### 7. Generate secret keys

```bash
# Generate DJANGO_SECRET_KEY and JWT_SIGNING_KEY (32+ chars)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate DB_PASSWORD and DJANGO_SUPERUSER_PASSWORD
python -c "import secrets; print(secrets.token_urlsafe(20))"
```

### 8. Configure GitHub secrets

1. Go to your GitHub repository → **Settings > Environments**
2. Create an environment named **`Azure Cloud`**
3. Add each secret (see table above)

Complete example:
```
AZURE_ACR_NAME = mynovaville
AZURE_ACR_USERNAME = username_from_acr
AZURE_ACR_PASSWORD = password_from_acr
AZURE_CREDENTIALS = { "clientId": "...", "clientSecret": "...", "subscriptionId": "...", "tenantId": "..." }
DB_NAME = novaville_db
DB_USER = novaville_admin@novaville-db
DB_PASSWORD = GeneratedSecurePassword123!
DJANGO_SECRET_KEY = GeneratedKey_xyz_abc_with_32_chars
JWT_SIGNING_KEY = GeneratedKey_def_ghi_with_32_chars
DJANGO_SUPERUSER_USERNAME = admin
DJANGO_SUPERUSER_EMAIL = admin@novaville.local
DJANGO_SUPERUSER_PASSWORD = GeneratedAdminPassword456!
DJANGO_RESET_ADMIN_ON_DEPLOY = false
```

### 9. First test: verify configuration

```bash
# Test Azure credentials
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# Test ACR connection
az acr login --name mynovaville

# Verify App Service exists
az webapp list --resource-group Novaville
```

---

## Post-deployment configuration (App Settings)

Once the App Service is created, environment variables and secrets must be configured as **App Settings** in Azure.

### Via Azure CLI

```bash
# Configure all App Settings
az webapp config appsettings set \
  --name NovavilleApp \
  --resource-group Novaville \
  --settings \
    DJANGO_SECRET_KEY="{DJANGO_SECRET_KEY}" \
    JWT_SIGNING_KEY="{JWT_SIGNING_KEY}" \
    DB_ENGINE="django.db.backends.postgresql" \
    DB_HOST="{DB_HOST}" \
    DB_PORT="5432" \
    DB_NAME="{DB_NAME}" \
    DB_USER="{DB_USER}" \
    DB_PASSWORD="{DB_PASSWORD}" \
    DJANGO_SUPERUSER_USERNAME="{DJANGO_SUPERUSER_USERNAME}" \
    DJANGO_SUPERUSER_EMAIL="{DJANGO_SUPERUSER_EMAIL}" \
    DJANGO_SUPERUSER_PASSWORD="{DJANGO_SUPERUSER_PASSWORD}" \
    DJANGO_RESET_ADMIN_ON_DEPLOY="false" \
    DJANGO_LOG_LEVEL="INFO" \
    DEBUG="false" \
    ALLOWED_HOSTS="novavilleapp.azurewebsites.net,yourdomain.com" \
    MIGRATE="1" \
    COLLECTSTATIC="1"

  # Simple alternative (recommended): DATABASE_URL with SSL required
  # DATABASE_URL="postgres://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}?sslmode=require"
```

### Via Azure Portal

1. Go to **NovavilleApp > Settings > Configuration**
2. Click **+ New application setting**
3. Add each variable (see table above)

### Custom domain configuration

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name NovavilleApp \
  --resource-group Novaville \
  --hostname yourdomain.com
```

Then configure DNS at your registrar:
- Type: `CNAME`
- Host: `yourdomain.com` (or subdomain)
- Points to: `NovavilleApp.azurewebsites.net`

### SSL/TLS configuration

```bash
# Import custom certificate
az webapp config ssl upload \
  --name NovavilleApp \
  --resource-group Novaville \
  --certificate-file /path/to/certificate.pfx \
  --certificate-password "{PFX_PASSWORD}"

# Or use Let's Encrypt (via Azure App Service)
# See: https://learn.microsoft.com/en-us/azure/app-service/configure-ssl-certificate
```

Bind the certificate:

```bash
az webapp config ssl bind \
  --name NovavilleApp \
  --resource-group Novaville \
  --certificate-thumbprint "{THUMBPRINT}" \
  --ssl-type SNI
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
