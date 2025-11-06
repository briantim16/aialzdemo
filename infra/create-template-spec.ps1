#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Creates an Azure Template Spec for the AI/ML Landing Zone

.DESCRIPTION
    This script creates a Template Spec in Azure to overcome the 4 MB Portal deployment limit.
    Template Specs have no size limit and are the recommended way to deploy large templates.

.PARAMETER TemplateSpecName
    Name of the Template Spec. Default: AI-ML-Landing-Zone

.PARAMETER Version
    Version of the Template Spec. Default: 1.0.0

.PARAMETER ResourceGroup
    Resource group for the Template Spec. Default: template-specs-rg

.PARAMETER Location
    Azure region for the Template Spec. Default: eastus2

.EXAMPLE
    ./create-template-spec.ps1

.EXAMPLE
    ./create-template-spec.ps1 -Version "1.1.0"

.EXAMPLE
    ./create-template-spec.ps1 -ResourceGroup "my-specs-rg" -Location "westus2"
#>

param(
    [string]$TemplateSpecName = "AI-ML-Landing-Zone",
    [string]$Version = "1.0.0",
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

Write-Header "🚀 Azure Template Spec Creator"

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
    $currentSubId = az account show --query id -o tsv
    Write-Success "Logged in to: $currentSub"
} catch {
    Write-Warning "Not logged in to Azure. Running az login..."
    az login
    $currentSub = az account show --query name -o tsv
    $currentSubId = az account show --query id -o tsv
}

# Show configuration
Write-Header "Configuration"
Write-Host "Template Spec Name:    " -NoNewline; Write-Host $TemplateSpecName -ForegroundColor Yellow
Write-Host "Version:               " -NoNewline; Write-Host $Version -ForegroundColor Yellow
Write-Host "Resource Group:        " -NoNewline; Write-Host $ResourceGroup -ForegroundColor Yellow
Write-Host "Location:              " -NoNewline; Write-Host $Location -ForegroundColor Yellow
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
try {
    az group show --name $ResourceGroup 2>$null | Out-Null
    Write-Success "Resource group exists: $ResourceGroup"
} catch {
    Write-Warning "Resource group doesn't exist. Creating..."
    az group create --name $ResourceGroup --location $Location
    Write-Success "Resource group created"
}

# Check if Template Spec exists
Write-Header "Template Spec Setup"
Write-Info "Checking if Template Spec exists..."
$existingSpec = $null
try {
    $existingSpec = az ts show --name $TemplateSpecName --resource-group $ResourceGroup --version $Version 2>$null | ConvertFrom-Json
} catch {
    # Doesn't exist - that's fine
}

$command = "create"
if ($existingSpec) {
    Write-Warning "Template Spec version $Version already exists"
    $response = Read-Host "Update existing version? (y/N)"
    if ($response -ne 'y') {
        Write-Warning "Operation cancelled. Consider creating a new version (e.g., 1.0.1)"
        exit 0
    }
    $command = "update"
}

# Create/Update Template Spec
Write-Header "Creating Template Spec"
Write-Info "This may take a few minutes for large templates..."
Write-Host ""

try {
    if ($command -eq "create") {
        az ts create `
            --name $TemplateSpecName `
            --version $Version `
            --location $Location `
            --resource-group $ResourceGroup `
            --template-file $TemplateFile `
            --ui-form-definition $UiDefFile `
            --description "Secure AI/ML Landing Zone with network isolation, private endpoints, and Azure AI Foundry. Includes Full (28 components), Core (11 components), and Custom installation profiles." `
            --display-name "AI/ML Landing Zone"
    } else {
        az ts update `
            --name $TemplateSpecName `
            --version $Version `
            --resource-group $ResourceGroup `
            --template-file $TemplateFile `
            --ui-form-definition $UiDefFile
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Template Spec creation failed"
    }

    Write-Header "✅ Template Spec Created Successfully!"

    # Get Template Spec ID
    $templateSpecId = az ts show `
        --name $TemplateSpecName `
        --resource-group $ResourceGroup `
        --version $Version `
        --query "id" -o tsv

    Write-Host ""
    Write-Info "📋 Template Spec Details:"
    Write-Host "   Name:     " -NoNewline; Write-Host $TemplateSpecName -ForegroundColor Yellow
    Write-Host "   Version:  " -NoNewline; Write-Host $Version -ForegroundColor Yellow
    Write-Host "   Location: " -NoNewline; Write-Host $Location -ForegroundColor Yellow
    Write-Host ""
    Write-Info "🔗 Template Spec ID:"
    Write-Host "   " -NoNewline; Write-Host $templateSpecId -ForegroundColor Yellow

    Write-Header "🚀 How to Deploy"

    Write-Host ""
    Write-Info "Option 1: Azure Portal"
    Write-Host "   1. Navigate to: https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Resources%2FtemplateSpecs"
    Write-Host "   2. Find: $TemplateSpecName"
    Write-Host "   3. Click 'Deploy'"
    Write-Host "   4. Fill in the custom wizard"

    Write-Host ""
    Write-Info "Option 2: Azure CLI"
    Write-Host "   # Create target resource group"
    Write-Host "   az group create --name `"aiml-landing-zone-rg`" --location `"$Location`""
    Write-Host ""
    Write-Host "   # Deploy Template Spec"
    Write-Host "   az deployment group create \"
    Write-Host "     --resource-group `"aiml-landing-zone-rg`" \"
    Write-Host "     --template-spec `"$templateSpecId`""

    Write-Host ""
    Write-Info "Option 3: PowerShell"
    Write-Host "   New-AzResourceGroupDeployment \"
    Write-Host "     -ResourceGroupName `"aiml-landing-zone-rg`" \"
    Write-Host "     -TemplateSpecId `"$templateSpecId`""

    Write-Header "📚 Next Steps"

    Write-Host "1. Test deployment in a test subscription"
    Write-Host "2. Grant users access to the Template Spec:"
    Write-Host "   az role assignment create \"
    Write-Host "     --assignee `"user@company.com`" \"
    Write-Host "     --role `"Template Spec Reader`" \"
    Write-Host "     --scope `"$templateSpecId`""
    Write-Host ""
    Write-Host "3. Document the Template Spec ID for your team"
    Write-Host "4. Create new versions for updates (1.0.1, 1.1.0, etc.)"
    Write-Host ""

    Write-Success "🎉 Template Spec ready for deployment!"

} catch {
    Write-Header "❌ Template Spec Creation Failed"
    Write-Error $_.Exception.Message
    Write-Host ""
    Write-Info "Check the error message above for details."
    exit 1
}
