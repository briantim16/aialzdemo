# Alternative Deployment Methods - Avoiding Portal File Size Limits

## 🚫 Problems Encountered

1. ❌ **Portal file upload**: 4 MB limit blocks 9.6 MB template
2. ❌ **Template Specs**: 4 MB limit via `az ts create`
3. ❌ **Azure Storage hosting**: Your subscription has:
   - Policy blocking key-based authentication
   - Role assignment propagation delays (30-60 seconds)
   - Complex RBAC requirements

## ✅ Working Solution: Deploy via Azure CLI

The **simplest and most reliable** method is to deploy directly via Azure CLI using the **Bicep source code**.

### Method 1: Direct Bicep Deployment (Recommended)

**Advantages:**
- ✅ No size limits
- ✅ No storage account needed
- ✅ Works with any subscription policies
- ✅ Fastest deployment
- ✅ Source code is readable

**Disadvantages:**
- ❌ No custom UI wizard (uses CLI parameters instead)

**Steps:**

```bash
# 1. Create target resource group
az group create --name aiml-prod-rg --location eastus2

# 2. Deploy using Bicep (Full profile)
az deployment group create \
  --resource-group aiml-prod-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

# OR deploy with inline parameters (Core profile example)
az deployment group create \
  --resource-group aiml-prod-rg \
  --template-file infra/main.bicep \
  --parameters \
    baseName="aiml" \
    location="eastus2" \
    deployToggles='{"searchService":true,"cosmosDb":true,"storageAccount":true,"keyVault":true,"appConfig":true,"containerRegistry":true,"logAnalytics":true,"appInsights":true,"virtualNetwork":true,"agentNsg":true,"peNsg":true}'
```

**Deployment Time:**
- Core profile: ~25 minutes
- Full profile: ~50 minutes

### Method 2: PowerShell Deployment

```powershell
# 1. Create resource group
New-AzResourceGroup -Name aiml-prod-rg -Location eastus2

# 2. Deploy
New-AzResourceGroupDeployment `
  -ResourceGroupName aiml-prod-rg `
  -TemplateFile infra/main.bicep `
  -TemplateParameterFile infra/main.bicepparam
```

### Method 3: VS Code Bicep Extension

1. Open `infra/main.bicep` in VS Code
2. Right-click in the editor
3. Select **"Deploy Bicep File..."**
4. Follow the prompts to select subscription/resource group
5. Fill in parameters when prompted

### Method 4: GitHub Actions Pipeline

Create `.github/workflows/deploy-aiml-lz.yml`:

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
          - staging
          - prod
      profile:
        description: 'Installation Profile'
        required: true
        type: choice
        options:
          - full
          - core

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - uses: actions/checkout@v4
      
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
          parameters: ./infra/main.bicepparam profile=${{ inputs.profile }}
```

## 📊 Comparison Table

| Method | Size Limit | Custom UI | Ease of Use | Policy-Proof | Speed |
|--------|-----------|-----------|-------------|--------------|-------|
| Portal Upload | ❌ 4 MB | ✅ Yes | ⭐⭐⭐⭐ | ❌ No | Fast |
| Template Spec | ❌ 4 MB | ✅ Yes | ⭐⭐⭐⭐⭐ | ❌ No | Fast |
| Storage + Portal | ✅ Unlimited | ✅ Yes | ⭐⭐ | ❌ No | Slow |
| **Bicep CLI** | **✅ Unlimited** | ❌ No | **⭐⭐⭐⭐** | **✅ Yes** | **Fast** |
| VS Code | ✅ Unlimited | ❌ No | ⭐⭐⭐⭐⭐ | ✅ Yes | Fast |
| Pipeline | ✅ Unlimited | ❌ No | ⭐⭐⭐ | ✅ Yes | Automated |

## 🎯 Recommended Approach

**For your scenario** (9.6 MB template + restrictive policies):

### **Use Azure CLI with Bicep**

```bash
# Quick deployment with Core profile
az deployment group create \
  --resource-group aiml-dev-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

This avoids:
- ✅ File size limits
- ✅ Storage account creation
- ✅ Role assignment delays
- ✅ Policy violations
- ✅ Complex RBAC setup

## 📝 What You Get

Even without the custom UI wizard, you still deploy the same resources:

### **Full Profile** (28 components):
- Networking: VNet, 7 NSGs, Application Gateway, Firewall
- AI/ML: AI Search, Cosmos DB, Storage, Key Vault, App Config
- Observability: Log Analytics, App Insights
- Container Platform: Container Registry, Container Apps
- Security: Bastion, Jump VM, Build VM
- Additional: API Management, Bing Grounding, WAF Policy

### **Core Profile** (11 components):
- Networking: VNet, 2 NSGs
- AI/ML: AI Search, Cosmos DB, Storage, Key Vault, App Config
- Observability: Log Analytics, App Insights
- Container Platform: Container Registry

## 💡 Next Steps

1. **Test deployment** with Core profile in dev environment:
   ```bash
   az group create --name aiml-dev-rg --location eastus2
   az deployment group create \
     --resource-group aiml-dev-rg \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

2. **Validate resources** after deployment:
   ```bash
   az resource list --resource-group aiml-dev-rg --output table
   ```

3. **Create pipeline** for production deployments (optional)

4. **Document** your chosen deployment method for team

---

**The custom UI wizard was a great effort**, but given your subscription's policies, **Bicep CLI deployment is the most practical solution**.

Would you like help setting up a deployment now?
