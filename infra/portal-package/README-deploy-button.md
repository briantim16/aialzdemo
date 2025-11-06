# Deploy to Azure

Click the button below to deploy the AI/ML Landing Zone to your Azure subscription:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fbriantim16%2faialzdemo%2fmain%2finfra%2fportal-package%2fmainTemplate.json/createUIDefinitionUri/https%3a%2f%2fraw.githubusercontent.com%2fbriantim16%2faialzdemo%2fmain%2finfra%2fportal-package%2fcreateUiDefinition.json)

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
- [GitHub Issues](https://github.com/briantim16/aialzdemo/issues)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
