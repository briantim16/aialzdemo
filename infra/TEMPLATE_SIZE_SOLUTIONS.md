# Azure Template Spec Limitations for Large Templates

## ❌ Problem Discovered

The AI/ML Landing Zone template is **9.6 MB**, which exceeds Azure's limits:
- **Azure Portal "Deploy to Azure" button**: 4 MB limit
- **Template Specs via CLI (`az ts create`)**: 4 MB limit
- **Linked templates via Storage**: Works, but not compatible with custom UI definition in Template Specs

## ✅ Working Solutions

### Solution 1: Direct ARM Deployment (No Template Spec)

**Pros:**
- ✅ Works with any template size
- ✅ Custom UI definition works
- ✅ No storage account dependencies

**Cons:**
- ❌ Users must download files manually
- ❌ No version management
- ❌ No centralized catalog

**How to Deploy:**

```bash
# Clone or download the repository
git clone https://github.com/Azure/bicep-avm-ptn-aiml-landing-zone.git
cd bicep-avm-ptn-aiml-landing-zone/infra

# Build the ARM template
pwsh ./package-for-portal.ps1

# Deploy via Azure Portal Custom Deployment
# 1. Go to: https://portal.azure.com/#create/Microsoft.Template
# 2. Click "Build your own template in the editor"
# 3. Click "Load file" and select portal-package/mainTemplate.json
# 4. Click "Save"
# 5. Click "Edit UI definition"
# 6. Click "Load file" and select portal-package/createUiDefinition.json
# 7. Click "Save"
# 8. Fill in the wizard and deploy
```

### Solution 2: Bicep Deployment (Recommended)

**Pros:**
- ✅ Works with any template size
- ✅ No compilation needed
- ✅ Source code is readable
- ✅ Faster deployments

**Cons:**
- ❌ No custom UI wizard (uses standard parameter prompts)

**How to Deploy:**

```bash
# Option A: Azure CLI
az group create --name aiml-prod-rg --location eastus2

az deployment group create \
  --resource-group aiml-prod-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

# Option B: Azure PowerShell
New-AzResourceGroup -Name aiml-prod-rg -Location eastus2

New-AzResourceGroupDeployment `
  -ResourceGroupName aiml-prod-rg `
  -TemplateFile infra/main.bicep `
  -TemplateParameterFile infra/main.bicepparam
```

### Solution 3: Azure DevOps / GitHub Actions Pipeline

**Pros:**
- ✅ Automated deployment
- ✅ Works with any template size
- ✅ CI/CD integration
- ✅ Approval gates

**Cons:**
- ❌ Requires pipeline setup
- ❌ No interactive wizard

**GitHub Actions Example:**

```yaml
name: Deploy AI/ML Landing Zone

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        type: choice
        options:
          - dev
          - prod
      installationProfile:
        description: 'Installation Profile'
        required: true
        type: choice
        options:
          - full
          - core
          - custom

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Bicep
        uses: azure/arm-deploy@v1
        with:
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          resourceGroupName: aiml-${{ inputs.environment }}-rg
          template: ./infra/main.bicep
          parameters: ./infra/main.bicepparam
```

## 📊 Comparison

| Feature | Portal Custom Deployment | Bicep CLI | Template Spec | Pipeline |
|---------|-------------------------|-----------|---------------|----------|
| Template Size | ✅ Unlimited | ✅ Unlimited | ❌ 4 MB limit | ✅ Unlimited |
| Custom UI Wizard | ✅ Yes | ❌ No | ✅ Yes (if <4MB) | ❌ No |
| Version Management | ❌ Manual | ❌ Manual | ✅ Built-in | ✅ Git-based |
| RBAC Control | ⚠️ Portal access | ⚠️ Subscription | ✅ Template Spec | ✅ Pipeline |
| Ease of Use | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Enterprise Ready | ⚠️ Manual process | ✅ Yes | ✅ Yes | ✅✅ Best |

## 🎯 Recommended Approach

For this 9.6 MB template, we recommend:

### For Ad-Hoc Deployments:
Use **Portal Custom Deployment** with manual file upload
- Best user experience with custom wizard
- No infrastructure dependencies
- Works for testing and demos

### For Production Deployments:
Use **Bicep CLI** or **Pipeline**
- More reliable
- Auditable
- Repeatable
- Version controlled

## 🔧 What We Built

The following artifacts are ready to use:

1. ✅ `createUiDefinition.json` - Complete custom wizard (33 KB)
2. ✅ `mainTemplate.json` - Full ARM template (9.6 MB)
3. ✅ `package-for-portal.ps1` - Automated packaging
4. ✅ `PORTAL_DEPLOYMENT.md` - Deployment guide
5. ✅ `QUICKSTART.md` - Quick start guide

## 📝 Next Steps

Choose your deployment path:

1. **GitHub Repository Package** - Include documentation for Portal Custom Deployment method
2. **Pipeline Setup** - Create GitHub Actions or Azure DevOps pipeline
3. **Simplified Version** - Create a "Core" template that's <4MB for Template Spec

Which approach would you like to pursue?
