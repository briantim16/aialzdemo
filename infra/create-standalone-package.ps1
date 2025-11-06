#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Creates a standalone deployment repository package

.DESCRIPTION
    Copies all necessary files to create a self-contained GitHub repository
    for deploying the AI/ML Landing Zone with custom UI.

.PARAMETER TargetPath
    Path where the new repository structure will be created

.PARAMETER IncludeSource
    Include Bicep source files and build scripts (default: true)

.PARAMETER MinimalPackage
    Create minimal package with only deployment files (default: false)

.EXAMPLE
    ./create-standalone-package.ps1 -TargetPath "C:\repos\aiml-landing-zone-deploy"

.EXAMPLE
    ./create-standalone-package.ps1 -TargetPath "C:\repos\aiml-deploy" -MinimalPackage
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,
    
    [bool]$IncludeSource = $true,
    
    [switch]$MinimalPackage
)

$ErrorActionPreference = "Stop"

# Color output
function Write-Header { param($Text) Write-Host "`n========================================" -ForegroundColor Cyan; Write-Host $Text -ForegroundColor Cyan; Write-Host "========================================" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "✅ $Text" -ForegroundColor Green }
function Write-Info { param($Text) Write-Host "ℹ️  $Text" -ForegroundColor Blue }
function Write-Warning { param($Text) Write-Host "⚠️  $Text" -ForegroundColor Yellow }

Write-Header "📦 Creating Standalone Deployment Repository"

$sourceRoot = $PSScriptRoot
$portalPackage = Join-Path $sourceRoot "portal-package"

# Check source files exist
if (!(Test-Path "$portalPackage\mainTemplate.json")) {
    Write-Warning "mainTemplate.json not found. Running package-for-portal.ps1..."
    & "$sourceRoot\package-for-portal.ps1"
}

# Create target directory
Write-Info "Creating target directory: $TargetPath"
New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
Write-Success "Directory created"

if ($MinimalPackage) {
    Write-Header "📦 Creating Minimal Package (Portal Deployment Only)"
    
    # Copy essential files
    Write-Info "Copying deployment files..."
    Copy-Item "$portalPackage\mainTemplate.json" "$TargetPath\" -Force
    Copy-Item "$portalPackage\createUiDefinition.json" "$TargetPath\" -Force
    
    # Create minimal README
    $readmeContent = @'
# AI/ML Landing Zone - Azure Portal Deployment

Deploy a secure AI/ML Landing Zone with a custom 6-step wizard.

## 🚀 Deploy to Azure

**After pushing this repo to GitHub, update the URLs below with your org/repo:**

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2FYOUR-REPO%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2FYOUR-REPO%2Fmain%2FcreateUiDefinition.json)

## 📦 Installation Profiles

### Full Profile (28 components)
- Complete AI/ML platform with networking, security, and all enterprise features
- Deployment time: ~50 minutes

### Core Profile (11 components)
- Essential AI/ML services: AI Search, Cosmos DB, Storage, Key Vault, Container Registry
- Deployment time: ~25 minutes

### Custom Profile
- Select individual components to match your requirements

## 📋 What Gets Deployed

- **Networking**: Virtual Network, NSGs, Application Gateway (optional), Azure Firewall (optional)
- **AI/ML Services**: AI Search, Cosmos DB, Storage Account, Key Vault, App Configuration
- **Observability**: Log Analytics, Application Insights
- **Container Platform**: Container Registry, Container Apps (optional)
- **Security & Access**: Bastion (optional), Jump VM (optional), Build VM (optional)
- **API Management**: Optional API gateway
- **Additional**: Bing Search grounding (optional)

## 🛠️ Deployment Steps

1. Click the **Deploy to Azure** button
2. Sign in to Azure Portal
3. Select subscription and resource group
4. Choose installation profile (Full/Core/Custom)
5. Configure network settings
6. Review and deploy

## 📖 Requirements

- Azure subscription with Contributor or Owner permissions
- Sufficient quota for selected resources

## 🔗 Alternative Deployment Methods

### Azure CLI
```bash
az deployment group create \
  --resource-group <your-rg> \
  --template-file mainTemplate.json
```

### PowerShell
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName <your-rg> `
  -TemplateFile mainTemplate.json
```

## ⚠️ Important Notes

- Repository must be **PUBLIC** for the Deploy to Azure button to work
- Files must be committed to the **main** branch (or update URL)
- Template size: 9.6 MB (works fine on GitHub)
- Custom UI is fully functional

## 📄 License

MIT License - See LICENSE file
'@
    
    $readmeContent | Out-File -FilePath "$TargetPath\README.md" -Encoding UTF8
    
    # Create .gitignore
    @'
# Azure
*.log
.azure/

