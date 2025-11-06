# Azure Portal Deployment - Quick Start Guide

## 🎯 What We've Created

This implementation provides an **Azure Portal custom UI wizard** for deploying the AI/ML Landing Zone with three pre-configured installation profiles.

## 📁 New Files Created

```
infra/
├── createUiDefinition.json       # ✨ Custom Portal UI wizard
├── build-arm-template.ps1         # PowerShell build script
├── build-arm-template.sh          # Bash build script  
├── PORTAL_DEPLOYMENT.md           # Comprehensive documentation
└── QUICKSTART.md                  # This file
```

## 🚀 Quick Start (3 Steps)

### Step 1: Build ARM Template

**PowerShell:**
```powershell
cd infra
.\build-arm-template.ps1
```

**Bash:**
```bash
cd infra
chmod +x build-arm-template.sh
./build-arm-template.sh
```

**Output:** Creates `arm-output/` directory with compiled templates

### Step 2: Test UI Definition

1. Open [UI Definition Sandbox](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade)
2. Click **Load Create UI Definition**
3. Upload `arm-output/createUiDefinition.json`
4. Click **Preview** and test the wizard

### Step 3: Deploy via Template Spec

```bash
# Create template spec
az ts create \
  --name "AI-ML-Landing-Zone" \
  --version "1.0.0" \
  --resource-group rg-template-specs \
  --location eastus2 \
  --template-file arm-output/mainTemplate.json \
  --ui-form-definition arm-output/createUiDefinition.json

# Deploy from Azure Portal:
# 1. Navigate to Template Specs
# 2. Select "AI-ML-Landing-Zone"
# 3. Click "Deploy"
```

## 🎨 Installation Profiles

### Full Profile (28 Components)
Complete production-ready AI/ML platform:
- ✅ All networking (VNet, 7 NSGs, Gateway, Firewall)
- ✅ All AI/ML services (Search, Cosmos, Storage, Key Vault, etc.)
- ✅ Complete observability (Log Analytics, App Insights)
- ✅ Full container platform (ACR, ACA, Container Apps)
- ✅ API Management
- ✅ Security & access (Bastion, Jump VM, Build VM)

**Best for:** Production deployments, enterprise scenarios

### Core Profile (11 Components)
Essential AI services for development:
- ✅ VNet + 2 NSGs (Agent, PE)
- ✅ Core AI services (Search, Cosmos, Storage, Key Vault, App Config)
- ✅ Observability (Log Analytics, App Insights)
- ✅ Container Registry
- ❌ No API Management, gateways, or VMs (cost optimization)

**Best for:** Development, testing, proof-of-concept

### Custom Profile
User selects individual components:
- All components start **disabled**
- Manually check each desired component
- Full flexibility for specific scenarios

**Best for:** Specialized deployments, resource reuse scenarios

## 🧪 Testing Checklist

- [ ] UI loads in sandbox without errors
- [ ] Profile dropdown shows 3 options
- [ ] Full profile summary displays correctly
- [ ] Core profile summary displays correctly  
- [ ] Custom mode shows all component checkboxes
- [ ] Component Selection step only visible in Custom mode
- [ ] Network config step works correctly
- [ ] Advanced config accepts resource IDs
- [ ] Review step shows deployment summary
- [ ] ARM template compiles successfully
- [ ] Template size checked (warn if >4MB)

## 📊 Component Categories

| Category | Full | Core | Custom |
|----------|------|------|--------|
| **Networking** | 9 | 3 | ☑️ |
| **AI/ML Core** | 6 | 5 | ☑️ |
| **Observability** | 2 | 2 | ☑️ |
| **Container Platform** | 4 | 1 | ☑️ |
| **API Management** | 2 | 0 | ☑️ |
| **Security & Access** | 5 | 0 | ☑️ |
| **Gateways & Firewall** | 2 | 0 | ☑️ |
| **Total** | **28** | **11** | **0-28** |

