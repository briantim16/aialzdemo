#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Generates a Deploy to Azure button URL using GitHub-hosted template files

.DESCRIPTION
    Creates a deployment URL that references the mainTemplate.json and createUiDefinition.json
    files directly from a GitHub repository, avoiding the need for Azure Storage.

.PARAMETER GitHubOrg
    GitHub organization or user name. Default: Azure

.PARAMETER GitHubRepo
    GitHub repository name. Default: bicep-avm-ptn-aiml-landing-zone

.PARAMETER Branch
    Git branch name. Default: main

.PARAMETER TemplatePath
    Path to mainTemplate.json in repo. Default: infra/portal-package/mainTemplate.json

.PARAMETER UiDefPath
    Path to createUiDefinition.json in repo. Default: infra/portal-package/createUiDefinition.json

.EXAMPLE
    ./generate-github-deploy-url.ps1

.EXAMPLE
    ./generate-github-deploy-url.ps1 -Branch "feature/updates"
#>

param(
    [string]$GitHubOrg = "Azure",
    [string]$GitHubRepo = "bicep-avm-ptn-aiml-landing-zone",
    [string]$Branch = "main",
    [string]$TemplatePath = "infra/portal-package/mainTemplate.json",
    [string]$UiDefPath = "infra/portal-package/createUiDefinition.json"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Header { param($Text) Write-Host "`n========================================" -ForegroundColor Cyan; Write-Host $Text -ForegroundColor Cyan; Write-Host "========================================" -ForegroundColor Cyan }
function Write-Success { param($Text) Write-Host "✅ $Text" -ForegroundColor Green }
function Write-Info { param($Text) Write-Host "ℹ️  $Text" -ForegroundColor Blue }
function Write-Warning { param($Text) Write-Host "⚠️  $Text" -ForegroundColor Yellow }

Write-Header "🚀 GitHub-Hosted Deploy to Azure URL Generator"

# Construct raw GitHub URLs
$rawGitHubBase = "https://raw.githubusercontent.com/$GitHubOrg/$GitHubRepo/$Branch"
$templateUrl = "$rawGitHubBase/$TemplatePath"
$uiDefUrl = "$rawGitHubBase/$UiDefPath"

Write-Info "Configuration:"
Write-Host "  GitHub Org:  $GitHubOrg" -ForegroundColor Yellow
Write-Host "  Repository:  $GitHubRepo" -ForegroundColor Yellow
Write-Host "  Branch:      $Branch" -ForegroundColor Yellow
Write-Host ""

Write-Info "Template URLs:"
Write-Host "  Template:    $templateUrl" -ForegroundColor Cyan
Write-Host "  UI Def:      $uiDefUrl" -ForegroundColor Cyan
Write-Host ""

# Check if files exist in repo (optional validation)
Write-Info "Checking if files exist locally..."
$localTemplatePath = "./portal-package/mainTemplate.json"
$localUiDefPath = "./portal-package/createUiDefinition.json"

if (Test-Path $localTemplatePath) {
    $size = (Get-Item $localTemplatePath).Length / 1MB
    Write-Success "Template file found: $([math]::Round($size, 2)) MB"
} else {
    Write-Warning "Template file not found locally (this is OK if already committed to GitHub)"
}

if (Test-Path $localUiDefPath) {
    $size = (Get-Item $localUiDefPath).Length / 1KB
    Write-Success "UI definition file found: $([math]::Round($size, 2)) KB"
} else {
    Write-Warning "UI definition file not found locally (this is OK if already committed to GitHub)"
}

# URL encode the GitHub URLs
Add-Type -AssemblyName System.Web
$encodedTemplateUrl = [System.Web.HttpUtility]::UrlEncode($templateUrl)
$encodedUiDefUrl = [System.Web.HttpUtility]::UrlEncode($uiDefUrl)

# Generate Deploy to Azure URLs
Write-Header "✅ Generated Deployment URLs"

# Method 1: Full Portal URL with custom UI
$portalUrlWithUI = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedTemplateUrl/createUIDefinitionUri/$encodedUiDefUrl"

Write-Host ""
Write-Info "Method 1: Portal Deployment with Custom UI Wizard"
Write-Host ""
Write-Host $portalUrlWithUI -ForegroundColor Green
Write-Host ""

# Method 2: Portal URL without custom UI (fallback)
$portalUrlNoUI = "https://portal.azure.com/#create/Microsoft.Template/uri/$encodedTemplateUrl"

Write-Info "Method 2: Portal Deployment (Standard Parameters)"
Write-Host ""
Write-Host $portalUrlNoUI -ForegroundColor Yellow
Write-Host ""

# Generate Markdown Deploy to Azure button
Write-Header "📝 Markdown Deploy Button"
Write-Host ""
Write-Host "Add this to your README.md:" -ForegroundColor Cyan
Write-Host ""
$markdownButton = @"
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)]($portalUrlWithUI)
"@
Write-Host $markdownButton -ForegroundColor White
Write-Host ""

