#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Packages the AI/ML Landing Zone for Azure Portal deployment.

.DESCRIPTION
    This script creates a standalone deployment package containing:
    - Compiled ARM template (mainTemplate.json)
    - Custom UI definition (createUiDefinition.json)
    - Documentation and README
    - Deploy to Azure button

.PARAMETER OutputPath
    Path where the package will be created. Default: ./portal-package

.PARAMETER SkipBicepBuild
    Skip building the Bicep template (use existing mainTemplate.json)

.PARAMETER CreateGitHubRepo
    Create a complete GitHub repository structure

.EXAMPLE
    ./package-for-portal.ps1
    
.EXAMPLE
    ./package-for-portal.ps1 -OutputPath "../my-portal-package"
    
.EXAMPLE
    ./package-for-portal.ps1 -CreateGitHubRepo -OutputPath "../azure-aiml-portal-template"
#>

param(
    [string]$OutputPath = "./portal-package",
    [switch]$SkipBicepBuild,
    [switch]$CreateGitHubRepo
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Header { param($Text) Write-Host "`n========================================" -ForegroundColor Cyan; Write-Host $Text -ForegroundColor Cyan; Write-Host "========================================" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "✅ $Text" -ForegroundColor Green }
function Write-Info { param($Text) Write-Host "ℹ️  $Text" -ForegroundColor Blue }
function Write-Warning { param($Text) Write-Host "⚠️  $Text" -ForegroundColor Yellow }
function Write-Error { param($Text) Write-Host "❌ $Text" -ForegroundColor Red }

Write-Header "🚀 Azure Portal Deployment Package Builder"

# Validate prerequisites
Write-Info "Checking prerequisites..."

# Check Azure CLI
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI not found. Please install: https://aka.ms/azure-cli"
    exit 1
}
Write-Success "Azure CLI found: $(az version --query '\"azure-cli\"' -o tsv)"

# Check Bicep
$bicepVersion = az bicep version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Bicep CLI not found. Installing..."
    az bicep install
}
Write-Success "Bicep CLI found: $bicepVersion"

# Create output directory
Write-Info "Creating output directory: $OutputPath"
if (Test-Path $OutputPath) {
    $response = Read-Host "Output directory exists. Overwrite? (y/N)"
    if ($response -ne 'y') {
        Write-Warning "Operation cancelled"
        exit 0
    }
    Remove-Item $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
Write-Success "Output directory created"

# Step 1: Build ARM template from Bicep
if (!$SkipBicepBuild) {
    Write-Header "📦 Step 1: Compiling Bicep to ARM Template"
    
    Write-Info "Checking main.bicep size..."
    $bicepFile = "./main.bicep"
    if (!(Test-Path $bicepFile)) {
        Write-Error "main.bicep not found in current directory"
        exit 1
    }
    
    $bicepSize = (Get-Item $bicepFile).Length / 1KB
    Write-Info "main.bicep size: $([math]::Round($bicepSize, 2)) KB"
    
    try {
        Write-Info "Compiling main.bicep → mainTemplate.json..."
        az bicep build --file $bicepFile --outfile "$OutputPath/mainTemplate.json"
        
        if ($LASTEXITCODE -eq 0) {
            $armSize = (Get-Item "$OutputPath/mainTemplate.json").Length / 1KB
            Write-Success "ARM template compiled successfully"
            Write-Info "mainTemplate.json size: $([math]::Round($armSize, 2)) KB"
            
            # Check size limit
            if ($armSize -gt 4096) {
                Write-Warning "Template size exceeds 4 MB Portal limit. Consider using Template Specs."
            }
        } else {
            throw "Bicep compilation failed"
        }
    } catch {
        Write-Error "Failed to compile Bicep template: $_"
        Write-Info "This template is very large and may require pre-provisioning."
        Write-Info "Try running: ./scripts/preprovision.ps1 first"
        exit 1
    }
} else {
    Write-Info "Skipping Bicep build (using existing mainTemplate.json)"
    if (Test-Path "./mainTemplate.json") {
        Copy-Item "./mainTemplate.json" "$OutputPath/mainTemplate.json"
        Write-Success "Copied existing mainTemplate.json"
    } else {
        Write-Error "mainTemplate.json not found and SkipBicepBuild specified"
        exit 1
    }
}

# Step 2: Copy and validate createUiDefinition.json
Write-Header "📋 Step 2: Copying UI Definition"

if (!(Test-Path "./createUiDefinition.json")) {
    Write-Error "createUiDefinition.json not found in current directory"
    exit 1
}

Copy-Item "./createUiDefinition.json" "$OutputPath/createUiDefinition.json"
Write-Success "Copied createUiDefinition.json"

# Validate JSON
try {
    $uiDef = Get-Content "$OutputPath/createUiDefinition.json" -Raw | ConvertFrom-Json
    Write-Success "UI definition is valid JSON"
    
    $uiSize = (Get-Item "$OutputPath/createUiDefinition.json").Length / 1KB
    Write-Info "createUiDefinition.json size: $([math]::Round($uiSize, 2)) KB"
} catch {
    Write-Error "Invalid JSON in createUiDefinition.json: $_"
    exit 1
}

# Step 3: Create README
Write-Header "📝 Step 3: Generating README"

$readmeContent = @"
# Azure AI/ML Landing Zone - Portal Deployment

Secure, enterprise-ready AI/ML landing zone with network isolation, private endpoints, and Azure AI Foundry.

## 🚀 Quick Deploy

Click the button below to deploy via Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F{YOUR-ORG}%2F{YOUR-REPO}%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F{YOUR-ORG}%2F{YOUR-REPO}%2Fmain%2FcreateUiDefinition.json)

