# Creating a Standalone Deployment Repository

## 📦 What You Need to Copy

For a **complete, working deployment package** in a new repository, you need:

### **Option 1: Portal Deployment Only (Minimal)**

Copy these files to your new repo:

```
your-new-repo/
├── mainTemplate.json           # 9.6 MB ARM template
├── createUiDefinition.json     # 33 KB custom UI definition
└── README.md                   # Deployment instructions
```

**Pros:**
- ✅ Smallest package (~9.6 MB)
- ✅ Everything needed for Portal deployment
- ✅ No build scripts required

**Cons:**
- ❌ Can't make changes easily (need to edit ARM JSON)
- ❌ No source Bicep code
- ❌ Hard to maintain/update

### **Option 2: Full Development Package (Recommended)**

Copy these files/folders:

```
your-new-repo/
├── mainTemplate.json                    # Compiled ARM template
├── createUiDefinition.json              # Custom UI
├── main.bicep                           # Source Bicep template
├── main.bicepparam                      # Default parameters
├── README.md                            # Documentation
├── build-arm-template.ps1               # Compile script (PowerShell)
├── build-arm-template.sh                # Compile script (Bash)
├── package-for-portal.ps1               # Full packaging script
├── generate-github-deploy-url.ps1       # URL generator
├── common/
│   ├── build-cloudinit.yaml
│   └── types.bicep
├── components/                          # All component modules
│   ├── bing-search/
│   ├── enrich-subnets-with-nsgs/
│   ├── existing-vnet-subnets/
│   ├── existing-vnet-subnets-wrapper/
│   └── vnet-peering/
└── wrappers/                            # All AVM wrapper modules
    ├── avm.ptn.ai-ml.ai-foundry.bicep
    ├── avm.res.*.bicep
    └── (all other wrapper files)
```

**Pros:**
- ✅ Can modify and rebuild
- ✅ Source code included
- ✅ Full development capability
- ✅ Can create updated versions

**Cons:**
- ❌ Larger repository (~50+ MB with all wrappers)
- ❌ Requires Bicep CLI to rebuild

## 🚀 Quick Setup Script

Here's a PowerShell script to create the deployment package:

```powershell
# create-standalone-repo.ps1
$sourceRoot = "C:\DEMOTHIS\DELETEMEIMMEDIATELY\bicepaialz\bicep-avm-ptn-aiml-landing-zone\infra"
$targetRoot = "C:\path\to\your-new-repo"

# Create target structure
New-Item -ItemType Directory -Path "$targetRoot" -Force

# Copy portal package files
Copy-Item "$sourceRoot\portal-package\mainTemplate.json" "$targetRoot\"
Copy-Item "$sourceRoot\portal-package\createUiDefinition.json" "$targetRoot\"

# Copy source Bicep files (if you want to be able to modify)
Copy-Item "$sourceRoot\main.bicep" "$targetRoot\"
Copy-Item "$sourceRoot\main.bicepparam" "$targetRoot\"

# Copy build scripts
Copy-Item "$sourceRoot\build-arm-template.ps1" "$targetRoot\"
Copy-Item "$sourceRoot\build-arm-template.sh" "$targetRoot\"
Copy-Item "$sourceRoot\package-for-portal.ps1" "$targetRoot\"
Copy-Item "$sourceRoot\generate-github-deploy-url.ps1" "$targetRoot\"

# Copy dependencies
Copy-Item "$sourceRoot\common" "$targetRoot\common" -Recurse
Copy-Item "$sourceRoot\components" "$targetRoot\components" -Recurse
Copy-Item "$sourceRoot\wrappers" "$targetRoot\wrappers" -Recurse

# Copy documentation
Copy-Item "$sourceRoot\..\README.md" "$targetRoot\"
Copy-Item "$sourceRoot\..\docs" "$targetRoot\docs" -Recurse -ErrorAction SilentlyContinue

Write-Host "✅ Repository structure created at: $targetRoot"
```

## 📝 Minimal README.md for New Repo

Create this `README.md` in your new repo:

