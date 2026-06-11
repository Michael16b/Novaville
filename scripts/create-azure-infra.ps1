$ErrorActionPreference = "Stop"

$requiredVars = @(
  "AZURE_RESOURCE_GROUP",
  "AZURE_LOCATION",
  "AZURE_APP_NAME",
  "AZURE_APP_SERVICE_PLAN_NAME",
  "AZURE_ACR_NAME",
  "AZURE_STORAGE_ACCOUNT_NAME"
)

$missing = @()
foreach ($var in $requiredVars) {
  $value = [Environment]::GetEnvironmentVariable($var)
  if ([string]::IsNullOrWhiteSpace($value)) {
    $missing += $var
  }
}

if ($missing.Count -gt 0) {
  Write-Error "Missing environment variables: $($missing -join ', ')"
  exit 1
}

$rgExists = $false
try {
  az group show --name $env:AZURE_RESOURCE_GROUP --output none | Out-Null
  $rgExists = $true
} catch {
  $rgExists = $false
}

if ($rgExists) {
  Write-Host "Resource group already exists: $($env:AZURE_RESOURCE_GROUP)"
} else {
  az group create --name $env:AZURE_RESOURCE_GROUP --location $env:AZURE_LOCATION --output none | Out-Null
}

$acrExists = $false
try {
  az acr show --name $env:AZURE_ACR_NAME --resource-group $env:AZURE_RESOURCE_GROUP --output none | Out-Null
  $acrExists = $true
} catch {
  $acrExists = $false
}

if ($acrExists) {
  Write-Host "ACR already exists: $($env:AZURE_ACR_NAME)"
} else {
  az acr create `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --name $env:AZURE_ACR_NAME `
    --sku Basic `
    --admin-enabled true `
    --output none | Out-Null
}

$storageExists = $false
try {
  az storage account show --name $env:AZURE_STORAGE_ACCOUNT_NAME --resource-group $env:AZURE_RESOURCE_GROUP --output none | Out-Null
  $storageExists = $true
} catch {
  $storageExists = $false
}

if ($storageExists) {
  Write-Host "Storage account already exists: $($env:AZURE_STORAGE_ACCOUNT_NAME)"
} else {
  az storage account create `
    --name $env:AZURE_STORAGE_ACCOUNT_NAME `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --location $env:AZURE_LOCATION `
    --sku Standard_LRS `
    --kind StorageV2 `
    --output none | Out-Null
}

$planExists = $false
try {
  az appservice plan show --name $env:AZURE_APP_SERVICE_PLAN_NAME --resource-group $env:AZURE_RESOURCE_GROUP --output none | Out-Null
  $planExists = $true
} catch {
  $planExists = $false
}

if ($planExists) {
  Write-Host "App Service plan already exists: $($env:AZURE_APP_SERVICE_PLAN_NAME)"
} else {
  az appservice plan create `
    --name $env:AZURE_APP_SERVICE_PLAN_NAME `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --location $env:AZURE_LOCATION `
    --sku B1 `
    --is-linux `
    --output none | Out-Null
}

$appExists = $false
try {
  az webapp show --name $env:AZURE_APP_NAME --resource-group $env:AZURE_RESOURCE_GROUP --output none | Out-Null
  $appExists = $true
} catch {
  $appExists = $false
}

if ($appExists) {
  Write-Host "App Service already exists: $($env:AZURE_APP_NAME)"
} else {
  az webapp create `
    --name $env:AZURE_APP_NAME `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --plan $env:AZURE_APP_SERVICE_PLAN_NAME `
    --deployment-container-image-name "nginx:latest" `
    --output none | Out-Null
}

Write-Host "Done."
Write-Host "Resource group: $($env:AZURE_RESOURCE_GROUP)"
Write-Host "App Service: $($env:AZURE_APP_NAME)"
Write-Host "App Service plan: $($env:AZURE_APP_SERVICE_PLAN_NAME)"
Write-Host "ACR: $($env:AZURE_ACR_NAME)"
Write-Host "Storage account: $($env:AZURE_STORAGE_ACCOUNT_NAME)"
