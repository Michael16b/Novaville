$ErrorActionPreference = "Stop"

$requiredVars = @(
  "AZURE_RESOURCE_GROUP",
  "AZURE_LOCATION",
  "AZURE_APP_NAME",
  "AZURE_POSTGRES_SERVER_NAME",
  "DB_NAME",
  "DB_USER",
  "DB_PASSWORD"
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

$sku = if ($env:AZURE_POSTGRES_SKU) { $env:AZURE_POSTGRES_SKU } else { "Standard_B1ms" }
$storageGb = if ($env:AZURE_POSTGRES_STORAGE_GB) { $env:AZURE_POSTGRES_STORAGE_GB } else { "32" }
$version = if ($env:AZURE_POSTGRES_VERSION) { $env:AZURE_POSTGRES_VERSION } else { "15" }

$serverExists = $false
try {
  az postgres flexible-server show `
    --name $env:AZURE_POSTGRES_SERVER_NAME `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --output none | Out-Null
  $serverExists = $true
} catch {
  $serverExists = $false
}

if ($serverExists) {
  Write-Host "PostgreSQL server already exists: $($env:AZURE_POSTGRES_SERVER_NAME)"
} else {
  az postgres flexible-server create `
    --name $env:AZURE_POSTGRES_SERVER_NAME `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --location $env:AZURE_LOCATION `
    --admin-user $env:DB_USER `
    --admin-password $env:DB_PASSWORD `
    --sku-name $sku `
    --tier Burstable `
    --storage-size $storageGb `
    --version $version `
    --public-access Enabled | Out-Null
}

$dbExists = $false
try {
  az postgres flexible-server db show `
    --resource-group $env:AZURE_RESOURCE_GROUP `
    --server-name $env:AZURE_POSTGRES_SERVER_NAME `
    --name $env:DB_NAME `
    --output none | Out-Null
  $dbExists = $true
} catch {
  try {
    az postgres flexible-server db show `
      --resource-group $env:AZURE_RESOURCE_GROUP `
      --server-name $env:AZURE_POSTGRES_SERVER_NAME `
      --database-name $env:DB_NAME `
      --output none | Out-Null
    $dbExists = $true
  } catch {
    $dbExists = $false
  }
}

if ($dbExists) {
  Write-Host "Database already exists: $($env:DB_NAME)"
} else {
  $dbCreated = $false
  try {
    az postgres flexible-server db create `
      --resource-group $env:AZURE_RESOURCE_GROUP `
      --server-name $env:AZURE_POSTGRES_SERVER_NAME `
      --name $env:DB_NAME `
      --output none | Out-Null
    $dbCreated = $true
  } catch {
    $dbCreated = $false
  }

  if (-not $dbCreated) {
    az postgres flexible-server db create `
      --resource-group $env:AZURE_RESOURCE_GROUP `
      --server-name $env:AZURE_POSTGRES_SERVER_NAME `
      --database-name $env:DB_NAME `
      --output none | Out-Null
  }
}

$outboundIps = az webapp show `
  --name $env:AZURE_APP_NAME `
  --resource-group $env:AZURE_RESOURCE_GROUP `
  --query outboundIpAddresses `
  --output tsv

$ipList = $outboundIps -split ","
foreach ($ip in $ipList) {
  $ruleName = "appservice-" + ($ip -replace "\.", "-")
  $ruleCreated = $false
  try {
    az postgres flexible-server firewall-rule create `
      --resource-group $env:AZURE_RESOURCE_GROUP `
      --server-name $env:AZURE_POSTGRES_SERVER_NAME `
      --name $ruleName `
      --start-ip-address $ip `
      --end-ip-address $ip `
      --output none | Out-Null
    $ruleCreated = $true
  } catch {
    $ruleCreated = $false
  }

  if (-not $ruleCreated) {
    az postgres flexible-server firewall-rule create `
      --resource-group $env:AZURE_RESOURCE_GROUP `
      --name $env:AZURE_POSTGRES_SERVER_NAME `
      --rule-name $ruleName `
      --start-ip-address $ip `
      --end-ip-address $ip `
      --output none | Out-Null
  }
  Write-Host "Firewall rule added for $ip"
}

$dbHost = "$($env:AZURE_POSTGRES_SERVER_NAME).postgres.database.azure.com"
$dbUserFormatted = "$($env:DB_USER)@$($env:AZURE_POSTGRES_SERVER_NAME)"

Write-Host "Done."
Write-Host "DB_HOST=$dbHost"
Write-Host "DB_USER=$dbUserFormatted"
Write-Host "DATABASE_URL=postgres://${dbUserFormatted}:$($env:DB_PASSWORD)@$dbHost:5432/$($env:DB_NAME)?sslmode=require"