```markdown
# AI/ML Landing Zone - Portal Deployment

Deploy a secure AI/ML Landing Zone to Azure with a custom 6-step wizard.

## 🚀 Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2FYOUR-REPO%2Fmain%2FmainTemplate.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-ORG%2FYOUR-REPO%2Fmain%2FcreateUiDefinition.json)

**Replace `YOUR-ORG/YOUR-REPO` with your actual GitHub org/repo names**

## 📦 What's Included

### Installation Profiles

- **Full** (28 components) - Complete AI/ML platform
- **Core** (11 components) - Essential AI services
- **Custom** - Select individual components

### Components

- **Networking**: VNet, NSGs, Application Gateway, Azure Firewall
- **AI/ML**: AI Search, Cosmos DB, Storage, Key Vault, App Config
- **Observability**: Log Analytics, Application Insights
- **Container Platform**: Container Registry, Container Apps
- **Security**: Bastion, Jump VM, Build VM
- **Additional**: API Management, Bing Grounding

## 🛠️ Making Changes

If you need to modify the template:

1. Edit `main.bicep` (source code)
2. Run `./build-arm-template.ps1` (PowerShell) or `./build-arm-template.sh` (Bash)
3. Commit updated `mainTemplate.json`
4. Push to GitHub

## 📚 Deployment Steps

1. Click **Deploy to Azure** button above
2. Sign in to Azure Portal
3. Select subscription and resource group
4. Choose installation profile
5. Configure settings in 6-step wizard
6. Review and deploy

## ⏱️ Deployment Time

- Core profile: ~25 minutes
- Full profile: ~50 minutes

## 📖 Documentation

- Custom UI has inline help for all options
- Deployment outputs include all resource IDs
- Supports existing VNet integration
- Platform Landing Zone compatible

## 🔧 Alternative Deployment Methods

### Azure CLI (no custom UI)
```bash
az deployment group create \
  --resource-group <your-rg> \
  --template-file mainTemplate.json
```

### PowerShell
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName <your-rg> `
  -TemplateFile mainTemplate.json
```

## 📄 License

[Your License Here]
```

## ✅ Checklist for New Repo

After copying files:

- [ ] Update README.md with your GitHub org/repo name
- [ ] Update Deploy to Azure button URL
- [ ] Test deployment from your repo
- [ ] Add LICENSE file
- [ ] Add .gitignore:
  ```
  # Azure
  *.log
  .azure/
  
  # Build outputs (if you commit source)
  # portal-package/mainTemplate.json
  
  # OS
  .DS_Store
  Thumbs.db
  ```
- [ ] Set repository visibility (public for Deploy button to work)
- [ ] Tag initial release (v1.0.0)

## 🎯 Recommended: Minimal Deployment Repo

**For simplest deployment-only repository:**

```
your-new-repo/
├── .github/
│   └── workflows/
│       └── validate.yml          # Optional: validate on PR
├── mainTemplate.json              # 9.6 MB
├── createUiDefinition.json        # 33 KB  
├── README.md                      # With Deploy button
└── LICENSE
```

This is sufficient for Portal deployment via GitHub!

## 🔗 Deploy to Azure URL Format

Once files are in GitHub, the URL is:

```
https://portal.azure.com/#create/Microsoft.Template/uri/<ENCODED-TEMPLATE-URL>/createUIDefinitionUri/<ENCODED-UI-DEF-URL>
```

Where:
- `<ENCODED-TEMPLATE-URL>` = URL-encoded `https://raw.githubusercontent.com/YOUR-ORG/YOUR-REPO/main/mainTemplate.json`
- `<ENCODED-UI-DEF-URL>` = URL-encoded `https://raw.githubusercontent.com/YOUR-ORG/YOUR-REPO/main/createUiDefinition.json`

Use the `generate-github-deploy-url.ps1` script to create this automatically.

## ⚠️ Important Notes

1. **Repository must be PUBLIC** for raw.githubusercontent.com URLs to work
2. **Files must be in the main/master branch** (or specify branch in URL)
3. **No Azure Storage needed** - GitHub hosts everything
4. **No size limits** - GitHub handles the 9.6 MB template fine
5. **Custom UI works perfectly** with GitHub-hosted templates

## 🚦 Testing Your Setup

After pushing to GitHub:

1. Run `generate-github-deploy-url.ps1` with your org/repo
2. Click the generated URL
3. Verify the custom 6-step wizard appears
4. Test deployment to a dev resource group

---

**Bottom Line**: Copy just `mainTemplate.json` + `createUiDefinition.json` + `README.md` for a minimal deployment repo, or copy everything for full development capability.
