# Comparaison des Architectures Azure

## Architecture Actuelle (docker-compose-azure.yml) ✅

```
┌─────────────────────────────────────────┐
│   Azure Web App for Containers         │
│                                         │
│  ┌──────────────┐    ┌──────────────┐  │
│  │   Postgres   │◄───│   Backend    │  │
│  │  Container   │    │  Container   │  │
│  │              │    │  :8000       │  │
│  │ novaville_db │    │ Django+Wait  │  │
│  └──────────────┘    └──────┬───────┘  │
│         ▲                    ▲          │
│         │                    │          │
│    [Volume]            [Internal]       │
│                              │          │
│  ┌──────────────────────────┘          │
│  │   Frontend (Nginx)                  │
│  │   :80 (Public)                      │
│  │   Proxy: /api/ → backend:8000       │
│  └─────────────────────────────────────┤
│                                         │
└─────────────────────────────────────────┘
         ▲
         │ Port 80 (HTTPS)
         │
   [novavilleapp.azurewebsites.net]

Solution: Nginx dans frontend proxy les requêtes /api/ vers backend
```

## Architecture Recommandée (docker-compose-azure-managed-db.yml) ✅

```
┌─────────────────────────────────────────┐
│   Azure Web App for Containers         │
│                                         │
│  ┌──────────────────────────┐          │
│  │   Frontend (Nginx)       │          │
│  │   :80 (Public)           │          │
│  │   Proxy: /api/ → backend │          │
│  └──────────┬───────────────┘          │
│             │                           │
│  ┌──────────▼───────────┐              │
│  │   Backend            │              │
│  │   :8000 (Internal)   │              │
│  │   Django+Wait        │              │
│  └──────────┬───────────┘              │
│             │                           │
└─────────────┼───────────────────────────┘
              │ Port 5432 + SSL
              ▼
┌──────────────────────────────────────────┐
│  Azure Database for PostgreSQL          │
│                                          │
│  novavillesql.postgres.database.azure.com│
│  Database: novavilledb                   │
│                                          │
│  ✓ Backups automatiques                 │
│  ✓ Haute disponibilité                  │
│  ✓ Données persistantes                 │
│  ✓ Firewall géré                        │
└──────────────────────────────────────────┘

Avantage: Service géré + Routing correct via Nginx
```

## Configuration Rapide

### Étape 1: Configurer les Variables d'Environnement

Dans Azure Portal → App Service → Configuration:

```bash
DB_HOST=novavillesql.postgres.database.azure.com
DB_PORT=5432
DB_NAME=novavilledb
DB_USER=novaville_admin@novavillesql  # Format important!
DB_PASSWORD=VotreMotDePasse
DJANGO_SECRET_KEY=VotreClé
DJANGO_ALLOWED_HOSTS=novavilleapp.azurewebsites.net
```

### Étape 2: Modifier le Workflow GitHub

Dans `.github/workflows/deploy_docker_azure.yml`, ligne 59:

```yaml
# AVANT
--multicontainer-config-file docker-compose-azure.yml \

# APRÈS
--multicontainer-config-file docker-compose-azure-managed-db.yml \
```

### Étape 3: Configurer le Firewall Azure Database

```bash
az postgres server firewall-rule create \
  --resource-group Novaville \
  --server-name novavillesql \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Étape 4: Déployer

Push sur `main` pour déclencher le workflow GitHub Actions.

## Vérification

Logs de succès attendus:

```
[wait_for_db] Waiting for database at novavillesql.postgres.database.azure.com:5432...
[wait_for_db] Database: novavilledb, User: novaville_admin@novavillesql
[wait_for_db] Attempt 1/60...
[wait_for_db] Database is ready!
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, sessions...
Running migrations...
```

## Différences Clés

| Aspect | Containerized | Azure Database |
|--------|---------------|----------------|
| Hostname | `postgres` | `novavillesql.postgres.database.azure.com` |
| User Format | `novaville_user` | `username@servername` |
| Port | 5432 | 5432 |
| SSL | Optionnel | Requis (auto) |
| Backups | Manuel | Automatique |
| Persistence | Volume | Service géré |
| HA | Non | Oui |

Voir `AZURE_DEPLOYMENT.md` pour plus de détails.
