# Template Spec Deployment Guide

## 🎯 Why Template Specs?

Your template is **9.6 MB** - far exceeding Azure Portal's 4 MB limit. Template Specs solve this by:
- ✅ **No size limits** - Can handle templates of any size
- ✅ **Versioned** - Track and manage versions
- ✅ **Secure** - RBAC-controlled access
- ✅ **Enterprise-ready** - Best practice for production
- ✅ **Custom UI** - Still uses createUiDefinition.json

## 📦 What is a Template Spec?

A Template Spec is an Azure resource that stores ARM templates. Think of it as a "template library" in Azure.

## 🚀 Quick Deployment

### Step 1: Create the Template Spec

```bash
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --location "eastus2" \
  --resource-group "template-specs-rg" \
  --template-file ./portal-package/mainTemplate.json \
  --ui-form-definition ./portal-package/createUiDefinition.json \
  --description "Secure AI/ML Landing Zone with network isolation, private endpoints, and Azure AI Foundry" \
  --display-name "AI/ML Landing Zone"
```

**Note**: The resource group must exist first!

### Step 2: Deploy from Portal

Once created, users can deploy via:

1. **Azure Portal** → Search "Template specs"
2. Find "AI-ML-Landing-Zone"
3. Click **Deploy**
4. Custom UI wizard appears automatically!

### Step 3: Deploy via CLI

```bash
# Get the Template Spec ID
TEMPLATE_SPEC_ID=$(az ts show \
  --name "AI-ML-Landing-Zone" \
  --resource-group "template-specs-rg" \
  --version "1.0.0" \
  --query "id" -o tsv)

# Deploy it
az deployment group create \
  --resource-group "aiml-landing-zone-rg" \
  --template-spec "$TEMPLATE_SPEC_ID"
```

## 🛠️ Using the Helper Script

I've created a script to automate this:

```bash
cd infra
./create-template-spec.sh
```

This will:
- ✅ Create resource group (if needed)
- ✅ Create the Template Spec
- ✅ Upload both template and UI definition
- ✅ Provide deployment instructions

## 📊 Size Comparison

| Method | Size Limit | Your Template | Works? |
|--------|-----------|---------------|--------|
| Portal "Deploy to Azure" button | 4 MB | 9.6 MB | ❌ No |
| Template Specs | Unlimited | 9.6 MB | ✅ Yes |
| Linked Templates | 4 MB each | N/A | ⚠️ Complex |

## 🔄 Updating the Template Spec

### Option 1: New Version (Recommended)

```bash
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.1.0" \
  --resource-group "template-specs-rg" \
  --template-file ./portal-package/mainTemplate.json \
  --ui-form-definition ./portal-package/createUiDefinition.json
```

### Option 2: Update Existing Version

```bash
az ts update \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --resource-group "template-specs-rg" \
  --template-file ./portal-package/mainTemplate.json \
  --ui-form-definition ./portal-package/createUiDefinition.json
```

## 🌐 Sharing with Others

### Option 1: RBAC Permissions

Grant users access to the Template Spec:

```bash
az role assignment create \
  --assignee "user@company.com" \
  --role "Template Spec Reader" \
  --scope "/subscriptions/{sub-id}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone"
```

### Option 2: Cross-Subscription Access

Template Specs can be deployed across subscriptions if users have:
- ✅ Read access to the Template Spec
- ✅ Contributor access to target resource group

### Option 3: Export Template Spec

Share the Template Spec ID:

```
/subscriptions/{subscription-id}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone/versions/1.0.0
```

Users can deploy with:

```bash
az deployment group create \
  --resource-group "my-rg" \
  --template-spec "/subscriptions/{sub-id}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone/versions/1.0.0"
```

## 📝 Documentation for Users

### Portal Deployment Instructions

1. **Prerequisites**:
   - Azure subscription
   - Contributor access to target resource group
   - Read access to Template Spec (if in different subscription)

2. **Steps**:
   - Navigate to Azure Portal
   - Search for "Template specs"
   - Select subscription containing the Template Spec
   - Find "AI-ML-Landing-Zone"
   - Click **Deploy**
   - Fill in the custom wizard
   - Click **Review + Create**

### CLI Deployment Instructions

