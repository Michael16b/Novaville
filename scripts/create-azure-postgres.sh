#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  AZURE_RESOURCE_GROUP
  AZURE_LOCATION
  AZURE_APP_NAME
  AZURE_POSTGRES_SERVER_NAME
  DB_NAME
  DB_USER
  DB_PASSWORD
)

missing=0
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: $var is not set"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

AZURE_POSTGRES_SKU=${AZURE_POSTGRES_SKU:-Standard_B1ms}
AZURE_POSTGRES_STORAGE_GB=${AZURE_POSTGRES_STORAGE_GB:-32}
AZURE_POSTGRES_VERSION=${AZURE_POSTGRES_VERSION:-15}

if az postgres flexible-server show \
  --name "$AZURE_POSTGRES_SERVER_NAME" \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --output none 2>/dev/null; then
  echo "PostgreSQL server already exists: $AZURE_POSTGRES_SERVER_NAME"
else
  az postgres flexible-server create \
    --name "$AZURE_POSTGRES_SERVER_NAME" \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --location "$AZURE_LOCATION" \
    --admin-user "$DB_USER" \
    --admin-password "$DB_PASSWORD" \
    --sku-name "$AZURE_POSTGRES_SKU" \
    --tier Burstable \
    --storage-size "$AZURE_POSTGRES_STORAGE_GB" \
    --version "$AZURE_POSTGRES_VERSION" \
    --public-access Enabled
fi

db_exists=false
if az postgres flexible-server db show \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --server-name "$AZURE_POSTGRES_SERVER_NAME" \
  --name "$DB_NAME" \
  --output none 2>/dev/null; then
  db_exists=true
elif az postgres flexible-server db show \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --server-name "$AZURE_POSTGRES_SERVER_NAME" \
  --database-name "$DB_NAME" \
  --output none 2>/dev/null; then
  db_exists=true
fi

if $db_exists; then
  echo "Database already exists: $DB_NAME"
else
  if az postgres flexible-server db create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --server-name "$AZURE_POSTGRES_SERVER_NAME" \
    --name "$DB_NAME" \
    --output none 2>/dev/null; then
    :
  else
    az postgres flexible-server db create \
      --resource-group "$AZURE_RESOURCE_GROUP" \
      --server-name "$AZURE_POSTGRES_SERVER_NAME" \
      --database-name "$DB_NAME" \
      --output none
  fi
fi

outbound_ips=$(az webapp show \
  --name "$AZURE_APP_NAME" \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --query outboundIpAddresses \
  --output tsv)

IFS=',' read -ra ip_list <<< "$outbound_ips"
for ip in "${ip_list[@]}"; do
  rule_name="appservice-${ip//./-}"
  if az postgres flexible-server firewall-rule create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --server-name "$AZURE_POSTGRES_SERVER_NAME" \
    --name "$rule_name" \
    --start-ip-address "$ip" \
    --end-ip-address "$ip" \
    --output none 2>/dev/null; then
    :
  else
    az postgres flexible-server firewall-rule create \
      --resource-group "$AZURE_RESOURCE_GROUP" \
      --name "$AZURE_POSTGRES_SERVER_NAME" \
      --rule-name "$rule_name" \
      --start-ip-address "$ip" \
      --end-ip-address "$ip" \
      --output none
  fi
  echo "Firewall rule added for $ip"
done

DB_HOST="${AZURE_POSTGRES_SERVER_NAME}.postgres.database.azure.com"
DB_USER_FORMATTED="${DB_USER}@${AZURE_POSTGRES_SERVER_NAME}"

cat <<EOF
Done.
DB_HOST=$DB_HOST
DB_USER=$DB_USER_FORMATTED
DATABASE_URL=postgres://${DB_USER_FORMATTED}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME}?sslmode=require
EOF
