# 🧪 Interactive Testing Session

## Current Status
✅ **createUiDefinition.json validated successfully**
- Valid JSON syntax
- Correct schema (0.1.2-preview)
- 5 wizard steps + basics
- 27 components in custom mode
- All outputs configured
- File size: 29.38 KB

## 🚀 How to Test RIGHT NOW

### Option 1: In VS Code Simple Browser (Already Open!)

The sandbox should be loaded in VS Code. If not visible:
1. Look for "Simple Browser" tab in VS Code
2. Or run: `Ctrl+Shift+P` → "Simple Browser: Show"

### Option 2: In Your Default Browser

1. **Click this link:** https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade
2. Sign in to Azure Portal if needed

## 📝 Step-by-Step Testing

### Step 1️⃣: Load the UI Definition

In the sandbox:
1. Click **"Load Create UI Definition"** button (top right)
2. Browse to and select:
   ```
   C:\DEMOTHIS\DELETEMEIMMEDIATELY\bicepaialz\bicep-avm-ptn-aiml-landing-zone\infra\createUiDefinition.json
   ```
3. Wait for "Loaded successfully" message

### Step 2️⃣: Preview the Wizard

1. Click **"Preview"** button at the bottom
2. The wizard should open with 6 steps:
   - **Basics** (auto-generated)
   - **Installation Profile**
   - **Component Selection** (conditional)
   - **Network Configuration**
   - **Advanced Configuration**
   - **Review + Create**

### Step 3️⃣: Test the Full Profile

1. **Basics Step:**
   - Leave fields empty or fill:
     - Base Name: `myailz`
     - Resource Token: `test123`
   - Click **Next**

2. **Installation Profile:**
   - Select: **"Full - Complete AI/ML Platform"**
   - You should see summary showing 28 components
   - Click **Next**

3. **Notice:** Component Selection step should be **SKIPPED** (hidden)

4. **Network Configuration:**
   - Leave Platform LZ unchecked
   - Keep "Create new VNet" selected
   - Click **Next**

5. **Advanced Configuration:**
   - Leave all fields empty
   - Click **Next**

6. **Review + Create:**
   - Check the summary
   - Click **View outputs** tab at bottom

7. **Verify Outputs:**
   - Expand `deployToggles` object
   - ALL 28 properties should be `true`
   ```json
   "logAnalytics": true,
   "appInsights": true,
   "virtualNetwork": true,
   // ... all true
   ```

✅ **Full Profile Test: PASS** if all toggles are true

### Step 4️⃣: Test the Core Profile

1. Click **"Previous"** until you're back at Installation Profile
2. Select: **"Core - Essential AI Services"**
3. You should see summary showing 11 components
4. Click through all steps
5. At Review, check outputs:
   - Only these should be `true`:
     - logAnalytics, appInsights, containerRegistry
     - cosmosDb, keyVault, storageAccount
     - searchService, appConfig
     - virtualNetwork, agentNsg, peNsg
   - All others should be `false`

✅ **Core Profile Test: PASS** if only 11 toggles are true

### Step 5️⃣: Test the Custom Profile

1. Go back to Installation Profile
2. Select: **"Custom - Select Individual Components"**
3. Click **Next**
4. **NOW** Component Selection should be **VISIBLE**
5. You should see 6 sections:
   - Networking Components
   - AI/ML Core Services
   - Observability & Monitoring
   - Container Platform
   - API Management
   - Security & Access
6. **All checkboxes should be UNCHECKED**
7. Check a few boxes:
   - ☑️ Virtual Network
   - ☑️ Agent Subnet NSG
   - ☑️ Azure AI Search
   - ☑️ Key Vault
   - ☑️ Log Analytics Workspace
8. Click through to Review
9. Check outputs - only your checked items should be `true`

✅ **Custom Profile Test: PASS** if selections match outputs

### Step 6️⃣: Test Network Configuration

1. Go to Network Configuration step
2. **Check** "Platform Landing Zone Integration"
3. Info box should appear explaining platform mode
4. Change VNet mode to "Use existing VNet"
5. Warning should appear
6. Continue to Advanced Configuration
7. Virtual Network Resource ID field should be visible

✅ **Network Config Test: PASS** if UI responds to changes

### Step 7️⃣: Test Validation

1. Go to Advanced Configuration
2. In "Virtual Network Resource ID" field, enter:
   ```
   invalid-text
   ```