> **Note**: Replace `{YOUR-ORG}` and `{YOUR-REPO}` with your GitHub organization and repository name.

## 📋 What Gets Deployed

### Installation Profiles

Choose from three pre-configured deployment profiles:

#### **Full Profile** (28 components)
Complete AI/ML platform with all services:
- **Networking**: Virtual Network, 7 NSGs, Application Gateway, Azure Firewall
- **AI/ML Core**: AI Search, Cosmos DB, Storage, Key Vault, App Configuration
- **Observability**: Log Analytics, Application Insights
- **Container Platform**: Container Registry, Container Apps Environment
- **API Management**: API gateway and management
- **Security**: Bastion Host, Jump VM, Build VM
- **Additional**: Bing Grounding, WAF Policy

#### **Core Profile** (11 components)
Essential AI services for most workloads:
- Virtual Network with NSGs
- AI Search, Cosmos DB, Storage, Key Vault, App Configuration
- Log Analytics, Application Insights
- Container Registry

#### **Custom Profile**
Select only the components you need.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              AI/ML Landing Zone VNet                  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐    │  │
│  │  │ Agent    │  │ Private  │  │  Optional:       │    │  │
│  │  │ Subnet   │  │ Endpoint │  │  - App Gateway   │    │  │
│  │  │          │  │ Subnet   │  │  - API Mgmt      │    │  │
│  │  └──────────┘  └──────────┘  │  - Container Apps│    │  │
│  │                               └──────────────────┘    │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  Private Endpoints to:                                      │
│  • Azure AI Search        • Cosmos DB                       │
│  • Storage Account        • Key Vault                       │
│  • Container Registry     • App Configuration               │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Prerequisites

- **Azure Subscription** with appropriate permissions
- **Resource Provider Registrations**:
  - Microsoft.Network
  - Microsoft.Compute
  - Microsoft.Storage
  - Microsoft.KeyVault
  - Microsoft.Search
  - Microsoft.DocumentDB
  - Microsoft.ContainerRegistry
  - Microsoft.App
  - Microsoft.ApiManagement (if deploying API Management)

## 🎯 Deployment Steps

### Option 1: Azure Portal (Recommended)

1. Click the "Deploy to Azure" button above
2. Select your **Subscription** and create/select a **Resource Group**
3. Choose a **Region** (all resources deploy to this region)
4. Select an **Installation Profile**:
   - **Full**: All 28 components
   - **Core**: 11 essential components
   - **Custom**: Select individual components
5. Configure networking options
6. Review and click **Create**

Deployment time: **30-60 minutes** (varies by profile)

### Option 2: Template Spec

For enterprise deployments, use Template Specs:

