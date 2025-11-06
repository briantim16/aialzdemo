# Azure Portal Deployment Package Guide

This guide explains how to package the AI/ML Landing Zone for Azure Portal deployment.

## 📦 What's Needed for Portal Deployment

To deploy via Azure Portal, you need:

1. **mainTemplate.json** - The compiled ARM template from `main.bicep`
2. **createUiDefinition.json** - The custom UI definition (already created)
3. **README.md** - Deployment instructions and overview
4. **Supporting documentation** - Parameter descriptions, architecture diagrams

## 🎯 Required Files for Standalone Repo

```
azure-aiml-portal-template/
├── README.md                      # Main documentation
├── mainTemplate.json              # Compiled ARM template
├── createUiDefinition.json        # Portal UI definition
├── docs/
│   ├── deployment-guide.md        # Step-by-step deployment
│   ├── parameters.md              # Parameter reference
│   └── architecture.md            # Architecture overview
├── .github/
│   └── workflows/
│       └── validate.yml           # CI/CD validation
└── LICENSE                        # License file
```

## 🔨 Build Process

### Option 1: Quick Package (Portal Deployment Only)

This creates a minimal package for Azure Portal "Deploy to Azure" button:

```powershell
# Run the packaging script
./package-for-portal.ps1
```

This will:
1. Compile `main.bicep` → `mainTemplate.json`
2. Validate `createUiDefinition.json`
3. Create a deployment package in `./portal-package/`
4. Generate a README with "Deploy to Azure" button

### Option 2: Template Spec Deployment

For enterprise scenarios, use Template Specs:

```bash
# Create the template spec
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --location "eastus" \
  --resource-group "template-specs-rg" \
  --template-file mainTemplate.json \
  --ui-form-definition createUiDefinition.json \
  --description "Secure AI/ML Landing Zone with network isolation"
```

### Option 3: Full GitHub Repository

For a complete standalone repository:

```powershell
# Run the full packaging script
./create-standalone-repo.ps1 -OutputPath "../azure-aiml-portal-template"
```

## 📋 Pre-requisites

Before building, ensure:

1. **Azure Bicep CLI** is installed: `az bicep version`
2. **PowerShell 7+** (for scripts): `pwsh --version`
3. **Azure CLI** is logged in: `az account show`

## 🚀 Deployment Methods

### Method 1: Azure Portal "Deploy to Azure" Button

Add this to your GitHub README:

```markdown
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F{org}%2F{repo}%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F{org}%2F{repo}%2Fmain%2FcreateUiDefinition.json)
```

### Method 2: Template Spec (Recommended for Enterprise)

```bash
# Deploy from template spec
az deployment group create \
  --resource-group "aiml-landing-zone-rg" \
  --template-spec "/subscriptions/{sub-id}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone/versions/1.0.0"
```

### Method 3: Direct ARM Deployment

```bash
# Deploy ARM template directly
az deployment group create \
  --resource-group "aiml-landing-zone-rg" \
  --template-file mainTemplate.json \
  --parameters @parameters.json
```

## ⚠️ Important Notes

### Size Limitations

- **Azure Portal**: Template + CUID must be < 4 MB
- **Template Specs**: Can handle larger templates
- **Current size**: Check with `./validate-ui.ps1`

### Compilation Challenges

The main.bicep file is **very large** (2800+ lines) and uses:
- 50+ wrapper modules
- Template specs for sub-modules
- Complex parameter types

**Two approaches:**

#### A. Pre-compiled Approach (Recommended)
Run pre-provisioning to replace wrapper references with template specs, then compile:

```powershell
# 1. Run pre-provisioning
./scripts/preprovision.ps1

# 2. Compile to ARM
az bicep build --file infra/main.bicep --outfile mainTemplate.json
```

#### B. Simplified Approach
Create a simplified version that removes some optional components to reduce size.

## 📊 Size Management

If the compiled template exceeds 4 MB:

1. **Use Template Specs** - No size limit
2. **Split into linked templates** - Break into smaller pieces
3. **Remove optional features** - Create "Core" vs "Full" versions
4. **Compress parameter descriptions** - Reduce metadata

## 🧪 Testing

Before publishing:

```powershell
# 1. Validate JSON syntax
./validate-ui.ps1

# 2. Test in Portal Sandbox
# Open: https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade
# Upload: createUiDefinition.json

# 3. Validate ARM template
az deployment group validate \
  --resource-group "test-rg" \
  --template-file mainTemplate.json \
  --parameters @test-parameters.json
```

## 📚 Documentation to Include

Your standalone repo should include:

1. **README.md**
   - Overview of the landing zone
   - Architecture diagram
   - Quick start instructions
   - "Deploy to Azure" button

2. **docs/deployment-guide.md**
   - Step-by-step deployment walkthrough
   - Prerequisites
   - Post-deployment configuration

3. **docs/parameters.md**
   - Complete parameter reference
   - Installation profile descriptions
   - Network configuration options

4. **docs/architecture.md**
   - Component overview
   - Network topology
   - Security features

## 🔐 Security Considerations

Before publishing:

- [ ] Remove any sensitive information (subscription IDs, tenant IDs)
- [ ] Review parameter defaults (no production values)
- [ ] Validate RBAC requirements in documentation
- [ ] Test with least-privilege service principal

## 📝 License

Ensure you include appropriate license file (MIT, Apache 2.0, etc.)

## 🆘 Troubleshooting

### "Template too large" error
→ Use Template Specs instead of direct deployment

### "Invalid UI definition" error
→ Run `./validate-ui.ps1` and check schema version

### Compilation errors
→ Ensure all wrapper modules are accessible or run pre-provisioning

### Parameter validation errors
→ Check parameter types match between CUID and ARM template

## 📞 Next Steps

1. Run `./package-for-portal.ps1` to create the package
2. Test in Azure Portal Sandbox
3. Create GitHub repository
4. Add "Deploy to Azure" button
5. Test end-to-end deployment
