# Azure Portal Deployment with Custom UI Definition

This document explains how to deploy the AI/ML Landing Zone through the Azure Portal using the custom `createUiDefinition.json`.

## Overview

The custom UI definition provides a **wizard-based deployment experience** in the Azure Portal with three installation profiles:

1. **Full** - Complete AI/ML platform with all 28 components
2. **Core** - Essential AI services with 11 core components  
3. **Custom** - User selects individual components

## Installation Profiles

### Full Profile (28 Components)

Deploys a complete, production-ready AI/ML landing zone:

**Networking (9 components)**
- Virtual Network
- 7 Network Security Groups (Agent, PE, App Gateway, API Management, ACA, Jumpbox, DevOps Build Agents)
- VNet Peering support

**AI/ML Core (6 components)**
- Azure AI Search
- Cosmos DB
- Storage Account
- Key Vault
- App Configuration
- Bing Grounding

**Observability (2 components)**
- Log Analytics Workspace
- Application Insights

**Container Platform (4 components)**
- Container Registry
- Container Apps Environment
- Container Apps
- ACA Environment NSG

**API & Management (2 components)**
- API Management
- API Management NSG

**Security & Access (3 components)**
- Azure Bastion
- Jump VM
- Build VM

**Gateways & Firewall (2 components)**
- Application Gateway
- Azure Firewall
- WAF Policy

### Core Profile (11 Components)

Essential AI services for development and small-scale deployments:

- **Networking**: VNet, Agent NSG, PE NSG
- **AI/ML**: Search, Cosmos DB, Storage, Key Vault, App Config
- **Observability**: Log Analytics, App Insights
- **Containers**: Container Registry

**Excluded** (to reduce cost and complexity):
- API Management
- Application Gateway  
- Azure Firewall
- Container Apps Environment & Apps
- Bastion Host, Jump VM, Build VM
- Bing Grounding

### Custom Profile

All components start **disabled**. You manually select each component needed for your specific scenario.

## Testing the UI Definition

### Option 1: Azure Portal Sandbox (Recommended)

1. Navigate to the [Create UI Definition Sandbox](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade)
2. Click **Load Create UI Definition**
3. Upload the `createUiDefinition.json` file
4. Click **Preview** to test the wizard experience
5. Navigate through all steps to verify:
   - Profile selection works
   - Component checkboxes appear/disappear based on profile
   - Validation messages display correctly
   - Output parameters are generated correctly

### Option 2: Test Deployment

Create a test deployment to validate the full experience:

```bash
# 1. Build ARM template from Bicep (if not done already)
cd infra
az bicep build --file main.bicep --outfile main.json

# 2. Create a test resource group
az group create --name rg-ailz-ui-test --location eastus2

# 3. Test deployment (validation only)
az deployment group validate \
  --resource-group rg-ailz-ui-test \
  --template-file main.json \
  --parameters @main.bicepparam
```

## Deployment Methods

### Method 1: Direct Portal Link

Upload both `main.json` (ARM template) and `createUiDefinition.json` to an Azure Storage Account with public access:

```bash
# Create storage account
az storage account create \
  --name ailzdeploymentsa \
  --resource-group rg-deployment-assets \
  --location eastus2 \
  --sku Standard_LRS

# Upload files
az storage blob upload \
  --account-name ailzdeploymentsa \
  --container-name templates \
  --name main.json \
  --file main.json \
  --public-access blob

az storage blob upload \
  --account-name ailzdeploymentsa \
  --container-name templates \
  --name createUiDefinition.json \
  --file createUiDefinition.json \
  --public-access blob
```

Then share this URL (replace with your blob URLs):

```
https://portal.azure.com/#create/Microsoft.Template/uri/<url-encoded-template-uri>/createUIDefinitionUri/<url-encoded-ui-definition-uri>
```

### Method 2: Template Specs (Recommended)

Publish as a Template Spec for version control and easy sharing:

```bash
# Create template spec
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --resource-group rg-template-specs \
  --location eastus2 \
  --template-file main.json \
  --ui-form-definition createUiDefinition.json \
  --description "Secure AI/ML Landing Zone with network isolation and Azure AI Foundry" \
  --display-name "AI/ML Landing Zone"

# Deploy from template spec
az ts show \
  --name "AI-ML-Landing-Zone" \
  --resource-group rg-template-specs \
  --version "1.0.0" \
  --query "id"

# Use the returned ID in the Azure Portal
```

Then deploy via Portal:
1. Navigate to **Template Specs** in Azure Portal
2. Select **AI-ML-Landing-Zone**
3. Click **Deploy**
4. Follow the custom UI wizard

### Method 3: Azure Marketplace (Long-term)

For enterprise-wide sharing, publish to Azure Marketplace:

1. Create Partner Center account
2. Create new Azure Application offer
3. Upload ARM template and UI definition
4. Submit for certification
5. Publish to Marketplace

## UI Wizard Flow

### Step 1: Basics
- **Subscription**: Select target subscription
- **Resource Group**: Create new or select existing
- **Region**: Azure region for resources
- **Base Name**: Optional naming prefix (leave empty for auto-generation)
- **Resource Token**: Optional uniqueness suffix
- **Enable Telemetry**: Toggle for AVM telemetry