\`\`\`bash
# Create the template spec
az ts create \\
  --name "AI-ML-Landing-Zone" \\
  --version "1.0.0" \\
  --location "eastus" \\
  --resource-group "template-specs-rg" \\
  --template-file mainTemplate.json \\
  --ui-form-definition createUiDefinition.json

# Deploy from template spec
az deployment group create \\
  --resource-group "aiml-rg" \\
  --template-spec "/subscriptions/{sub-id}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone/versions/1.0.0"
\`\`\`

### Option 3: Azure CLI

\`\`\`bash
# Deploy directly with Azure CLI
az deployment group create \\
  --resource-group "aiml-landing-zone-rg" \\
  --template-file mainTemplate.json \\
  --parameters \\
    location="eastus" \\
    baseName="aiml" \\
    installationProfile="core"
\`\`\`

## 🔧 Configuration Options

### Basic Configuration
- **Base Name**: Prefix for resource names (auto-generated if empty)
- **Resource Token**: Unique identifier (auto-generated if empty)
- **Enable Telemetry**: Anonymous usage data for Azure Verified Modules

### Installation Profiles
- **Full**: Production-ready with all features
- **Core**: Cost-optimized essential services
- **Custom**: Select specific components

### Network Configuration
- **New VNet**: Create isolated network (default)
- **Existing VNet**: Integrate with existing network
- **Platform Landing Zone**: Use enterprise hub-spoke model

### Advanced Configuration
- Reuse existing resources (Log Analytics, Storage, etc.)
- Custom tagging
- Existing resource integration

## 🔒 Security Features

- **Network Isolation**: All services deployed with private endpoints
- **No Public Access**: Resources accessible only within VNet
- **NSG Protection**: Network security groups on all subnets
- **Private DNS Zones**: Automatic DNS resolution for private endpoints
- **Azure Policy**: (Optional) Guardrails and compliance
- **Azure Firewall**: (Optional) Centralized egress control

## 💰 Cost Considerations

Estimated monthly cost by profile (East US, standard tier):

- **Core Profile**: ~\$500-800/month
  - AI Search (Basic)
  - Cosmos DB (RU/s)
  - Storage Account
  - Container Registry
  - Monitoring

- **Full Profile**: ~\$2,000-3,500/month
  - All Core services +
  - Application Gateway
  - API Management
  - Container Apps
  - Azure Firewall
  - VMs (Bastion, Jump, Build)

> **Note**: Actual costs vary based on usage, data transfer, and storage.

## 📊 Post-Deployment

After deployment completes:

1. **Verify Resources**: Check Azure Portal for deployed resources
2. **Configure AI Services**: Set up AI Search indexes, Cosmos DB collections
3. **Deploy Workloads**: Use Container Apps or VMs for AI/ML applications
4. **Set Up Monitoring**: Configure Application Insights dashboards
5. **Test Connectivity**: Verify private endpoint connectivity

## 🧹 Cleanup

To remove all deployed resources:

\`\`\`bash
az group delete --name "aiml-landing-zone-rg" --yes --no-wait
\`\`\`

## 📚 Documentation

- [Deployment Guide](docs/deployment-guide.md) - Step-by-step instructions
- [Parameters Reference](docs/parameters.md) - All configuration options
- [Architecture Details](docs/architecture.md) - Component overview

## 🆘 Troubleshooting

### Common Issues

**"Template too large" error**
→ Use Template Specs instead of direct deployment

**"Quota exceeded" error**
→ Request quota increase for the region or choose different SKUs

**"Resource provider not registered" error**
→ Register required providers: \`az provider register --namespace Microsoft.{Service}\`

**Private endpoint DNS not resolving**
→ Ensure Private DNS Zones are linked to VNet

## 🤝 Contributing

This template uses [Azure Verified Modules (AVM)](https://aka.ms/avm). For issues or contributions:
- [Report Issues](https://github.com/{YOUR-ORG}/{YOUR-REPO}/issues)
- [Submit Pull Requests](https://github.com/{YOUR-ORG}/{YOUR-REPO}/pulls)

## 📄 License

[Specify your license here - MIT, Apache 2.0, etc.]

## 🔗 Related Resources

- [Azure AI Services Documentation](https://learn.microsoft.com/azure/ai-services/)
- [Azure Landing Zones](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Verified Modules](https://aka.ms/avm)
- [Azure AI Foundry](https://learn.microsoft.com/azure/ai-studio/)

---

**Made with ❤️ for Azure AI/ML workloads**
"@

Set-Content -Path "$OutputPath/README.md" -Value $readmeContent
Write-Success "README.md created"

# Step 4: Create GitHub workflow (if requested)
if ($CreateGitHubRepo) {
    Write-Header "🔄 Step 4: Creating GitHub Repository Structure"
    
    # Create .github/workflows directory
    New-Item -ItemType Directory -Path "$OutputPath/.github/workflows" -Force | Out-Null
    
    $workflowContent = @'
name: Validate Templates

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Validate ARM Template
        run: |
          az deployment group validate \
            --resource-group "validation-rg" \
            --template-file mainTemplate.json \
            --parameters location="eastus" \
            --no-prompt
      
      - name: Validate UI Definition JSON
        run: |
          jq empty createUiDefinition.json
          echo "✅ UI Definition is valid JSON"
      
      - name: Check Template Size
        run: |
          TEMPLATE_SIZE=$(wc -c < mainTemplate.json)
          UIDEF_SIZE=$(wc -c < createUiDefinition.json)
          TOTAL_SIZE=$((TEMPLATE_SIZE + UIDEF_SIZE))
          MAX_SIZE=4194304  # 4 MB
          
          echo "Template size: $((TEMPLATE_SIZE / 1024)) KB"
          echo "UI Definition size: $((UIDEF_SIZE / 1024)) KB"
          echo "Total size: $((TOTAL_SIZE / 1024)) KB"
          
          if [ $TOTAL_SIZE -gt $MAX_SIZE ]; then
            echo "⚠️ Warning: Total size exceeds 4 MB Portal limit"
            echo "Consider using Template Specs for deployment"
          fi
'@
    
    Set-Content -Path "$OutputPath/.github/workflows/validate.yml" -Value $workflowContent
    Write-Success "GitHub workflow created"
    
    # Create docs directory
    New-Item -ItemType Directory -Path "$OutputPath/docs" -Force | Out-Null
    Write-Success "Docs directory created"
    
    # Copy license if exists
    if (Test-Path "../LICENSE") {
        Copy-Item "../LICENSE" "$OutputPath/LICENSE"
        Write-Success "License file copied"
    }
}

# Step 5: Generate deployment summary
Write-Header "📊 Deployment Package Summary"

$templateSize = (Get-Item "$OutputPath/mainTemplate.json").Length
$uiDefSize = (Get-Item "$OutputPath/createUiDefinition.json").Length
$totalSize = $templateSize + $uiDefSize

Write-Info "Package Location: $OutputPath"
Write-Info ""
Write-Info "Files:"
Write-Info "  - mainTemplate.json       : $([math]::Round($templateSize / 1KB, 2)) KB"
Write-Info "  - createUiDefinition.json : $([math]::Round($uiDefSize / 1KB, 2)) KB"
Write-Info "  - README.md"
if ($CreateGitHubRepo) {
    Write-Info "  - .github/workflows/validate.yml"
    Write-Info "  - docs/"
}

Write-Info ""
Write-Info "Total Size: $([math]::Round($totalSize / 1KB, 2)) KB"

if ($totalSize -gt 4MB) {
    Write-Warning "Package exceeds 4 MB Azure Portal limit!"
    Write-Info "Recommendation: Use Template Specs for deployment"
} else {
    Write-Success "Package size is within Azure Portal limits"
}

# Step 6: Next steps
Write-Header "✨ Package Created Successfully!"

Write-Info ""
Write-Info "📍 Next Steps:"
Write-Info ""
Write-Info "1. Test the UI Definition:"
Write-Info "   • Open: https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade"
Write-Info "   • Upload: $OutputPath/createUiDefinition.json"
Write-Info ""
Write-Info "2. Validate the ARM template:"
Write-Info "   az deployment group validate --resource-group test-rg --template-file $OutputPath/mainTemplate.json"
Write-Info ""

if ($CreateGitHubRepo) {
    Write-Info "3. Create GitHub repository:"
    Write-Info "   cd $OutputPath"
    Write-Info "   git init"
    Write-Info "   git add ."
    Write-Info "   git commit -m 'Initial commit'"
    Write-Info "   git remote add origin https://github.com/{YOUR-ORG}/{YOUR-REPO}.git"
    Write-Info "   git push -u origin main"
    Write-Info ""
    Write-Info "4. Update README.md with your GitHub URLs"
    Write-Info ""
} else {
    Write-Info "3. Create Template Spec (recommended):"
    Write-Info "   az ts create --name 'AI-ML-Landing-Zone' --version '1.0.0' \"
    Write-Info "     --location 'eastus' --resource-group 'template-specs-rg' \"
    Write-Info "     --template-file '$OutputPath/mainTemplate.json' \"
    Write-Info "     --ui-form-definition '$OutputPath/createUiDefinition.json'"
    Write-Info ""
}

Write-Info "5. Test deployment end-to-end in a test subscription"
Write-Info ""

Write-Success "🎉 Packaging complete!"
