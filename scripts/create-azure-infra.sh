#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  AZURE_RESOURCE_GROUP
  AZURE_LOCATION
  AZURE_APP_NAME
  AZURE_APP_SERVICE_PLAN_NAME
  AZURE_ACR_NAME
  AZURE_STORAGE_ACCOUNT_NAME
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

if az group show --name "$AZURE_RESOURCE_GROUP" --output none 2>/dev/null; then
  echo "Resource group already exists: $AZURE_RESOURCE_GROUP"
else
  az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION" --output none
fi

if az acr show --name "$AZURE_ACR_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --output none 2>/dev/null; then
  echo "ACR already exists: $AZURE_ACR_NAME"
else
  az acr create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name "$AZURE_ACR_NAME" \
    --sku Basic \
    --admin-enabled true \
    --output none
fi

if az storage account show --name "$AZURE_STORAGE_ACCOUNT_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --output none 2>/dev/null; then
  echo "Storage account already exists: $AZURE_STORAGE_ACCOUNT_NAME"
else
  az storage account create \
    --name "$AZURE_STORAGE_ACCOUNT_NAME" \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --location "$AZURE_LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --output none
fi

if az appservice plan show --name "$AZURE_APP_SERVICE_PLAN_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --output none 2>/dev/null; then
  echo "App Service plan already exists: $AZURE_APP_SERVICE_PLAN_NAME"
else
  az appservice plan create \
    --name "$AZURE_APP_SERVICE_PLAN_NAME" \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --location "$AZURE_LOCATION" \
    --sku B1 \
    --is-linux \
    --output none
fi

if az webapp show --name "$AZURE_APP_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --output none 2>/dev/null; then
  echo "App Service already exists: $AZURE_APP_NAME"
else
  az webapp create \
    --name "$AZURE_APP_NAME" \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --plan "$AZURE_APP_SERVICE_PLAN_NAME" \
    --deployment-container-image-name "nginx:latest" \
    --output none
fi

cat <<EOF
Done.
Resource group: $AZURE_RESOURCE_GROUP
App Service: $AZURE_APP_NAME
App Service plan: $AZURE_APP_SERVICE_PLAN_NAME
ACR: $AZURE_ACR_NAME
Storage account: $AZURE_STORAGE_ACCOUNT_NAME
EOF