3. Click in another field
4. You should see validation error (red text)
5. Enter valid format:
   ```
   /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet
   ```
6. Error should disappear

✅ **Validation Test: PASS** if validation works

## 🎯 Quick Test Checklist

Run through this checklist:

- [ ] Sandbox opens without errors
- [ ] UI definition loads successfully
- [ ] Preview button works
- [ ] All 6 steps appear
- [ ] Full profile shows 28 components summary
- [ ] Core profile shows 11 components summary
- [ ] Custom profile hides Component Selection initially
- [ ] Selecting Custom shows Component Selection step
- [ ] All 27 checkboxes appear in Custom mode
- [ ] Platform LZ checkbox triggers info box
- [ ] VNet mode selector works
- [ ] Resource ID validation works
- [ ] Outputs panel shows all parameters
- [ ] Full profile outputs all true
- [ ] Core profile outputs 11 true, 17 false
- [ ] Custom profile outputs match selections

## 🐛 Troubleshooting

### Sandbox won't load
- **Fix:** Ensure you're signed into Azure Portal
- **Fix:** Try different browser (Chrome/Edge recommended)
- **Fix:** Clear browser cache

### Can't upload file
- **Fix:** Check file path is correct
- **Fix:** Ensure file is valid JSON (run validate-ui.ps1)

### Errors in console
- **Fix:** Press F12, check Console tab for details
- **Fix:** Copy error and review against schema

### Profile selection not working
- **Fix:** Check browser console for JavaScript errors
- **Fix:** Reload sandbox and try again

### Outputs not showing expected values
- **Fix:** Check "View outputs" tab (may need to expand)
- **Fix:** Navigate to Review step first

## 📸 What You Should See

### Installation Profile Step
```
┌─────────────────────────────────────────┐
│ Installation Profile                     │
├─────────────────────────────────────────┤
│ ℹ️ Info box with link to GitHub         │
│                                          │
│ Installation Profile ▼                   │
│ ┌─────────────────────────────────────┐ │
│ │ Full - Complete AI/ML Platform      │ │ ← Selected
│ │ Core - Essential AI Services        │ │
│ │ Custom - Select Individual...       │ │
│ └─────────────────────────────────────┘ │
│                                          │
│ Selected Profile Summary                 │
│ ✓ Networking: VNet, 7 NSGs, ...        │
│ ✓ AI/ML Core: Search, Cosmos, ...      │
│ ✓ Observability: ...                    │
│   ...                                    │
│ Total: 28 components                     │
└─────────────────────────────────────────┘
```

### Component Selection (Custom Mode)
```
┌─────────────────────────────────────────┐
│ Component Selection                      │
├─────────────────────────────────────────┤
│ ℹ️ In Custom mode, all start disabled   │
│                                          │
│ ▼ Networking Components                 │
│   ☐ Virtual Network                     │
│   ☐ Agent Subnet NSG                    │
│   ☐ Private Endpoints Subnet NSG        │
│   ...                                    │
│                                          │
│ ▼ AI/ML Core Services                   │
│   ☐ Azure AI Search                     │
│   ☐ Cosmos DB                           │
│   ...                                    │
└─────────────────────────────────────────┘
```

## ✅ Test Completion

Once you've verified all items above:

1. **Take screenshots** of each step
2. **Copy the outputs JSON** from the outputs panel
3. **Document any issues** you found
4. **Report back** with results!

---

## 📋 Test Report Template

Copy this and fill in your results:

```markdown
## UI Definition Test Report

**Date:** November 6, 2025
**Tester:** [Your Name]
**Browser:** [Browser + Version]
**Duration:** [X minutes]

### Test Results
- [ ] ✅ PASS - Full Profile (all 28 true)
- [ ] ✅ PASS - Core Profile (11 true, 17 false)
- [ ] ✅ PASS - Custom Profile (selections match)
- [ ] ✅ PASS - Network Configuration
- [ ] ✅ PASS - Validation
- [ ] ✅ PASS - UI Rendering

### Issues Found
[None / List issues]

### Screenshots
[Attach if needed]

### Overall Status
[ ] ✅ READY FOR PRODUCTION
[ ] ⚠️ NEEDS MINOR FIXES
[ ] ❌ NEEDS MAJOR FIXES

### Notes
[Any additional observations]
```

---

**🎉 Happy Testing!** The sandbox is ready and waiting for you!