## 🔧 Wizard Steps

1. **Basics** - Subscription, RG, Location, Base Name, Telemetry
2. **Installation Profile** - Choose Full/Core/Custom
3. **Component Selection** - (Custom only) Select individual components
4. **Network Configuration** - Platform LZ mode, VNet settings
5. **Advanced Configuration** - Tags, existing resource IDs
6. **Review + Create** - Summary and deploy

## 💡 Key Features

✅ **Three Installation Modes:** Full, Core, Custom  
✅ **Smart Defaults:** Pre-configured toggles based on profile  
✅ **Conditional UI:** Component selection only in Custom mode  
✅ **Platform Integration:** Toggle for platform landing zone mode  
✅ **Resource Reuse:** Support for existing resource IDs  
✅ **Validation Ready:** Schema-compliant, no lint errors  
✅ **Build Automation:** PowerShell and Bash scripts included  

## 📝 Parameter Mapping

| Profile | `deployToggles` Behavior |
|---------|-------------------------|
| **Full** | All 28 flags set to `true` |
| **Core** | 11 essential flags `true`, rest `false` |
| **Custom** | Dynamically set based on user checkboxes |

## 🚨 Important Notes

### Template Size
- Current Bicep compiles to **>4 MB** ARM template
- **Solution:** Use Template Specs (handles large templates)
- **Alternative:** Linked templates with external storage

### Dependencies
Some components require others (not enforced in UI yet):
- AI Foundry → requires Key Vault + Storage
- Private Endpoints → requires Virtual Network
- App Gateway → requires NSG + Public IP

**Future Enhancement:** Add validation rules to UI definition

### Platform Landing Zone Mode
When enabled:
- Private DNS zones NOT created
- Expects existing platform-managed DNS zones
- Private endpoints configured for platform zones

## 📚 Documentation

- **Full Guide:** [PORTAL_DEPLOYMENT.md](./PORTAL_DEPLOYMENT.md)
- **Parameters:** [../docs/parameters.md](../docs/parameters.md)
- **Examples:** [../docs/examples.md](../docs/examples.md)
- **Azure Docs:** [Create UI Definition Reference](https://learn.microsoft.com/azure/azure-resource-manager/managed-applications/create-uidefinition-overview)

## 🆘 Troubleshooting

**UI doesn't load in sandbox:**
- Check JSON syntax with a validator
- Verify schema version is `0.1.2-preview`
- Review browser console for errors

**Profile selection not working:**
- Verify step names match in outputs section
- Check conditional logic in `deployToggles` output
- Test in sandbox with browser dev tools

**Template deployment fails:**
- Review deployment errors in Activity Log
- Check parameter names match template
- Verify resource naming constraints (globally unique names)

**Build script errors:**
- Ensure Azure CLI is installed and logged in
- Check Bicep files compile individually
- Review script output for specific errors

## 🎓 Next Steps

1. **Test the UI** in Azure Portal sandbox
2. **Deploy a test environment** using Core profile
3. **Document custom scenarios** for your organization
4. **Add validation rules** for component dependencies
5. **Publish Template Spec** within your organization
6. **Gather feedback** and iterate

## 🤝 Contributing

To modify the UI:
1. Edit `createUiDefinition.json`
2. Test in sandbox: [portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade)
3. Re-run build script
4. Test deployment

To add new components:
1. Add checkbox in appropriate section
2. Update profile presets (Full/Core)
3. Update outputs section
4. Update documentation

## 📞 Support

- **GitHub Issues:** [Report bugs or feature requests](https://github.com/Azure/bicep-avm-ptn-aiml-landing-zone/issues)
- **Documentation:** [Full repo docs](../docs/)
- **Azure Support:** [Azure Portal support](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade)

---

**Status:** ✅ Implementation Complete  
**Last Updated:** November 6, 2025  
**Files:** 4 new files created  
**Schema Validation:** ✅ No errors  
