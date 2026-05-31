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

## Ce qui est automatise vs manuel

**Automatise (CI)**
- build et push des images (backend, frontend)
- configuration des App Settings
- deploiement App Service via `docker-compose-azure.yml`

**Optionnel (CI, declenchement manuel)**
- creation infra Azure (RG, ACR, Storage, App Service, plan) via `create_infra`
- creation PostgreSQL Flexible Server + firewall + base via `create_postgres`

**Manuel (a faire une seule fois)**
- creation et mise a jour des secrets GitHub
- choix des noms de ressources Azure (RG, serveur Postgres, storage)

**Checklist avant relance du deploy**
- `AZURE_POSTGRES_SERVER_NAME` defini
- `DB_NAME`, `DB_USER`, `DB_PASSWORD` definis
- workflow deploy relance apres creation de la base

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

**Nuance Azure PostgreSQL** : `DB_USER` doit etre au format `user@server` (ex: `novaville_user@novaville-db-prod`).
`DB_HOST` vaut `novaville-db-prod.postgres.database.azure.com`.

### Secrets Infrastructure (script PostgreSQL)

| Secret | Description | Exemple |
|--------|-------------|---------|
| `AZURE_POSTGRES_SERVER_NAME` | Nom du serveur PostgreSQL flexible | `novaville-db` |
| `AZURE_APP_NAME` | Nom de l'App Service | `NovavilleApp` |
| `AZURE_RESOURCE_GROUP` | Resource Group cible | `Novaville` |
| `AZURE_LOCATION` | Region Azure | `francecentral` |

### Secrets Infrastructure (script infra Azure)

| Secret | Description | Exemple |
|--------|-------------|---------|
| `AZURE_APP_SERVICE_PLAN_NAME` | Nom du plan App Service | `NovavillePlan` |
| `AZURE_STORAGE_ACCOUNT_NAME` | Nom du Storage Account (unique) | `novavillestorage` |

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

### 2. Créer le Resource Group

```bash
az group create --name Novaville --location westeurope
```

### 3. Configurer Azure Container Registry (ACR)

```bash
# Créer l'ACR
az acr create --resource-group Novaville --name mynovaville --sku Basic

# Récupérer les credentials
az acr credential show --name mynovaville
```

Récupérer et configurer :
- `AZURE_ACR_NAME` = le nom du registre (ex: `mynovaville`)
- `AZURE_ACR_USERNAME` = `username` de la sortie ci-dessus
- `AZURE_ACR_PASSWORD` = `password` de la sortie ci-dessus

### 4. Créer la Base de Données PostgreSQL

**Option A : Azure Database for PostgreSQL (recommandé pour production)**

Utilisez le script Azure CLI du repo (aucune valeur en dur, tout vient des secrets) :

```bash
bash scripts/create-azure-postgres.sh
```

Sur Windows (PowerShell) :

```powershell
./scripts/create-azure-postgres.ps1
```

Exemple GitHub Actions (une seule fois) :

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

Variables requises (via secrets GitHub ou export local) :

```
AZURE_RESOURCE_GROUP
AZURE_LOCATION
AZURE_APP_NAME
AZURE_POSTGRES_SERVER_NAME
DB_NAME
DB_USER
DB_PASSWORD
```

Le script :
- cree le serveur avec le SKU minimum (`Standard_B1ms`)
- active l'acces public
- ouvre le firewall sur les IP sortantes de l'App Service
- affiche `DB_HOST` et le format `DB_USER` attendu

Execution propre via GitHub Actions (recommande) :
1) Aller sur GitHub > Actions > workflow "Build and Deploy Novaville - Multi-Container".
2) Cliquer "Run workflow" et activer l'option `create_postgres`.
3) Le job cree la base, puis le reste du workflow continue normalement.

Apres execution, mettez a jour les secrets `DB_HOST` et `DB_USER` avec la sortie du script.

Une fois la base Azure creee, retirez le service Postgres du compose Azure et fournissez `DB_HOST`.

### 4b. Creer l'infrastructure Azure (optionnel)

Utilisez le script Azure CLI pour creer si absent :
- Resource Group
- App Service Plan
- App Service
- Container Registry (ACR)
- Storage Account

Execution via GitHub Actions (recommande) :
1) Aller sur GitHub > Actions > workflow "Build and Deploy Novaville - Multi-Container".
2) Cliquer "Run workflow" et activer l'option `create_infra`.

Script local :

```bash
bash scripts/create-azure-infra.sh
```

Sur Windows (PowerShell) :