# OS
.DS_Store
Thumbs.db
'@ | Out-File -FilePath "$TargetPath\.gitignore" -Encoding UTF8
    
    Write-Success "Minimal package created"
    
} else {
    Write-Header "📦 Creating Full Development Package"
    
    # Copy deployment files
    Write-Info "Copying deployment files..."
    Copy-Item "$portalPackage\mainTemplate.json" "$TargetPath\" -Force
    Copy-Item "$portalPackage\createUiDefinition.json" "$TargetPath\" -Force
    Write-Success "Deployment files copied"
    
    if ($IncludeSource) {
        # Copy source Bicep files
        Write-Info "Copying Bicep source files..."
        Copy-Item "$sourceRoot\main.bicep" "$TargetPath\" -Force -ErrorAction SilentlyContinue
        Copy-Item "$sourceRoot\main.bicepparam" "$TargetPath\" -Force -ErrorAction SilentlyContinue
        
        # Copy build scripts
        Write-Info "Copying build scripts..."
        Copy-Item "$sourceRoot\build-arm-template.ps1" "$TargetPath\" -Force -ErrorAction SilentlyContinue
        Copy-Item "$sourceRoot\build-arm-template.sh" "$TargetPath\" -Force -ErrorAction SilentlyContinue
        Copy-Item "$sourceRoot\package-for-portal.ps1" "$TargetPath\" -Force -ErrorAction SilentlyContinue
        Copy-Item "$sourceRoot\generate-github-deploy-url.ps1" "$TargetPath\" -Force -ErrorAction SilentlyContinue
        
        # Copy dependencies
        Write-Info "Copying Bicep modules..."
        if (Test-Path "$sourceRoot\common") {
            Copy-Item "$sourceRoot\common" "$TargetPath\common" -Recurse -Force
        }
        if (Test-Path "$sourceRoot\components") {
            Copy-Item "$sourceRoot\components" "$TargetPath\components" -Recurse -Force
        }
        if (Test-Path "$sourceRoot\wrappers") {
            Copy-Item "$sourceRoot\wrappers" "$TargetPath\wrappers" -Recurse -Force
        }
        
        Write-Success "Source files and modules copied"
    }
    
    # Copy documentation
    Write-Info "Copying documentation..."
    $parentDir = Split-Path $sourceRoot -Parent
    if (Test-Path "$parentDir\README.md") {
        Copy-Item "$parentDir\README.md" "$TargetPath\README-Original.md" -Force
    }
    if (Test-Path "$parentDir\docs") {
        Copy-Item "$parentDir\docs" "$TargetPath\docs" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Create deployment README
    $deployReadme = @'
# AI/ML Landing Zone - Deployment Repository

This repository contains everything needed to deploy a secure AI/ML Landing Zone to Azure.

## 🚀 Quick Deploy

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2FYOUR-REPO%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2FYOUR-REPO%2Fmain%2FcreateUiDefinition.json)

**⚠️ Update `YOUR-ORG/YOUR-REPO` in the URL above after pushing to GitHub**

## 📦 Repository Contents

- `mainTemplate.json` - Compiled ARM template (9.6 MB)
- `createUiDefinition.json` - Custom 6-step wizard UI
- `main.bicep` - Source Bicep template
- `main.bicepparam` - Default parameters
- `build-arm-template.ps1` - Rebuild script (PowerShell)
- `generate-github-deploy-url.ps1` - Generate deploy URL
- `common/`, `components/`, `wrappers/` - Bicep modules

## 🛠️ Making Changes

To modify the deployment:

1. Edit `main.bicep` or module files
2. Run rebuild: `./build-arm-template.ps1`
3. Commit updated `mainTemplate.json`
4. Push to GitHub

## 🔗 Generate Deploy URL

After pushing to your GitHub repo:

```powershell
./generate-github-deploy-url.ps1 -GitHubOrg "YOUR-ORG" -GitHubRepo "YOUR-REPO"
```

This generates the Deploy to Azure button URL.

## 📖 Documentation

- See `docs/` folder for detailed documentation
- `README-Original.md` - Original project README

## 📄 License

MIT License
'@
    
    $deployReadme | Out-File -FilePath "$TargetPath\README.md" -Encoding UTF8
    
    # Create .gitignore
    @'
# Azure
*.log
.azure/

# Build outputs (uncomment to not commit compiled template)
# mainTemplate.json

# OS
.DS_Store
Thumbs.db

# VS Code
.vscode/
'@ | Out-File -FilePath "$TargetPath\.gitignore" -Encoding UTF8
    
    Write-Success "Full package created"
}

# Show summary
Write-Header "📊 Package Summary"

$files = Get-ChildItem -Path $TargetPath -Recurse -File
$totalSize = ($files | Measure-Object -Property Length -Sum).Sum / 1MB

Write-Host ""
Write-Info "Target Path: $TargetPath"
Write-Info "Total Files: $($files.Count)"
Write-Info "Total Size:  $([math]::Round($totalSize, 2)) MB"
Write-Host ""

Write-Header "✅ Next Steps"
Write-Host ""
Write-Host "1. Initialize Git repository:" -ForegroundColor Yellow
Write-Host "   cd $TargetPath" -ForegroundColor White
Write-Host "   git init" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor White
Write-Host "   git commit -m 'Initial commit: AI/ML Landing Zone deployment'" -ForegroundColor White
Write-Host ""
Write-Host "2. Create GitHub repository and push:" -ForegroundColor Yellow
Write-Host "   git remote add origin https://github.com/YOUR-ORG/YOUR-REPO.git" -ForegroundColor White
Write-Host "   git branch -M main" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor White
Write-Host ""
Write-Host "3. Update README.md with your GitHub org/repo name" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Generate Deploy to Azure URL:" -ForegroundColor Yellow
Write-Host "   cd $TargetPath" -ForegroundColor White
Write-Host "   ./generate-github-deploy-url.ps1 -GitHubOrg 'YOUR-ORG' -GitHubRepo 'YOUR-REPO'" -ForegroundColor White
Write-Host ""
Write-Host "5. Test deployment!" -ForegroundColor Green
Write-Host ""

Write-Success "🎉 Standalone package ready at: $TargetPath"
