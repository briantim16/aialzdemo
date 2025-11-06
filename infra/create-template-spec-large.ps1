#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Creates an Azure Template Spec for large templates (>4 MB)

.DESCRIPTION
    This script handles templates larger than 4 MB by uploading to Azure Storage first,
    then creating a Template Spec that references the storage location.

.PARAMETER TemplateSpecName
    Name of the Template Spec. Default: AI-ML-Landing-Zone

.PARAMETER Version
    Version of the Template Spec. Default: 1.0.0

.PARAMETER ResourceGroup
    Resource group for the Template Spec. Default: aialz-dev

.PARAMETER Location
    Azure region. Default: eastus2

.PARAMETER StorageAccountName
    Storage account for large template (auto-generated if not provided)

.EXAMPLE
    ./create-template-spec-large.ps1
#>

param(
    [string]$TemplateSpecName = "AI-ML-Landing-Zone",
    [string]$Version = "1.0.0",
    [string]$ResourceGroup = "aialz-dev",
    [string]$Location = "eastus2",
    [string]$TemplateFile = "./portal-package/mainTemplate.json",
    [string]$UiDefFile = "./portal-package/createUiDefinition.json",
    [string]$StorageAccountName = ""
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Header { param($Text) Write-Host "`n========================================" -ForegroundColor Cyan; Write-Host $Text -ForegroundColor Cyan; Write-Host "========================================" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "✅ $Text" -ForegroundColor Green }
function Write-Info { param($Text) Write-Host "ℹ️  $Text" -ForegroundColor Blue }
function Write-Warning { param($Text) Write-Host "⚠️  $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "❌ $Text" -ForegroundColor Red }

Write-Header "🚀 Azure Template Spec Creator (Large Template Support)"

# Auto-generate storage account name if not provided
if ([string]::IsNullOrEmpty($StorageAccountName)) {
    $random = -join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
    $StorageAccountName = "templatespecs$random"
}

# Check files
Write-Info "Checking files..."
if (!(Test-Path $TemplateFile)) {
    Write-Error "Template file not found: $TemplateFile"
    Write-Warning "Run ./package-for-portal.ps1 first to create the template"
    exit 1
}

if (!(Test-Path $UiDefFile)) {
    Write-Error "UI definition file not found: $UiDefFile"
    exit 1
}

$templateSize = (Get-Item $TemplateFile).Length / 1MB
$uiDefSize = (Get-Item $UiDefFile).Length / 1KB

Write-Success "Template file found: $([math]::Round($templateSize, 2)) MB"
Write-Success "UI definition file found: $([math]::Round($uiDefSize, 2)) KB"

if ($templateSize -gt 4) {
    Write-Warning "Template exceeds 4 MB - will upload to Azure Storage first"
}

# Check Azure CLI
Write-Info "Checking Azure CLI..."
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI not found. Install from: https://aka.ms/azure-cli"
    exit 1
}
Write-Success "Azure CLI found: $(az version --query '\"azure-cli\"' -o tsv)"

# Check login
Write-Info "Checking Azure login..."
try {
    $currentSub = az account show --query name -o tsv
    Write-Success "Logged in to: $currentSub"
} catch {
    Write-Warning "Not logged in to Azure. Running az login..."
    az login
    $currentSub = az account show --query name -o tsv
}

# Show configuration
Write-Header "Configuration"
Write-Host "Template Spec Name:    " -NoNewline; Write-Host $TemplateSpecName -ForegroundColor Yellow
Write-Host "Version:               " -NoNewline; Write-Host $Version -ForegroundColor Yellow
Write-Host "Resource Group:        " -NoNewline; Write-Host $ResourceGroup -ForegroundColor Yellow
Write-Host "Location:              " -NoNewline; Write-Host $Location -ForegroundColor Yellow
Write-Host "Storage Account:       " -NoNewline; Write-Host $StorageAccountName -ForegroundColor Yellow
Write-Host "Subscription:          " -NoNewline; Write-Host $currentSub -ForegroundColor Yellow
Write-Host "Template Size:         " -NoNewline; Write-Host "$([math]::Round($templateSize, 2)) MB" -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Continue with these settings? (y/N)"
if ($response -ne 'y') {
    Write-Warning "Operation cancelled"
    exit 0
}

# Create resource group if needed
Write-Header "Resource Group Setup"
Write-Info "Checking resource group..."
$rgExists = az group show --name $ResourceGroup 2>$null
if (!$rgExists) {
    Write-Warning "Resource group doesn't exist. Creating..."
    az group create --name $ResourceGroup --location $Location | Out-Null
    Write-Success "Resource group created"
} else {
    Write-Success "Resource group exists: $ResourceGroup"
}

# Create storage account for large template
Write-Header "Storage Account Setup"
Write-Info "Checking storage account..."
$storageExists = az storage account show --name $StorageAccountName --resource-group $ResourceGroup 2>$null
if (!$storageExists) {
    Write-Info "Creating storage account: $StorageAccountName"
    az storage account create `
        --name $StorageAccountName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --allow-blob-public-access false | Out-Null
    Write-Success "Storage account created"
} else {
    Write-Success "Storage account exists"
}

# Get storage account key
Write-Info "Getting storage account key..."
$storageKey = az storage account keys list `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroup `
    --query "[0].value" -o tsv

# Create container
Write-Info "Creating blob container..."
$containerName = "templatespecs"
az storage container create `
    --name $containerName `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --auth-mode key 2>$null | Out-Null
Write-Success "Container ready: $containerName"

# Upload template to blob storage
Write-Header "Uploading Template to Azure Storage"
Write-Info "Uploading mainTemplate.json..."
$blobName = "AI-ML-Landing-Zone-$Version-template.json"
az storage blob upload `
    --container-name $containerName `
    --name $blobName `
    --file $TemplateFile `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --overwrite true | Out-Null
Write-Success "Template uploaded to blob storage"

# Generate SAS token (1 year expiry)
Write-Info "Generating SAS token..."
$expiryDate = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
$templateSasToken = az storage blob generate-sas `
    --container-name $containerName `
    --name $blobName `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --permissions r `
    --expiry $expiryDate `
    --https-only -o tsv

$templateUri = "https://$StorageAccountName.blob.core.windows.net/$containerName/$blobName`?$templateSasToken"
Write-Success "SAS token generated (expires: $expiryDate)"

# Upload UI definition to blob storage
Write-Info "Uploading createUiDefinition.json..."
$uiDefBlobName = "AI-ML-Landing-Zone-$Version-ui.json"
az storage blob upload `
    --container-name $containerName `
    --name $uiDefBlobName `
    --file $UiDefFile `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --overwrite true | Out-Null

$uiDefSasToken = az storage blob generate-sas `
    --container-name $containerName `
    --name $uiDefBlobName `
    --account-name $StorageAccountName `
    --account-key $storageKey `
    --permissions r `
    --expiry $expiryDate `
    --https-only -o tsv

$uiDefUri = "https://$StorageAccountName.blob.core.windows.net/$containerName/$uiDefBlobName`?$uiDefSasToken"
Write-Success "UI definition uploaded"

# Create wrapper template for Template Spec
Write-Header "Creating Template Spec"
Write-Info "Creating wrapper template..."
$wrapperTemplate = @{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
    contentVersion = '1.0.0.0'
    metadata = @{
        description = 'Secure AI/ML Landing Zone with network isolation, private endpoints, and Azure AI Foundry. Includes Full (28 components), Core (11 components), and Custom installation profiles.'
    }
    parameters = @{}
    resources = @(
        @{
            type = 'Microsoft.Resources/deployments'
            apiVersion = '2021-04-01'
            name = 'linkedTemplate'
            properties = @{
                mode = 'Incremental'
                templateLink = @{
                    uri = $templateUri
                }
                parameters = @{}
            }
        }
    )
}

$wrapperFile = "./portal-package/wrapper-template.json"
$wrapperTemplate | ConvertTo-Json -Depth 50 | Set-Content $wrapperFile
Write-Success "Wrapper template created"

# Create Template Spec with wrapper (small file)
Write-Info "Creating Template Spec (this may take a moment)..."
try {
    az ts create `
        --name $TemplateSpecName `
        --version $Version `
        --location $Location `
        --resource-group $ResourceGroup `
        --template-file $wrapperFile `
        --ui-form-definition $UiDefFile `
        --description "Secure AI/ML Landing Zone with network isolation, private endpoints, and Azure AI Foundry. Includes Full (28 components), Core (11 components), and Custom installation profiles." `
        --display-name "AI/ML Landing Zone" | Out-Null

    Write-Header "✅ Template Spec Created Successfully!"

    # Get Template Spec ID
    $templateSpecId = az ts show `
        --name $TemplateSpecName `
        --resource-group $ResourceGroup `
        --version $Version `
        --query "id" -o tsv

    Write-Host ""
    Write-Info "📋 Template Spec Details:"
    Write-Host "   Name:            " -NoNewline; Write-Host $TemplateSpecName -ForegroundColor Yellow
    Write-Host "   Version:         " -NoNewline; Write-Host $Version -ForegroundColor Yellow
    Write-Host "   Resource Group:  " -NoNewline; Write-Host $ResourceGroup -ForegroundColor Yellow
    Write-Host "   Storage Account: " -NoNewline; Write-Host $StorageAccountName -ForegroundColor Yellow
    Write-Host ""
    Write-Info "🔗 Template Spec ID:"
    Write-Host "   " -NoNewline; Write-Host $templateSpecId -ForegroundColor Yellow

    Write-Header "🚀 How to Deploy"

    Write-Host ""
    Write-Info "Option 1: Azure Portal (Recommended)"
    Write-Host "   1. Navigate to: https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Resources%2FtemplateSpecs"
    Write-Host "   2. Find: $TemplateSpecName"
    Write-Host "   3. Select version: $Version"
    Write-Host "   4. Click 'Deploy'"
    Write-Host "   5. Fill in the custom 6-step wizard"

    Write-Host ""
    Write-Info "Option 2: Azure CLI"
    Write-Host "   # Create target resource group"
    Write-Host "   az group create --name `"aiml-prod-rg`" --location `"$Location`""
    Write-Host ""
    Write-Host "   # Deploy Template Spec"
    Write-Host "   az deployment group create \"
    Write-Host "     --resource-group `"aiml-prod-rg`" \"
    Write-Host "     --template-spec `"$templateSpecId`""

    Write-Header "📚 Important Notes"
    Write-Host ""
    Write-Warning "Storage Account Dependencies:"
    Write-Host "   - Storage account: $StorageAccountName" -ForegroundColor Yellow
    Write-Host "   - Container: $containerName" -ForegroundColor Yellow
    Write-Host "   - SAS token expiry: $expiryDate" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   ⚠️  Do NOT delete the storage account or blobs!" -ForegroundColor Red
    Write-Host "   ⚠️  Renew SAS tokens before expiry!" -ForegroundColor Red
    Write-Host ""
    Write-Info "To renew SAS tokens, run this script again with the same version"
    Write-Host "or increment the version (e.g., 1.0.1) for updates."
    Write-Host ""

    Write-Success "🎉 Template Spec ready for deployment!"
    Write-Host ""

} catch {
    Write-Header "❌ Template Spec Creation Failed"
    Write-Error $_.Exception.Message
    Write-Host ""
    Write-Info "Check the error message above for details."
    exit 1
}
