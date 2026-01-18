# Guide de Déploiement Azure pour Novaville

Ce document explique les deux options de déploiement sur Azure et comment les configurer.

## Option 1: Azure Web App avec Conteneurs Multi-Containers (Actuel)

Cette option utilise `docker-compose-azure.yml` et déploie à la fois PostgreSQL et le backend dans des conteneurs sur Azure Web App for Containers.

### Avantages
- Configuration simple et autonome
- Toute la stack dans des conteneurs
- Cohérent avec le développement local

### Inconvénients
- Stockage des données dans des volumes de conteneurs (peut être perdu lors des redéploiements)
- Pas de backups automatiques de la base de données
- Ressources limitées par l'instance Web App

### Configuration

Utilisez le fichier `docker-compose-azure.yml` existant.

**Variables d'environnement à configurer dans Azure App Service:**
```
DB_PASSWORD=votre_mot_de_passe_securise
DJANGO_SECRET_KEY=votre_cle_secrete
DJANGO_SUPERUSER_PASSWORD=mot_de_passe_admin
```

**Commande de déploiement:**
```bash
az webapp config container set \
  --name NovavilleApp \
  --resource-group Novaville \
  --multicontainer-config-type COMPOSE \
  --multicontainer-config-file docker-compose-azure.yml
```

---

## Option 2: Azure Database for PostgreSQL (Recommandé pour Production)

Cette option utilise `docker-compose-azure-managed-db.yml` et Azure Database for PostgreSQL comme service géré, avec seulement le backend et frontend en conteneurs.

### Avantages ✅
- **Backups automatiques** de la base de données
- **Haute disponibilité** et redondance
- **Scalabilité** indépendante de la base de données
- **Sécurité renforcée** avec chiffrement et isolation réseau
- **Maintenance gérée** par Azure (mises à jour, patches)
- Données **persistantes** même lors des redéploiements

### Configuration Requise

#### 1. Créer Azure Database for PostgreSQL

Dans le portail Azure ou via CLI:

```bash
# Créer le serveur PostgreSQL
az postgres server create \
  --resource-group Novaville \
  --name novavillesql \
  --location westeurope \
  --admin-user novaville_admin \
  --admin-password VotreMotDePasseSecurise \
  --sku-name B_Gen5_1 \
  --version 15

# Créer la base de données
az postgres db create \
  --resource-group Novaville \
  --server-name novavillesql \
  --name novavilledb
```

#### 2. Configurer le Firewall

Autoriser l'accès depuis Azure Services:

```bash
az postgres server firewall-rule create \
  --resource-group Novaville \
  --server-name novavillesql \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

#### 3. Obtenir les Informations de Connexion

- **Hostname**: `novavillesql.postgres.database.azure.com`
- **Port**: `5432`
- **Database**: `novavilledb`
- **User**: `novaville_admin@novavillesql` (format: username@servername)
- **Password**: Celui configuré lors de la création

#### 4. Configurer les Variables d'Environnement dans Azure App Service

Dans le portail Azure > App Service > Configuration > Application settings:

```
DB_HOST=novavillesql.postgres.database.azure.com
DB_PORT=5432
DB_NAME=novavilledb
DB_USER=novaville_admin@novavillesql
DB_PASSWORD=VotreMotDePasseSecurise
DJANGO_SECRET_KEY=votre_cle_secrete_django
DJANGO_ALLOWED_HOSTS=novavilleapp.azurewebsites.net
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@example.com
DJANGO_SUPERUSER_PASSWORD=VotreMotDePasseAdmin
```

#### 5. Déployer avec la Nouvelle Configuration

Modifiez `.github/workflows/deploy_docker_azure.yml` pour utiliser le nouveau fichier:

```yaml
- name: Deploy Docker Compose
  run: |
    az webapp config container set \
      --name NovavilleApp \
      --resource-group Novaville \
      --multicontainer-config-type COMPOSE \
      --multicontainer-config-file docker-compose-azure-managed-db.yml \
      --docker-registry-server-url https://${{ secrets.AZURE_ACR_NAME }}.azurecr.io \
      --docker-registry-server-user ${{ secrets.AZURE_ACR_USERNAME }} \
      --docker-registry-server-password ${{ secrets.AZURE_ACR_PASSWORD }}
```

---

## Vérification de la Configuration

### Tester la Connexion à la Base de Données

Une fois déployé, vérifiez les logs du backend:

```bash
az webapp log tail --name NovavilleApp --resource-group Novaville
```

Vous devriez voir:
```
[wait_for_db] Waiting for database at novavillesql.postgres.database.azure.com:5432...
[wait_for_db] Database: novavilledb, User: novaville_admin@novavillesql
[wait_for_db] Attempt 1/60...
[wait_for_db] Database is ready!
```

### Connexions SSL

Azure Database for PostgreSQL requiert SSL par défaut. Django gère automatiquement SSL avec psycopg2, mais si vous avez des problèmes, ajoutez:

```python
# Dans settings.py ou via variable d'environnement
DATABASES['default']['OPTIONS'] = {
    'sslmode': 'require'
}
```

---

## Migration depuis l'Option 1 vers l'Option 2

Si vous avez déjà des données dans l'option 1 (conteneur), voici comment migrer:

1. **Exporter les données** depuis le conteneur:
```bash
docker exec novaville-postgres pg_dump -U novaville_user novaville_db > backup.sql
```

2. **Importer dans Azure Database**:
```bash
psql "host=novavillesql.postgres.database.azure.com port=5432 dbname=novavilledb user=novaville_admin@novavillesql sslmode=require" < backup.sql
```

---

## Recommandation

Pour votre cas actuel où vous avez créé `novavillesql/novavilledb`:

👉 **Utilisez l'Option 2** avec `docker-compose-azure-managed-db.yml`

Raisons:
1. Vous avez déjà créé la base de données Azure
2. Meilleure solution pour la production (backups, HA, sécurité)
3. Les données persistent même lors des redéploiements
4. Facilite la scalabilité future

---

## Dépannage

### Erreur: "Connection refused"
- Vérifiez les règles de firewall Azure Database
- Confirmez que les variables d'environnement sont correctement définies
- Vérifiez le format du username: `username@servername`

### Erreur: "SSL required"
- Azure Database for PostgreSQL nécessite SSL
- Django/psycopg2 gère automatiquement SSL dans la plupart des cas

### Logs pour Debugging
```bash
# Voir les logs en temps réel
az webapp log tail --name NovavilleApp --resource-group Novaville

# Télécharger tous les logs
az webapp log download --name NovavilleApp --resource-group Novaville
```

### Tester la Connexion Manuellement

Depuis votre machine locale (pour tester):
```bash
psql "host=novavillesql.postgres.database.azure.com port=5432 dbname=novavilledb user=novaville_admin@novavillesql sslmode=require"
```
