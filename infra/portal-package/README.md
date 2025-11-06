# Azure AI/ML Landing Zone - Portal Deployment

Secure, enterprise-ready AI/ML landing zone with network isolation, private endpoints, and Azure AI Foundry.

## 🚀 Quick Deploy

Click the button below to deploy via Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F{YOUR-ORG}%2F{YOUR-REPO}%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F{YOUR-ORG}%2F{YOUR-REPO}%2Fmain%2FcreateUiDefinition.json)

> **Note**: Replace {YOUR-ORG} and {YOUR-REPO} with your GitHub organization and repository name.

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

`
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
`

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

\\\ash
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
\\\

### Option 3: Azure CLI

\\\ash
# Deploy directly with Azure CLI
az deployment group create \\
  --resource-group "aiml-landing-zone-rg" \\
  --template-file mainTemplate.json \\
  --parameters \\
    location="eastus" \\
    baseName="aiml" \\
    installationProfile="core"
\\\

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

- **Core Profile**: ~\-800/month
  - AI Search (Basic)
  - Cosmos DB (RU/s)
  - Storage Account
  - Container Registry
  - Monitoring

- **Full Profile**: ~\,000-3,500/month
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

\\\ash
az group delete --name "aiml-landing-zone-rg" --yes --no-wait
\\\

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
→ Register required providers: \z provider register --namespace Microsoft.{Service}\

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
