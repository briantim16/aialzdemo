# 🚀 Quick Deploy Guide - AI/ML Landing Zone

## ✅ Verified Method for 9.6 MB Template

The Azure Portal **Custom Deployment** feature supports large templates with custom UI definitions.

## 📋 3-Minute Deployment Steps

### 1. Open Azure Portal Custom Template

Click this link: **https://portal.azure.com/#create/Microsoft.Template**

### 2. Upload Template (9.6 MB)

1. Click **"Build your own template in the editor"**
2. Click **"Load file"**
3. Browse to: `infra/portal-package/mainTemplate.json`
4. Wait ~15 seconds for upload
5. Click **"Save"**

### 3. Upload Custom UI (33 KB)

1. Click **"Edit UI definition"** (top of page, near template name)
2. Click **"Load file"**
3. Browse to: `infra/portal-package/createUiDefinition.json`
4. Click **"Save and close"**

### 4. Fill in 6-Step Wizard

The custom wizard will appear with these steps:

**Basics**
- Subscription & Resource Group
- Region
- Optional: Base name & resource token

**Installation Profile**
- Full (28 components) ← Recommended for complete setup
- Core (11 components) ← Recommended for essential AI services
- Custom (select individual components)

**Component Selection**
- Only shown if "Custom" profile selected
- Toggle individual components on/off

**Network Configuration**
- Platform Landing Zone: Yes/No
- VNet: Create new or use existing

**Advanced Configuration**
- Optional: Existing resource IDs to reuse
- Optional: Custom tags

**Review + Create**
- Review configuration
- Click **Create**

### 5. Monitor Deployment

- ⏱️ Core profile: ~25 minutes
- ⏱️ Full profile: ~50 minutes
- Watch progress in Notifications (bell icon)

## 🎉 Done!

Your AI/ML Landing Zone is deployed with:
- ✅ Private networking
- ✅ AI services (Search, Storage, Key Vault, etc.)
- ✅ Monitoring (Log Analytics, App Insights)
- ✅ Container platform (optional)
- ✅ Security controls (NSGs, Private Endpoints)

---

## ❓ Why Not Template Spec?

Template Specs have a **4 MB limit** via `az ts create`. This template is 9.6 MB, so we use **Portal Custom Deployment** instead, which has no size limit.

## 🔧 Alternative: Deploy via CLI (No Wizard)

If you prefer command-line:

```bash
az deployment group create \
  --resource-group <your-rg-name> \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

This uses the Bicep source (no UI wizard) but works for any size.

---

**Files Needed:**
- ✅ `infra/portal-package/mainTemplate.json` (created by `package-for-portal.ps1`)
- ✅ `infra/portal-package/createUiDefinition.json` (created by `package-for-portal.ps1`)

**If you don't have these files yet:**
```powershell
cd infra
./package-for-portal.ps1
```