```powershell
./scripts/create-azure-infra.ps1
```

Configuration des secrets a partir de la sortie :
- `DB_HOST` : `<server-name>.postgres.database.azure.com`
- `DB_USER` : `<user>@<server-name>`
- `DB_NAME` : votre nom de base
- `DB_PASSWORD` : le mot de passe admin

**Option B : Container PostgreSQL (utilisé dans docker-compose-azure.yml)**

Si vous utilisez Bitnami PostgreSQL dans un conteneur (voir `docker-compose-azure.yml`), générez simplement les credentials :

```bash
DB_NAME=novaville_db
DB_USER=novaville_user
DB_PASSWORD=$(python -c "import secrets; print(secrets.token_urlsafe(20))")
```

### 5. Créer App Service Azure

```bash
# Créer le plan App Service (B2 = production, B1 = dev)
az appservice plan create \
  --name NovavillePlan \
  --resource-group Novaville \
  --sku B2 \
  --is-linux

# Créer l'App Service
az webapp create \
  --name NovavilleApp \
  --resource-group Novaville \
  --plan NovavillePlan \
  --deployment-container-image-name-user-provided \
  --docker-registry-server-url "https://{AZURE_ACR_NAME}.azurecr.io"
```

### 6. Configurer Docker dans App Service

```bash
# Configurer les credentials du registre ACR
az webapp config container set \
  --name NovavilleApp \
  --resource-group Novaville \
  --docker-custom-image-name "{AZURE_ACR_NAME}.azurecr.io/novaville-frontend:latest" \
  --docker-registry-server-url "https://{AZURE_ACR_NAME}.azurecr.io" \
  --docker-registry-server-user "{AZURE_ACR_USERNAME}" \
  --docker-registry-server-password "{AZURE_ACR_PASSWORD}"
```

### 7. Générer les clés secrètes

```bash
# Générer DJANGO_SECRET_KEY et JWT_SIGNING_KEY (32 chars+)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Générer DB_PASSWORD et DJANGO_SUPERUSER_PASSWORD
python -c "import secrets; print(secrets.token_urlsafe(20))"
```

### 8. Configurer les secrets GitHub

1. Aller à votre dépôt GitHub → **Settings > Environments**
2. Créer un environment nommé **`Azure Cloud`**
3. Ajouter chaque secret (voir tableau ci-dessus)

Exemple complet :
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

### 9. Premier test : vérifier la configuration

```bash
# Tester les credentials Azure
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# Tester la connexion à ACR
az acr login --name mynovaville

# Vérifier que l'App Service existe
az webapp list --resource-group Novaville
```

---

## Configuration post-déploiement (App Settings)

Une fois l'App Service créé, les variables d'environnement et secrets doivent être configurés comme **App Settings** dans Azure.

### Via Azure CLI

```bash
# Configurer tous les App Settings
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

  # Option alternative simple (recommandee) : DATABASE_URL avec SSL obligatoire
  # DATABASE_URL="postgres://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}?sslmode=require"
```

### Via Azure Portal

1. Aller à **NovavilleApp > Settings > Configuration**
2. Cliquer sur **+ New application setting**
3. Ajouter chaque variable (voir tableau plus haut)

### Configuration de domaines personnalisés

```bash
# Ajouter un domaine personnalisé
az webapp config hostname add \
  --webapp-name NovavilleApp \
  --resource-group Novaville \
  --hostname yourdomain.com
```

Puis configurer le DNS chez votre registrar :
- Type: `CNAME`
- Host: `yourdomain.com` (ou subdomain)
- Points to: `NovavilleApp.azurewebsites.net`

### Configuration SSL/TLS

```bash
# Importer un certificat personnalisé
az webapp config ssl upload \
  --name NovavilleApp \
  --resource-group Novaville \
  --certificate-file /path/to/certificate.pfx \
  --certificate-password "{PFX_PASSWORD}"

# Ou utiliser Let's Encrypt (via Azure App Service)
# Voir : https://learn.microsoft.com/en-us/azure/app-service/configure-ssl-certificate
```

Bind le certificat :

```bash
az webapp config ssl bind \
  --name NovavilleApp \
  --resource-group Novaville \
  --certificate-thumbprint "{THUMBPRINT}" \
  --ssl-type SNI
```

---

## Workflow automatique (GitHub Actions)

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
- [Distribution des applications](./app-distribution) — build et publication des applications
- [GitHub Actions workflow](https://github.com/Michael16b/Novaville/blob/main/.github/workflows/deploy_docker_azure.yml)