```bash
# 1. Login to Azure
az login

# 2. Set subscription
az account set --subscription "your-subscription-id"

# 3. Create resource group
az group create --name "aiml-rg" --location "eastus2"

# 4. Deploy Template Spec
az deployment group create \
  --resource-group "aiml-rg" \
  --template-spec "/subscriptions/{spec-sub-id}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone/versions/1.0.0" \
  --parameters location="eastus2"
```

## 🏢 Enterprise Patterns

### Pattern 1: Centralized Template Spec

```
Platform Team Subscription
├── template-specs-rg
│   └── AI-ML-Landing-Zone (Template Spec)
│
App Team Subscriptions
├── team-a-sub
│   └── aiml-landing-zone-rg (Deployment)
├── team-b-sub
│   └── aiml-landing-zone-rg (Deployment)
```

### Pattern 2: Per-Environment Versions

```
Template Specs:
├── AI-ML-Landing-Zone v1.0.0 (Production)
├── AI-ML-Landing-Zone v1.1.0-preview (Staging)
└── AI-ML-Landing-Zone v2.0.0-beta (Development)
```

### Pattern 3: Azure DevOps Pipeline

```yaml
- task: AzureCLI@2
  displayName: 'Update Template Spec'
  inputs:
    azureSubscription: 'Platform-Subscription'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az ts create \
        --name "AI-ML-Landing-Zone" \
        --version "$(Build.BuildNumber)" \
        --resource-group "template-specs-rg" \
        --template-file ./mainTemplate.json \
        --ui-form-definition ./createUiDefinition.json
```

## ⚡ Quick Commands Reference

```bash
# Create resource group
az group create --name "template-specs-rg" --location "eastus2"

# Create Template Spec
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --resource-group "template-specs-rg" \
  --template-file mainTemplate.json \
  --ui-form-definition createUiDefinition.json

# List versions
az ts show --name "AI-ML-Landing-Zone" --resource-group "template-specs-rg"

# Delete a version
az ts delete --name "AI-ML-Landing-Zone" --version "1.0.0" --resource-group "template-specs-rg"

# Deploy
az deployment group create \
  --resource-group "target-rg" \
  --template-spec "/subscriptions/{sub}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone/versions/1.0.0"
```

## 🎯 GitHub Repository Content

Since Template Specs are the deployment method, your GitHub repo should contain:

```
azure-aiml-landing-zone/
├── README.md                      # Explains Template Spec deployment
├── mainTemplate.json              # (Optional - for reference)
├── createUiDefinition.json        # (Optional - for reference)
├── scripts/
│   └── create-template-spec.sh    # Helper script
└── docs/
    ├── template-spec-deployment.md
    ├── parameters.md
    └── architecture.md
```

**README.md** should say:

> This template exceeds Azure Portal's 4 MB limit. Deploy using **Template Specs**:
> 
> 1. Create the Template Spec: `./scripts/create-template-spec.sh`
> 2. Deploy from Azure Portal → Template specs → AI-ML-Landing-Zone

## 🔍 Troubleshooting

### Error: "The template is too large"
✅ **Solution**: You're using Template Specs correctly - this shouldn't happen

### Error: "Template Spec not found"
✅ **Solution**: Ensure you're in the correct subscription where the Template Spec exists

### Error: "Authorization failed"
✅ **Solution**: Grant "Template Spec Reader" role on the Template Spec

### Custom UI not showing in Portal
✅ **Solution**: Ensure `--ui-form-definition` was specified when creating the Template Spec

## ✨ Best Practices

1. **Version naming**: Use semantic versioning (1.0.0, 1.1.0, 2.0.0)
2. **Resource group**: Dedicate a resource group for Template Specs
3. **Location**: Choose a central region (Template Spec is metadata only)
4. **Access control**: Use RBAC to control who can deploy
5. **Documentation**: Always include deployment instructions
6. **Testing**: Test new versions before promoting to production

## 📚 Learn More

- [Template Specs Documentation](https://learn.microsoft.com/azure/azure-resource-manager/templates/template-specs)
- [Template Specs Tutorial](https://learn.microsoft.com/azure/azure-resource-manager/templates/template-specs-create-portal-forms)
- [Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/templates/template-specs-best-practices)