### Step 2: Installation Profile
- **Profile Selector**: Choose Full, Core, or Custom
- **Profile Summary**: Visual summary of what will be deployed
- **Info Boxes**: Detailed explanations for each profile

### Step 3: Component Selection (Custom Only)
Grouped by category:
- **Networking Components**: VNet, NSGs, Gateway, Firewall
- **AI/ML Core Services**: Search, Cosmos, Storage, Key Vault
- **Observability**: Log Analytics, App Insights
- **Container Platform**: ACR, ACA, Container Apps
- **API Management**: APIM, APIM NSG
- **Security & Access**: Bastion, Jump VM, Build VM

### Step 4: Network Configuration
- **Platform Landing Zone**: Toggle for platform integration
- **VNet Deployment Mode**: Create new vs. use existing
- **Warnings**: Info boxes for platform LZ mode

### Step 5: Advanced Configuration
- **Tags**: Resource tags (currently placeholder)
- **Existing Resource IDs**: Reuse existing resources
  - Virtual Network Resource ID
  - Log Analytics Workspace ID
  - App Insights ID
  - Storage Account ID
  - Key Vault ID
  - Container Registry ID

### Step 6: Review + Create
- **Deployment Summary**: Profile, region, settings
- **Review**: Final check before deployment
- **Create**: Start deployment

## Parameter Mapping

The UI outputs map to ARM template parameters as follows:

| UI Output | ARM Parameter | Type | Description |
|-----------|---------------|------|-------------|
| `location` | `location` | string | Azure region |
| `baseName` | `baseName` | string | Naming prefix |
| `resourceToken` | `resourceToken` | string | Uniqueness suffix |
| `enableTelemetry` | `enableTelemetry` | bool | Telemetry toggle |
| `flagPlatformLandingZone` | `flagPlatformLandingZone` | bool | Platform LZ mode |
| `deployToggles` | `deployToggles` | object | 28 boolean flags |
| `resourceIds` | `resourceIds` | object | Existing resource IDs |
| `tags` | `tags` | object | Resource tags |

## Component Dependencies

Some components require others to function:

| Component | Requires |
|-----------|----------|
| AI Foundry | Key Vault, Storage Account |
| Private Endpoints | Virtual Network |
| Application Gateway | Application Gateway NSG, Public IP |
| API Management | API Management NSG |
| Container Apps | Container Apps Environment |

> **Note**: The current UI definition does not enforce these dependencies. Consider adding validation rules in a future iteration.

## Customization Guide

### Adding New Components

1. Add checkbox in appropriate section:
```json
{
  "name": "newComponent",
  "type": "Microsoft.Common.CheckBox",
  "label": "New Component",
  "toolTip": "Deploy the new component"
}
```

2. Update outputs section:
```json
"deployToggles": "[if(equals(...), 
  createObject(..., 'newComponent', steps('section').newComponent, ...),
  ...)]"
```

3. Update profile presets (Full/Core):
```json
createObject(..., 'newComponent', true(), ...)
```

### Adding Validation Rules

Add to the outputs section:

```json
"validations": [
  {
    "isValid": "[or(not(outputs.deployToggles.aiFoundry), and(outputs.deployToggles.keyVault, outputs.deployToggles.storageAccount))]",
    "message": "AI Foundry requires Key Vault and Storage Account"
  }
]
```

### Modifying Profiles

Edit the `deployToggles` output logic:

```json
// Core Profile
createObject(
  'logAnalytics', true(),
  'appInsights', true(),
  'newCoreComponent', true(), // Add new core component
  ...
)
```

## Troubleshooting

### UI Definition Not Loading
- Verify JSON syntax with a linter
- Check schema version matches: `0.1.2-preview`
- Ensure all required properties exist

### Components Not Toggling
- Check step names match in outputs section
- Verify checkbox names are correct
- Test in sandbox to see console errors

### Deployment Fails
- Check ARM template compatibility
- Verify output parameter names match template parameters
- Review deployment errors in Activity Log

### Profile Selection Not Working
- Inspect outputs section conditional logic
- Test with browser developer tools console
- Verify all 28 components are included

## Next Steps

1. **Test in Sandbox**: Validate UI before deployment
2. **Deploy Test Environment**: Use Core profile for testing
3. **Document Custom Scenarios**: Create example parameter sets
4. **Add Validation**: Implement dependency checks
5. **Publish Template Spec**: Share within organization
6. **Gather Feedback**: Iterate based on user experience

## Resources

- [Create UI Definition Documentation](https://learn.microsoft.com/azure/azure-resource-manager/managed-applications/create-uidefinition-overview)
- [UI Definition Sandbox](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade)
- [Template Specs Documentation](https://learn.microsoft.com/azure/azure-resource-manager/templates/template-specs)
- [AI Landing Zone Repository](https://github.com/Azure/bicep-avm-ptn-aiml-landing-zone)

## Support

For issues or questions:
- Open an issue in the GitHub repository
- Review existing deployment examples
- Check the main documentation in `docs/`
