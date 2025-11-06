#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Uploads large ARM template to Azure Storage and generates deployment URLs

.DESCRIPTION
    This script uploads the 9.6 MB mainTemplate.json to Azure Storage with public read access,
    then generates a direct deployment URL that can be used to deploy via Azure Portal.

.EXAMPLE
    ./upload-to-storage-for-deploy.ps1
#>

param(
    [string]$ResourceGroup = "aialz-dev",
    [string]$Location = "eastus2",
    [string]$TemplateFile = "./portal-package/mainTemplate.json",
    [string]$UiDefFile = "./portal-package/createUiDefinition.json"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Header { param($Text) Write-Host "`n========================================" -ForegroundColor Cyan; Write-Host $Text -ForegroundColor Cyan; Write-Host "========================================" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "✅ $Text" -ForegroundColor Green }
function Write-Info { param($Text) Write-Host "ℹ️  $Text" -ForegroundColor Blue }
function Write-Warning { param($Text) Write-Host "⚠️  $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "❌ $Text" -ForegroundColor Red }

Write-Header "🚀 Azure Storage Upload for Large Template Deployment"

# Auto-generate storage account name
$random = -join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
$StorageAccountName = "aimltemplate$random"

Write-Info "Configuration:"
Write-Host "  Storage Account: $StorageAccountName"
Write-Host "  Resource Group:  $ResourceGroup"
Write-Host "  Location:        $Location"
Write-Host ""

# Check files
if (!(Test-Path $TemplateFile)) {
    Write-Error "Template file not found: $TemplateFile"
    exit 1
}

if (!(Test-Path $UiDefFile)) {
    Write-Error "UI definition file not found: $UiDefFile"
    exit 1
}

$templateSize = (Get-Item $TemplateFile).Length / 1MB
Write-Info "Template size: $([math]::Round($templateSize, 2)) MB"

# Create resource group if needed
Write-Info "Checking resource group..."
$rgExists = az group show --name $ResourceGroup 2>$null
if (!$rgExists) {
    Write-Info "Creating resource group..."
    az group create --name $ResourceGroup --location $Location | Out-Null
    Write-Success "Resource group created"
} else {
    Write-Success "Resource group exists"
}

# Create storage account with public blob access allowed
Write-Header "Creating Storage Account"
Write-Info "Creating storage account: $StorageAccountName"
Write-Info "This may take 1-2 minutes..."

az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access true `
    --https-only true | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create storage account. Check for policy restrictions."
    exit 1
}

Write-Success "Storage account created"

# Assign Storage Blob Data Contributor role to current user
Write-Info "Assigning Storage Blob Data Contributor role..."
$currentUser = az ad signed-in-user show --query id -o tsv
$storageAccountId = az storage account show --name $StorageAccountName --resource-group $ResourceGroup --query id -o tsv

az role assignment create `
    --role "Storage Blob Data Contributor" `
    --assignee $currentUser `
    --scope $storageAccountId | Out-Null

Write-Info "Waiting 30 seconds for role assignment to propagate..."
Start-Sleep -Seconds 30
Write-Success "Role assigned"

# Create public container (using Azure AD auth instead of keys)
Write-Info "Creating public blob container..."
$containerName = "templates"
$createResult = az storage container create `
    --name $containerName `
    --account-name $StorageAccountName `
    --public-access blob `
    --auth-mode login 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Container creation failed: $createResult"
    Write-Info "Waiting 20 more seconds for role propagation..."
    Start-Sleep -Seconds 20
    Write-Info "Retrying container creation..."
    az storage container create `
        --name $containerName `
        --account-name $StorageAccountName `
        --public-access blob `
        --auth-mode login | Out-Null
}

Write-Success "Container created with public read access"
Write-Info "Waiting 10 seconds for container to be fully available..."
Start-Sleep -Seconds 10

# Upload template (using Azure AD auth)
Write-Header "Uploading Files to Azure Storage"
Write-Info "Uploading mainTemplate.json (9.6 MB)..."
Write-Info "This may take 30-60 seconds..."

$blobName = "mainTemplate.json"
az storage blob upload `
    --container-name $containerName `
    --name $blobName `
    --file $TemplateFile `
    --account-name $StorageAccountName `
    --auth-mode login `
    --overwrite true `
    --no-progress | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to upload template"
    exit 1
}

Write-Success "Template uploaded"

# Upload UI definition (using Azure AD auth)
Write-Info "Uploading createUiDefinition.json..."
$uiDefBlobName = "createUiDefinition.json"
az storage blob upload `
    --container-name $containerName `
    --name $uiDefBlobName `
    --file $UiDefFile `
    --account-name $StorageAccountName `
    --auth-mode login `
    --overwrite true `
    --no-progress | Out-Null

Write-Success "UI definition uploaded"

# Get public URLs
$templateUrl = "https://$StorageAccountName.blob.core.windows.net/$containerName/$blobName"
$uiDefUrl = "https://$StorageAccountName.blob.core.windows.net/$containerName/$uiDefBlobName"

Write-Header "✅ Upload Complete!"

Write-Host ""
Write-Info "📋 Public URLs (no authentication needed):"
Write-Host ""
Write-Host "Template URL:" -ForegroundColor Yellow
Write-Host "  $templateUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "UI Definition URL:" -ForegroundColor Yellow
Write-Host "  $uiDefUrl" -ForegroundColor Cyan
Write-Host ""

# Generate deployment URL
$deployUrl = "https://portal.azure.com/#create/Microsoft.Template/uri/" + [System.Web.HttpUtility]::UrlEncode($templateUrl) + "/createUIDefinitionUri/" + [System.Web.HttpUtility]::UrlEncode($uiDefUrl)

Write-Header "🚀 Deploy to Azure"
Write-Host ""
Write-Info "Click this URL to deploy with the custom wizard:"
Write-Host ""
Write-Host $deployUrl -ForegroundColor Green
Write-Host ""

# Save URLs to file
$urlFile = "./portal-package/deployment-urls.txt"
@"
AI/ML Landing Zone - Deployment URLs
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Storage Account: $StorageAccountName
Resource Group: $ResourceGroup
Container: $containerName (public read access)

=== PUBLIC URLS ===

Template URL:
$templateUrl

UI Definition URL:
$uiDefUrl

=== DEPLOY TO AZURE ===

Portal Deployment URL (click to deploy):
$deployUrl

=== ALTERNATIVE: Manual Upload ===

1. Go to: https://portal.azure.com/#create/Microsoft.Template
2. Click "Build your own template in the editor"
3. Click "Load file" and paste the Template URL above
4. Click "Edit UI definition"
5. Click "Load file" and paste the UI Definition URL above

=== CLEANUP ===

When done testing, delete the storage account:
az storage account delete --name $StorageAccountName --resource-group $ResourceGroup --yes

"@ | Out-File -FilePath $urlFile -Encoding UTF8

Write-Success "URLs saved to: $urlFile"
Write-Host ""

Write-Header "📚 Next Steps"
Write-Host ""
Write-Host "1. Click the deployment URL above (or copy from $urlFile)"
Write-Host "2. You'll see the Azure Portal with your 6-step custom wizard"
Write-Host "3. Select installation profile (Full/Core/Custom)"
Write-Host "4. Fill in settings and deploy"
Write-Host ""
Write-Warning "Storage Account Cost: ~`$0.02/month for hosting the template"
Write-Info "Delete the storage account when you no longer need the deployment URL"
Write-Host ""

# Try to open browser (Windows only)
if ($IsWindows -or $env:OS -match "Windows") {
    $response = Read-Host "Open deployment URL in browser now? (y/N)"
    if ($response -eq 'y') {
        Start-Process $deployUrl
        Write-Success "Browser opened!"
    }
}

Write-Success "🎉 Ready to deploy!"
