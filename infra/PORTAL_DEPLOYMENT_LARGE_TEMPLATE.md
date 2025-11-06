# Deploy AI/ML Landing Zone via Azure Portal (Large Template Method)

## 🎯 Overview

This method works with the 9.6 MB template by using Azure Portal's **Custom Deployment** feature, which allows direct upload of large templates and custom UI definitions.

## ✅ Prerequisites

1. Azure subscription
2. Appropriate permissions (Contributor or Owner on target subscription/resource group)
3. Files from this repository:
   - `portal-package/mainTemplate.json` (9.6 MB)
   - `portal-package/createUiDefinition.json` (33 KB)

## 📋 Step-by-Step Deployment

### Step 1: Build the Portal Package

If you haven't already, run the packaging script:

```powershell
cd infra
./package-for-portal.ps1
```

This creates `portal-package/mainTemplate.json` and `portal-package/createUiDefinition.json`.

### Step 2: Navigate to Azure Portal Custom Deployment

Open your browser to: **https://portal.azure.com/#create/Microsoft.Template**

Or:
1. Go to https://portal.azure.com
2. Search for **"Deploy a custom template"**
3. Click on the service

### Step 3: Upload the ARM Template

1. Click **"Build your own template in the editor"**
2. Click **"Load file"**
3. Select `infra/portal-package/mainTemplate.json` from your local machine
4. Click **"Save"**

⏱️ _Note: The 9.6 MB file may take 10-20 seconds to upload_

### Step 4: Upload the Custom UI Definition

1. Click **"Edit UI definition"** (near the top of the page)
2. Click **"Load file"** 
3. Select `infra/portal-package/createUiDefinition.json` from your local machine
4. Click **"Save and close"**

### Step 5: Complete the Wizard

You'll now see the custom 6-step wizard:

#### **Step 1: Basics**
- **Subscription**: Select your Azure subscription
- **Resource Group**: Create new or use existing
- **Region**: Select Azure region (e.g., East US 2)
- **Base Name**: (Optional) Custom base name for resources
- **Resource Token**: (Optional) Deterministic token
- **Enable Telemetry**: Yes/No

#### **Step 2: Installation Profile**
Choose one:
- **Full** - Complete AI/ML Platform (28 components)
- **Core** - Essential AI Services (11 components)  
- **Custom** - Select individual components

#### **Step 3: Component Selection**
_(Only if you chose "Custom" profile)_

Select which components to deploy:
- Networking (VNet, NSGs, Firewall, Application Gateway)
- AI/ML Core (AI Search, Cosmos DB, Storage, Key Vault, App Config)
- Observability (Log Analytics, Application Insights)
- Container Platform (Container Registry, Container Apps)
- API Management
- Security & Access (Bastion, Jump VM, Build VM)

#### **Step 4: Network Configuration**
- **Platform Landing Zone Integration**: Enable if using ALZ pattern
- **Virtual Network Deployment**: Create new or use existing

#### **Step 5: Advanced Configuration**
- **Existing Resource IDs**: (Optional) Reuse existing resources
- **Resource Tags**: (Optional) Add custom tags

#### **Step 6: Review + Create**
- Review your configuration
- Click **"Create"** to start deployment

### Step 6: Monitor Deployment

1. Deployment typically takes **30-60 minutes** depending on profile
2. Monitor progress in **Notifications** (bell icon) or **Deployments** blade
3. Check deployment outputs for resource IDs and endpoints

## 🔍 Deployment Validation

After deployment completes:

```powershell
# List all resources in the resource group
az resource list --resource-group <your-rg-name> --output table

# Check specific resources
az network vnet show --resource-group <your-rg-name> --name <vnet-name>
az search service show --resource-group <your-rg-name> --name <search-name>
```

## ⚠️ Troubleshooting

### "Invalid UIFormDefinition Schema" Error

**Cause**: The UI definition may not have uploaded correctly.

**Solution**:
1. Go back to **Step 2**
2. Click **"Edit UI definition"** again
3. Click **"Load file"** and re-upload `createUiDefinition.json`
4. Ensure the file is the correct one (32 KB, not a wrapper or other file)
5. Click **"Save and close"**

### Template Upload Fails or Times Out

**Cause**: Large file size (9.6 MB) may timeout on slow connections.

**Solutions**:
1. **Use a faster internet connection**
2. **Alternative**: Deploy via Azure CLI instead:
   ```bash
   az deployment group create \
     --resource-group <your-rg-name> \
     --template-file portal-package/mainTemplate.json \
     --parameters @portal-package/createUiDefinition.json
   ```
   _Note: CLI deployment won't show the custom wizard_

3. **Alternative**: Deploy the Bicep source directly:
   ```bash
   az deployment group create \
     --resource-group <your-rg-name> \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

### Deployment Fails with Policy Violation

**Cause**: Azure Policy in your subscription/management group is blocking resources.

**Solutions**:
1. Check the error message for which policy is blocking
2. Common issues:
   - **TLS version**: Some policies require TLS 1.2 minimum
   - **Public IP**: Some policies block public IPs
   - **Encryption**: Some policies require specific encryption settings
3. Either:
   - **Request policy exemption** for the deployment
   - **Modify parameters** to comply with policy
   - **Deploy to a different subscription** without restrictive policies

### Resource Already Exists

**Cause**: Previous deployment created resources, or conflicting resources exist.

**Solutions**:
1. **Delete previous deployment**: 
   ```bash
   az group delete --name <your-rg-name> --yes
   ```
2. **Use different resource names**: Change `baseName` or `resourceToken` parameters
3. **Check for conflicting resources** in the subscription

## 📊 Expected Deployment Time by Profile

| Profile | Components | Approx. Time | Complexity |
|---------|-----------|--------------|------------|
| **Core** | 11 | 20-30 min | ⭐⭐ |
| **Full** | 28 | 45-60 min | ⭐⭐⭐⭐⭐ |
| **Custom** | Varies | 15-60 min | ⭐⭐⭐ |

## 🎉 Post-Deployment

Once deployment succeeds:

1. **Check Outputs**: Review deployment outputs for resource IDs
2. **Verify Connectivity**: Test private endpoints and network connectivity
3. **Configure Access**: Set up RBAC for users
4. **Deploy Workloads**: Start deploying AI/ML workloads

## 📚 Additional Resources

- [Main Documentation](../README.md)
- [Parameter Reference](../docs/parameters.md)
- [How to Use Guide](../docs/how_to_use.md)
- [Architecture Diagram](../docs/architecture.md)

## 💡 Tips

- **Start with Core profile** for initial testing
- **Use Platform Landing Zone mode** if you have Azure Landing Zones deployed
- **Enable diagnostic logs** on all resources for troubleshooting
- **Document your configuration** for future updates

---

**Need Help?**
- Check [GitHub Issues](https://github.com/Azure/bicep-avm-ptn-aiml-landing-zone/issues)
- Review [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
