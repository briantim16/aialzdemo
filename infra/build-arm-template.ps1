# Build script to compile Bicep to ARM template for Azure Portal deployment
# This script handles the large template size by using template specs

#Requires -Version 7.0

param(
    [switch]$SkipWrappers = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 AI/ML Landing Zone - ARM Template Build Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$ScriptDir = $PSScriptRoot
$InfraDir = $ScriptDir
$OutputDir = Join-Path $ScriptDir "arm-output"
$MainBicep = Join-Path $InfraDir "main.bicep"
$MainArm = Join-Path $OutputDir "mainTemplate.json"
$UiDef = Join-Path $InfraDir "createUiDefinition.json"
$WrappersDir = Join-Path $InfraDir "wrappers"

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found. Please install: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Azure CLI installed" -ForegroundColor Green

# Check if logged in
try {
    $null = az account show 2>&1
    Write-Host "✅ Logged in to Azure" -ForegroundColor Green
}
catch {
    Write-Host "❌ Not logged in to Azure. Run 'az login' first" -ForegroundColor Red
    exit 1
}

# Create output directory
Write-Host ""
Write-Host "📁 Creating output directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir "nestedTemplates") | Out-Null
Write-Host "✅ Output directory created: $OutputDir" -ForegroundColor Green

# Compile main Bicep template
Write-Host ""
Write-Host "🔨 Compiling main Bicep template..." -ForegroundColor Yellow

try {
    az bicep build --file $MainBicep --outfile $MainArm
    Write-Host "✅ Main template compiled successfully" -ForegroundColor Green
    
    # Check template size
    $TemplateSize = (Get-Item $MainArm).Length
    $TemplateSizeMB = [math]::Round($TemplateSize / 1MB, 2)
    Write-Host "📏 Template size: $TemplateSizeMB MB" -ForegroundColor Cyan
    
    if ($TemplateSize -gt 4MB) {
        Write-Host "⚠️  WARNING: Template exceeds 4 MB limit ($TemplateSizeMB MB)" -ForegroundColor Yellow
        Write-Host "    You'll need to use Template Specs or linked templates for deployment" -ForegroundColor Yellow
    }
    else {
        Write-Host "✅ Template size is within 4 MB limit" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Failed to compile main template" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Compile wrapper modules
if (-not $SkipWrappers) {
    Write-Host ""
    Write-Host "🔨 Compiling wrapper modules..." -ForegroundColor Yellow
    
    $WrapperCount = 0
    $WrapperErrors = 0
    
    Get-ChildItem -Path $WrappersDir -Filter "*.bicep" | ForEach-Object {
        $WrapperName = $_.BaseName
        $WrapperJson = Join-Path $OutputDir "nestedTemplates" "$WrapperName.json"
        
        try {
            az bicep build --file $_.FullName --outfile $WrapperJson 2>$null
            $WrapperCount++
            Write-Host "  ✅ $WrapperName" -ForegroundColor Green
        }
        catch {
            $WrapperErrors++
            Write-Host "  ❌ $WrapperName (failed to compile)" -ForegroundColor Red
        }
    }
    
    Write-Host "✅ Compiled $WrapperCount wrapper modules" -ForegroundColor Green
    if ($WrapperErrors -gt 0) {
        Write-Host "⚠️  $WrapperErrors wrapper modules failed to compile" -ForegroundColor Yellow
    }
}
else {
    Write-Host ""
    Write-Host "⏭️  Skipping wrapper module compilation" -ForegroundColor Yellow
}

# Copy UI definition
Write-Host ""
Write-Host "📋 Copying UI definition..." -ForegroundColor Yellow

if (Test-Path $UiDef) {
    Copy-Item $UiDef -Destination (Join-Path $OutputDir "createUiDefinition.json")
    Write-Host "✅ UI definition copied" -ForegroundColor Green
}
else {
    Write-Host "❌ UI definition not found: $UiDef" -ForegroundColor Red
    exit 1
}

# Create README for deployment package
Write-Host ""
Write-Host "📝 Creating deployment package README..." -ForegroundColor Yellow

$ReadmeContent = @'
# AI/ML Landing Zone - Azure Portal Deployment Package

This package contains the compiled ARM templates and custom UI definition for deploying the AI/ML Landing Zone through the Azure Portal.

## Contents

- `mainTemplate.json` - Main ARM template (compiled from Bicep)
- `createUiDefinition.json` - Custom Azure Portal UI wizard
- `nestedTemplates/` - Compiled wrapper modules (if template size exceeds limits)

## Deployment Options

### Option 1: Template Specs (Recommended)

```powershell
# Create template spec
az ts create `
  --name "AI-ML-Landing-Zone" `
  --version "1.0.0" `
  --resource-group <your-template-specs-rg> `
  --location <region> `
  --template-file mainTemplate.json `
  --ui-form-definition createUiDefinition.json `
  --description "Secure AI/ML Landing Zone" `
  --display-name "AI/ML Landing Zone"
```

Then deploy via Azure Portal > Template Specs.

### Option 2: Direct Portal Link

1. Upload `mainTemplate.json` and `createUiDefinition.json` to Azure Blob Storage with public access
2. Get blob URLs
3. Create Portal link:

```
https://portal.azure.com/#create/Microsoft.Template/uri/<template-url-encoded>/createUIDefinitionUri/<ui-def-url-encoded>
```

### Option 3: Azure CLI/PowerShell

```powershell
az deployment group create `
  --resource-group <your-rg> `
  --template-file mainTemplate.json `
  --parameters '@parameters.json'
```

## Template Size Warning

⚠️ If the main template exceeds 4 MB, you must use one of these approaches:

1. **Template Specs** - Handles large templates automatically
2. **Linked Templates** - Upload nested templates to storage and reference via templateLink
3. **Module Flattening** - Reduce template size (may lose modularity)

## Installation Profiles

The UI definition includes three pre-configured profiles:

- **Full** - All 28 components (complete platform)
- **Core** - 11 essential components (development)
- **Custom** - User selects individual components

See `PORTAL_DEPLOYMENT.md` in the parent directory for detailed documentation.

## Support

- Repository: https://github.com/Azure/bicep-avm-ptn-aiml-landing-zone
- Documentation: ../docs/
'@

Set-Content -Path (Join-Path $OutputDir "README.md") -Value $ReadmeContent
Write-Host "✅ README created" -ForegroundColor Green

# Generate parameter file template
Write-Host ""
Write-Host "📝 Creating parameter file template..." -ForegroundColor Yellow

$ParametersContent = @'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "eastus2"
    },
    "baseName": {
      "value": ""
    },
    "resourceToken": {
      "value": ""
    },
    "enableTelemetry": {
      "value": true
    },
    "flagPlatformLandingZone": {
      "value": false
    },
    "deployToggles": {
      "value": {
        "logAnalytics": true,
        "appInsights": true,
        "containerEnv": true,
        "containerRegistry": true,
        "cosmosDb": true,
        "keyVault": true,
        "storageAccount": true,
        "searchService": true,
        "groundingWithBingSearch": true,
        "appConfig": true,
        "apiManagement": true,
        "applicationGateway": true,
        "applicationGatewayPublicIp": true,
        "firewall": true,
        "containerApps": true,
        "buildVm": true,
        "bastionHost": true,
        "jumpVm": true,
        "virtualNetwork": true,
        "wafPolicy": true,
        "agentNsg": true,
        "peNsg": true,
        "applicationGatewayNsg": true,
        "apiManagementNsg": true,
        "acaEnvironmentNsg": true,
        "jumpboxNsg": true,
        "devopsBuildAgentsNsg": true
      }
    },
    "resourceIds": {
      "value": {}
    },
    "tags": {
      "value": {}
    }
  }
}
'@

Set-Content -Path (Join-Path $OutputDir "parameters.template.json") -Value $ParametersContent
Write-Host "✅ Parameter template created" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✨ Build Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Output location: $OutputDir" -ForegroundColor White
Write-Host ""
Write-Host "📄 Files created:" -ForegroundColor White
Write-Host "  - mainTemplate.json (ARM template)" -ForegroundColor Gray
Write-Host "  - createUiDefinition.json (Portal UI)" -ForegroundColor Gray
if (-not $SkipWrappers) {
    Write-Host "  - nestedTemplates/*.json ($WrapperCount modules)" -ForegroundColor Gray
}
Write-Host "  - README.md" -ForegroundColor Gray
Write-Host "  - parameters.template.json" -ForegroundColor Gray
Write-Host ""
Write-Host "🎯 Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Test UI definition in sandbox:" -ForegroundColor White
Write-Host "     https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Create Template Spec:" -ForegroundColor White
Write-Host "     cd $OutputDir" -ForegroundColor Gray
Write-Host "     az ts create --name 'AI-ML-LZ' --version '1.0.0' \" -ForegroundColor Gray
Write-Host "       --resource-group <rg-name> --location <region> \" -ForegroundColor Gray
Write-Host "       --template-file mainTemplate.json \" -ForegroundColor Gray
Write-Host "       --ui-form-definition createUiDefinition.json" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Or deploy directly:" -ForegroundColor White
Write-Host "     az deployment group create \" -ForegroundColor Gray
Write-Host "       --resource-group <rg-name> \" -ForegroundColor Gray
Write-Host "       --template-file mainTemplate.json \" -ForegroundColor Gray
Write-Host "       --parameters '@parameters.template.json'" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 Full documentation: $InfraDir\PORTAL_DEPLOYMENT.md" -ForegroundColor Cyan
Write-Host ""
