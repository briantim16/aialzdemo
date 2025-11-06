#!/bin/bash

# Build script to compile Bicep to ARM template for Azure Portal deployment
# This script handles the large template size by using template specs

set -e  # Exit on error

echo "🚀 AI/ML Landing Zone - ARM Template Build Script"
echo "=================================================="

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFRA_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$SCRIPT_DIR/arm-output"
MAIN_BICEP="$INFRA_DIR/main.bicep"
MAIN_ARM="$OUTPUT_DIR/mainTemplate.json"
UI_DEF="$INFRA_DIR/createUiDefinition.json"
WRAPPERS_DIR="$INFRA_DIR/wrappers"

# Check prerequisites
echo ""
echo "📋 Checking prerequisites..."

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi
echo "✅ Azure CLI installed"

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Run 'az login' first"
    exit 1
fi
echo "✅ Logged in to Azure"

# Create output directory
echo ""
echo "📁 Creating output directory..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/nestedTemplates"
echo "✅ Output directory created: $OUTPUT_DIR"

# Compile main Bicep template
echo ""
echo "🔨 Compiling main Bicep template..."
if az bicep build --file "$MAIN_BICEP" --outfile "$MAIN_ARM"; then
    echo "✅ Main template compiled successfully"
    
    # Check template size
    TEMPLATE_SIZE=$(wc -c < "$MAIN_ARM")
    TEMPLATE_SIZE_MB=$(echo "scale=2; $TEMPLATE_SIZE / 1048576" | bc)
    echo "📏 Template size: $TEMPLATE_SIZE_MB MB"
    
    if (( $(echo "$TEMPLATE_SIZE > 4194304" | bc -l) )); then
        echo "⚠️  WARNING: Template exceeds 4 MB limit ($TEMPLATE_SIZE_MB MB)"
        echo "    You'll need to use Template Specs or linked templates for deployment"
    else
        echo "✅ Template size is within 4 MB limit"
    fi
else
    echo "❌ Failed to compile main template"
    exit 1
fi

# Compile wrapper modules
echo ""
echo "🔨 Compiling wrapper modules..."
WRAPPER_COUNT=0
WRAPPER_ERRORS=0