# Generate HTML Deploy to Azure button
Write-Header "📝 HTML Deploy Button"
Write-Host ""
Write-Host "Or use this HTML:" -ForegroundColor Cyan
Write-Host ""
$htmlButton = @"
<a href="$portalUrlWithUI" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/>
</a>
"@
Write-Host $htmlButton -ForegroundColor White
Write-Host ""

# Save to files
Write-Header "💾 Saving Output Files"

# Save URLs to text file
$urlFile = "./portal-package/github-deployment-urls.txt"
@"
AI/ML Landing Zone - GitHub-Hosted Deployment URLs
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

GitHub Repository: https://github.com/$GitHubOrg/$GitHubRepo
Branch: $Branch

=== RAW GITHUB URLS ===

Template URL:
$templateUrl

UI Definition URL:
$uiDefUrl

=== PORTAL DEPLOYMENT URLS ===

With Custom UI Wizard:
$portalUrlWithUI

Without Custom UI (Standard Parameters):
$portalUrlNoUI

=== DEPLOY BUTTON CODE ===

Markdown:
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)]($portalUrlWithUI)

HTML:
<a href="$portalUrlWithUI" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton" alt="Deploy to Azure"/>
</a>

=== HOW TO USE ===

1. Commit mainTemplate.json and createUiDefinition.json to your GitHub repo
2. Push to the branch: $Branch
3. Share the deployment URL or add the button to your README.md
4. Users click the button and see the custom 6-step wizard in Azure Portal

=== NOTES ===

- Files must be publicly accessible (public repo or raw.githubusercontent.com URLs)
- Template size: No limit when hosted on GitHub
- Custom UI: Works perfectly with GitHub-hosted templates
- No Azure Storage needed
- No costs for hosting

"@ | Out-File -FilePath $urlFile -Encoding UTF8

Write-Success "URLs saved to: $urlFile"

# Save Markdown snippet
$mdFile = "./portal-package/README-deploy-button.md"
@"
# Deploy to Azure

Click the button below to deploy the AI/ML Landing Zone to your Azure subscription:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)]($portalUrlWithUI)

## What Gets Deployed

### Installation Profiles

Choose from three pre-configured profiles in the deployment wizard:

#### **Full Profile** (28 components)
Complete AI/ML platform with all enterprise features:
- Networking: VNet, 7 NSGs, Application Gateway, Azure Firewall, WAF Policy
- AI/ML Services: AI Search, Cosmos DB, Storage Account, Key Vault, App Configuration
- Observability: Log Analytics, Application Insights  
- Container Platform: Container Registry, Container Apps Environment, Sample Apps
- API Management: Full API gateway with NSG
- Security & Access: Azure Bastion, Jump VM, Build VM
- Additional: Bing Search Grounding

#### **Core Profile** (11 components)
Essential AI/ML services for production workloads:
- Networking: VNet with Agent and Private Endpoint NSGs
- AI/ML Services: AI Search, Cosmos DB, Storage Account, Key Vault, App Configuration
- Observability: Log Analytics, Application Insights
- Container Platform: Container Registry

#### **Custom Profile**
Select individual components to match your requirements.

## Prerequisites

- Azure subscription with Contributor or Owner permissions
- Sufficient quota for selected resources
- ~25-60 minutes deployment time (depending on profile)

## Deployment Steps

1. Click the **Deploy to Azure** button above
2. Sign in to Azure Portal
3. Select subscription and resource group
4. Choose installation profile (Full/Core/Custom)
5. Configure network settings
6. Review and deploy

## Post-Deployment

After deployment completes:
- Review deployment outputs for resource IDs
- Configure RBAC for users
- Deploy AI/ML workloads
- Set up monitoring alerts

## Documentation

- [Parameters Reference](../../docs/parameters.md)
- [How to Use Guide](../../docs/how_to_use.md)
- [Architecture Overview](../../README.md)

## Support

For issues or questions:
- [GitHub Issues](https://github.com/$GitHubOrg/$GitHubRepo/issues)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
"@ | Out-File -FilePath $mdFile -Encoding UTF8

Write-Success "Deploy button README saved to: $mdFile"

Write-Header "🎉 Next Steps"
Write-Host ""
Write-Host "1. Commit and push the files to GitHub:" -ForegroundColor Yellow
Write-Host "   git add infra/portal-package/mainTemplate.json" -ForegroundColor White
Write-Host "   git add infra/portal-package/createUiDefinition.json" -ForegroundColor White
Write-Host "   git commit -m 'Add Portal deployment files'" -ForegroundColor White
Write-Host "   git push origin $Branch" -ForegroundColor White
Write-Host ""
Write-Host "2. Test the deployment URL (copy from above or $urlFile)" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Add the Deploy to Azure button to your README.md" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Share with your team!" -ForegroundColor Green
Write-Host ""

# Try to open browser (Windows only)
if ($IsWindows -or $env:OS -match "Windows") {
    $response = Read-Host "Open deployment URL in browser now? (y/N)"
    if ($response -eq 'y') {
        Start-Process $portalUrlWithUI
        Write-Success "Browser opened!"
    }
}

Write-Success "✅ All done!"
