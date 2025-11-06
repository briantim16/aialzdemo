#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TEMPLATE_SPEC_NAME="AI-ML-Landing-Zone"
TEMPLATE_SPEC_VERSION="1.0.0"
TEMPLATE_SPEC_RG="template-specs-rg"
LOCATION="eastus2"
TEMPLATE_FILE="./portal-package/mainTemplate.json"
UI_DEF_FILE="./portal-package/createUiDefinition.json"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Azure Template Spec Creator${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if files exist
echo -e "${BLUE}ℹ️  Checking files...${NC}"
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}❌ Template file not found: $TEMPLATE_FILE${NC}"
    echo -e "${YELLOW}Run ./package-for-portal.ps1 first to create the template${NC}"
    exit 1
fi

if [ ! -f "$UI_DEF_FILE" ]; then
    echo -e "${RED}❌ UI definition file not found: $UI_DEF_FILE${NC}"
    exit 1
fi

TEMPLATE_SIZE=$(du -h "$TEMPLATE_FILE" | cut -f1)
UIDEF_SIZE=$(du -h "$UI_DEF_FILE" | cut -f1)

echo -e "${GREEN}✅ Template file found: $TEMPLATE_SIZE${NC}"
echo -e "${GREEN}✅ UI definition file found: $UIDEF_SIZE${NC}"
echo ""

# Check Azure CLI
echo -e "${BLUE}ℹ️  Checking Azure CLI...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Install from: https://aka.ms/azure-cli${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI found: $(az version --query '\"azure-cli\"' -o tsv)${NC}"
echo ""

# Check login
echo -e "${BLUE}ℹ️  Checking Azure login...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure. Running az login...${NC}"
    az login
fi

CURRENT_SUB=$(az account show --query name -o tsv)
CURRENT_SUB_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✅ Logged in to: $CURRENT_SUB${NC}"
echo ""

# Prompt for confirmation
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Configuration${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Template Spec Name:    ${YELLOW}$TEMPLATE_SPEC_NAME${NC}"
echo -e "Version:               ${YELLOW}$TEMPLATE_SPEC_VERSION${NC}"
echo -e "Resource Group:        ${YELLOW}$TEMPLATE_SPEC_RG${NC}"
echo -e "Location:              ${YELLOW}$LOCATION${NC}"
echo -e "Subscription:          ${YELLOW}$CURRENT_SUB${NC}"
echo -e "Template Size:         ${YELLOW}$TEMPLATE_SIZE${NC}"
echo ""

read -p "Continue with these settings? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Operation cancelled${NC}"
    exit 0
fi

# Create resource group if it doesn't exist
echo ""
echo -e "${BLUE}ℹ️  Checking resource group...${NC}"
if az group show --name "$TEMPLATE_SPEC_RG" &> /dev/null; then
    echo -e "${GREEN}✅ Resource group exists: $TEMPLATE_SPEC_RG${NC}"
else
    echo -e "${YELLOW}⚠️  Resource group doesn't exist. Creating...${NC}"
    az group create --name "$TEMPLATE_SPEC_RG" --location "$LOCATION"
    echo -e "${GREEN}✅ Resource group created${NC}"
fi
echo ""

# Check if Template Spec already exists
echo -e "${BLUE}ℹ️  Checking if Template Spec exists...${NC}"
if az ts show --name "$TEMPLATE_SPEC_NAME" --resource-group "$TEMPLATE_SPEC_RG" --version "$TEMPLATE_SPEC_VERSION" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Template Spec version $TEMPLATE_SPEC_VERSION already exists${NC}"
    read -p "Update existing version? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled. Consider creating a new version (e.g., 1.0.1)${NC}"
        exit 0
    fi
    COMMAND="update"
else
    COMMAND="create"
fi
echo ""

# Create/Update Template Spec
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Creating Template Spec${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${BLUE}ℹ️  This may take a few minutes for large templates...${NC}"
echo ""

if [ "$COMMAND" = "create" ]; then
    az ts create \
      --name "$TEMPLATE_SPEC_NAME" \
      --version "$TEMPLATE_SPEC_VERSION" \
      --location "$LOCATION" \
      --resource-group "$TEMPLATE_SPEC_RG" \
      --template-file "$TEMPLATE_FILE" \
      --ui-form-definition "$UI_DEF_FILE" \
      --description "Secure AI/ML Landing Zone with network isolation, private endpoints, and Azure AI Foundry. Includes Full (28 components), Core (11 components), and Custom installation profiles." \
      --display-name "AI/ML Landing Zone"
else
    az ts update \
      --name "$TEMPLATE_SPEC_NAME" \
      --version "$TEMPLATE_SPEC_VERSION" \
      --resource-group "$TEMPLATE_SPEC_RG" \
      --template-file "$TEMPLATE_FILE" \
      --ui-form-definition "$UI_DEF_FILE"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ Template Spec Created Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Get Template Spec ID
    TEMPLATE_SPEC_ID=$(az ts show \
      --name "$TEMPLATE_SPEC_NAME" \
      --resource-group "$TEMPLATE_SPEC_RG" \
      --version "$TEMPLATE_SPEC_VERSION" \
      --query "id" -o tsv)
    
    echo -e "${CYAN}📋 Template Spec Details:${NC}"
    echo -e "   Name:     ${YELLOW}$TEMPLATE_SPEC_NAME${NC}"
    echo -e "   Version:  ${YELLOW}$TEMPLATE_SPEC_VERSION${NC}"
    echo -e "   Location: ${YELLOW}$LOCATION${NC}"
    echo ""
    echo -e "${CYAN}🔗 Template Spec ID:${NC}"
    echo -e "   ${YELLOW}$TEMPLATE_SPEC_ID${NC}"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}🚀 How to Deploy${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${BLUE}Option 1: Azure Portal${NC}"
    echo "   1. Navigate to: https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Resources%2FtemplateSpecs"
    echo "   2. Find: $TEMPLATE_SPEC_NAME"
    echo "   3. Click 'Deploy'"
    echo "   4. Fill in the custom wizard"
    echo ""
    
    echo -e "${BLUE}Option 2: Azure CLI${NC}"
    echo "   # Create target resource group"
    echo "   az group create --name \"aiml-landing-zone-rg\" --location \"$LOCATION\""
    echo ""
    echo "   # Deploy Template Spec"
    echo "   az deployment group create \\"
    echo "     --resource-group \"aiml-landing-zone-rg\" \\"
    echo "     --template-spec \"$TEMPLATE_SPEC_ID\""
    echo ""
    
    echo -e "${BLUE}Option 3: PowerShell${NC}"
    echo "   New-AzResourceGroupDeployment \\"
    echo "     -ResourceGroupName \"aiml-landing-zone-rg\" \\"
    echo "     -TemplateSpecId \"$TEMPLATE_SPEC_ID\""
    echo ""
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}📚 Next Steps${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "1. Test deployment in a test subscription"
    echo "2. Grant users access to the Template Spec:"
    echo "   az role assignment create \\"
    echo "     --assignee \"user@company.com\" \\"
    echo "     --role \"Template Spec Reader\" \\"
    echo "     --scope \"$TEMPLATE_SPEC_ID\""
    echo ""
    echo "3. Document the Template Spec ID for your team"
    echo "4. Create new versions for updates (1.0.1, 1.1.0, etc.)"
    echo ""
    
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}❌ Template Spec Creation Failed${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Check the error message above for details."
    exit 1
fi