for wrapper in "$WRAPPERS_DIR"/*.bicep; do
    if [ -f "$wrapper" ]; then
        WRAPPER_NAME=$(basename "$wrapper" .bicep)
        WRAPPER_JSON="$OUTPUT_DIR/nestedTemplates/$WRAPPER_NAME.json"
        
        if az bicep build --file "$wrapper" --outfile "$WRAPPER_JSON" 2>/dev/null; then
            WRAPPER_COUNT=$((WRAPPER_COUNT + 1))
            echo "  ✅ $WRAPPER_NAME"
        else
            WRAPPER_ERRORS=$((WRAPPER_ERRORS + 1))
            echo "  ❌ $WRAPPER_NAME (failed to compile)"
        fi
    fi
done

echo "✅ Compiled $WRAPPER_COUNT wrapper modules"
if [ $WRAPPER_ERRORS -gt 0 ]; then
    echo "⚠️  $WRAPPER_ERRORS wrapper modules failed to compile"
fi

# Copy UI definition
echo ""
echo "📋 Copying UI definition..."
if [ -f "$UI_DEF" ]; then
    cp "$UI_DEF" "$OUTPUT_DIR/createUiDefinition.json"
    echo "✅ UI definition copied"
else
    echo "❌ UI definition not found: $UI_DEF"
    exit 1
fi

# Create README for deployment package
echo ""
echo "📝 Creating deployment package README..."
cat > "$OUTPUT_DIR/README.md" << 'EOF'
# AI/ML Landing Zone - Azure Portal Deployment Package

This package contains the compiled ARM templates and custom UI definition for deploying the AI/ML Landing Zone through the Azure Portal.

## Contents

- `mainTemplate.json` - Main ARM template (compiled from Bicep)
- `createUiDefinition.json` - Custom Azure Portal UI wizard
- `nestedTemplates/` - Compiled wrapper modules (if template size exceeds limits)

## Deployment Options

### Option 1: Template Specs (Recommended)

```bash
# Create template spec
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --resource-group <your-template-specs-rg> \
  --location <region> \
  --template-file mainTemplate.json \
  --ui-form-definition createUiDefinition.json \
  --description "Secure AI/ML Landing Zone" \
  --display-name "AI/ML Landing Zone"
```

Then deploy via Azure Portal > Template Specs.

### Option 2: Direct Portal Link

1. Upload `mainTemplate.json` and `createUiDefinition.json` to Azure Blob Storage with public access
2. Get blob URLs
3. Create Portal link:

```
https://portal.azure.com/#create/Microsoft.Template/uri/<template-url-encoded>/createUIDefinitionUri/<ui-def-url-encoded>
```

### Option 3: Azure CLI

```bash
az deployment group create \
  --resource-group <your-rg> \
  --template-file mainTemplate.json \
  --parameters @parameters.json
```

## Template Size Warning

⚠️ If the main template exceeds 4 MB, you must use one of these approaches:

1. **Template Specs** - Handles large templates automatically
2. **Linked Templates** - Upload nested templates to storage and reference via templateLink
3. **Module Flattening** - Reduce template size (may lose modularity)

## Installation Profiles

The UI definition includes three pre-configured profiles:

- **Full** - All 28 components (complete platform)
- **Core** - 11 essential components (development)
- **Custom** - User selects individual components

See `PORTAL_DEPLOYMENT.md` in the parent directory for detailed documentation.

## Support

- Repository: https://github.com/Azure/bicep-avm-ptn-aiml-landing-zone
- Documentation: ../docs/
EOF

echo "✅ README created"

# Generate parameter file template
echo ""
echo "📝 Creating parameter file template..."
cat > "$OUTPUT_DIR/parameters.template.json" << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "eastus2"
    },
    "baseName": {
      "value": ""
    },
    "resourceToken": {
      "value": ""
    },
    "enableTelemetry": {
      "value": true
    },
    "flagPlatformLandingZone": {
      "value": false
    },
    "deployToggles": {
      "value": {
        "logAnalytics": true,
        "appInsights": true,
        "containerEnv": true,
        "containerRegistry": true,
        "cosmosDb": true,
        "keyVault": true,
        "storageAccount": true,
        "searchService": true,
        "groundingWithBingSearch": true,
        "appConfig": true,
        "apiManagement": true,
        "applicationGateway": true,
        "applicationGatewayPublicIp": true,
        "firewall": true,
        "containerApps": true,
        "buildVm": true,
        "bastionHost": true,
        "jumpVm": true,
        "virtualNetwork": true,
        "wafPolicy": true,
        "agentNsg": true,
        "peNsg": true,
        "applicationGatewayNsg": true,
        "apiManagementNsg": true,
        "acaEnvironmentNsg": true,
        "jumpboxNsg": true,
        "devopsBuildAgentsNsg": true
      }
    },
    "resourceIds": {
      "value": {}
    },
    "tags": {
      "value": {}
    }
  }
}
EOF

echo "✅ Parameter template created"

# Summary
echo ""
echo "=========================================="
echo "✨ Build Complete!"
echo "=========================================="
echo ""
echo "📦 Output location: $OUTPUT_DIR"
echo ""
echo "📄 Files created:"
echo "  - mainTemplate.json (ARM template)"
echo "  - createUiDefinition.json (Portal UI)"
echo "  - nestedTemplates/*.json ($WRAPPER_COUNT modules)"
echo "  - README.md"
echo "  - parameters.template.json"
echo ""
echo "🎯 Next steps:"
echo "  1. Test UI definition in sandbox:"
echo "     https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade"
echo ""
echo "  2. Create Template Spec:"
echo "     cd $OUTPUT_DIR"
echo "     az ts create --name 'AI-ML-LZ' --version '1.0.0' \\"
echo "       --resource-group <rg-name> --location <region> \\"
echo "       --template-file mainTemplate.json \\"
echo "       --ui-form-definition createUiDefinition.json"
echo ""
echo "  3. Or deploy directly:"
echo "     az deployment group create \\"
echo "       --resource-group <rg-name> \\"
echo "       --template-file mainTemplate.json \\"
echo "       --parameters @parameters.template.json"
echo ""
echo "📚 Full documentation: $INFRA_DIR/PORTAL_DEPLOYMENT.md"
echo ""
