# Azure Portal Deployment Package - Quick Reference

## 🎯 Minimum Required Files

To deploy via Azure Portal, you need **exactly 2 files**:

```
your-github-repo/
├── mainTemplate.json          ← Compiled ARM template
└── createUiDefinition.json    ← Custom UI (already created ✅)
```

## 🚀 Quick Start

### Option 1: Use the Packaging Script (Recommended)

```powershell
cd infra
./package-for-portal.ps1 -CreateGitHubRepo -OutputPath "../azure-aiml-portal-deploy"
```

This will create a complete package ready for GitHub.

### Option 2: Manual Build

```bash
# 1. Compile Bicep to ARM
cd infra
az bicep build --file main.bicep --outfile mainTemplate.json

# 2. Copy the UI definition (already created)
# createUiDefinition.json ✅

# 3. Create README with "Deploy to Azure" button
# See template in package-for-portal.ps1
```

## 📦 What Each File Does

| File | Purpose | Size | Required? |
|------|---------|------|-----------|
| `mainTemplate.json` | ARM template with all resource definitions | Large | ✅ Yes |
| `createUiDefinition.json` | Custom Azure Portal wizard | ~32 KB | ✅ Yes |
| `README.md` | Documentation + Deploy button | Small | Recommended |
| `docs/` | Additional documentation | Variable | Optional |

## ⚠️ Important Challenges

### Challenge 1: Template Size

The main.bicep file is **very large** (2,873 lines) because it:
- Uses 50+ wrapper modules
- References Azure Verified Modules via template specs
- Has complex parameter types

**Solutions:**

1. **Use Template Specs** (Recommended)
   - No 4 MB size limit
   - Better for enterprise
   - Versioned deployments

2. **Pre-compile wrappers**
   ```powershell
   ./scripts/preprovision.ps1  # Replaces module refs
   az bicep build --file infra/main.bicep
   ```

3. **Accept Portal limitations**
   - If template > 4 MB, Portal deployment won't work
   - Template Specs are the enterprise solution

### Challenge 2: Module Dependencies

This template depends on:
- Azure Verified Modules (AVM)
- Template specs for wrapper modules
- Pre-provisioning scripts

**For standalone deployment**, you need to either:
- ✅ Run pre-provisioning to inline everything
- ✅ Use Template Specs to handle size
- ❌ Can't use raw Bicep in Portal (too large)

## 📋 Deployment Methods Comparison

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Template Spec** | No size limit, versioned, secure | Requires pre-deployment | Enterprise |
| **Portal Button** | Easy, one-click | 4 MB limit, public URLs | Public repos |
| **Azure CLI** | Scriptable, flexible | Requires CLI | Automation |

## 🎨 Creating the GitHub Repository

### Step 1: Run Packaging Script

```powershell
cd c:\DEMOTHIS\DELETEMEIMMEDIATELY\bicepaialz\bicep-avm-ptn-aiml-landing-zone\infra
./package-for-portal.ps1 -CreateGitHubRepo -OutputPath "../../azure-aiml-portal-template"
```

### Step 2: Initialize Git

```bash
cd ../../azure-aiml-portal-template
git init
git add .
git commit -m "Initial commit: Azure AI/ML Landing Zone Portal deployment"
```

### Step 3: Create GitHub Repo

1. Go to https://github.com/new
2. Name it: `azure-aiml-landing-zone-template`
3. Make it public (required for "Deploy to Azure" button)
4. Don't initialize with README (we have one)

### Step 4: Push to GitHub

```bash
git remote add origin https://github.com/YOUR-ORG/azure-aiml-landing-zone-template.git
git branch -M main
git push -u origin main
```

### Step 5: Update README URLs

Edit `README.md` and replace:
- `{YOUR-ORG}` with your GitHub organization
- `{YOUR-REPO}` with `azure-aiml-landing-zone-template`

## 🔗 Deploy to Azure Button

Once on GitHub, your README will have:

```markdown
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2Fazure-aiml-landing-zone-template%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2Fazure-aiml-landing-zone-template%2Fmain%2FcreateUiDefinition.json)
```

When users click this button, Azure Portal will:
1. Download both JSON files from your repo
2. Show the custom UI wizard
3. Deploy the template with selected parameters

## 🧪 Testing Before Publishing

```powershell
# 1. Validate UI Definition
cd infra
./validate-ui.ps1

# 2. Test in Portal Sandbox
# Open: https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade
# Upload: createUiDefinition.json

# 3. Validate ARM template
az deployment group validate \
  --resource-group "test-rg" \
  --template-file portal-package/mainTemplate.json \
  --parameters location="eastus"
```

## 💡 Recommended Approach

Given the complexity and size of this template, I recommend:

### **Option A: Template Spec (Best)**

1. Build the template locally
2. Create a Template Spec in Azure
3. Document Template Spec deployment in README
4. No GitHub "Deploy to Azure" button needed

```bash
# Create Template Spec
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --location "eastus" \
  --resource-group "template-specs-rg" \
  --template-file mainTemplate.json \
  --ui-form-definition createUiDefinition.json \
  --description "Secure AI/ML Landing Zone with network isolation"

# Share the Template Spec ID
echo "Template Spec: /subscriptions/{sub}/resourceGroups/template-specs-rg/providers/Microsoft.Resources/templateSpecs/AI-ML-Landing-Zone"
```

Users deploy with:
```bash
az deployment group create \
  --resource-group "my-rg" \
  --template-spec "<template-spec-id>/versions/1.0.0"
```

### **Option B: Simplified GitHub Repo**

1. Create a "lite" version with fewer components
2. Make it fit under 4 MB
3. Use GitHub Deploy button

### **Option C: Hybrid Approach**

1. GitHub repo with documentation
2. Instructions for both methods
3. Template Spec for full deployment
4. Simplified ARM for Portal button

## 📊 File Structure Summary

### Minimal Package (2 files)
```
├── mainTemplate.json
└── createUiDefinition.json
```

### Recommended Package (GitHub-ready)
```
├── README.md
├── mainTemplate.json
├── createUiDefinition.json
├── .github/
│   └── workflows/
│       └── validate.yml
├── docs/
│   ├── deployment-guide.md
│   ├── parameters.md
│   └── architecture.md
└── LICENSE
```

## ⏭️ Next Actions

1. **Test the build** - Run `package-for-portal.ps1`
2. **Check template size** - Determine if Portal deployment is viable
3. **Choose deployment method** - Template Spec vs Portal button
4. **Create repository** - If going the GitHub route
5. **Write documentation** - Update README with your specifics
6. **Test end-to-end** - Deploy in test subscription

## 🆘 Need Help?

If the template is too large:
- ✅ **Use Template Specs** - Solves size problem
- ✅ **Create simplified version** - Reduce components
- ✅ **Split into linked templates** - Advanced technique

Already have `createUiDefinition.json` ✅ - Half the work is done!
