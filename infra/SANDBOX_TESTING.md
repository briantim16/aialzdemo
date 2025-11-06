# UI Definition Sandbox Testing Guide

## ✅ Pre-Test Checklist

- [x] createUiDefinition.json validated (0 errors)
- [x] Schema version: 0.1.2-preview
- [x] 6 wizard steps configured
- [x] 3 installation profiles (Full, Core, Custom)

## 🧪 Testing Steps

### 1. Open the Sandbox

Click this link to open the Azure Portal UI Definition Sandbox:
**[Open Create UI Definition Sandbox](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade)**

### 2. Load the UI Definition

1. Click **"Load Create UI Definition"** button
2. Browse to: `infra/createUiDefinition.json`
3. Click **Open**
4. Wait for the file to load

### 3. Preview the Wizard

Click the **"Preview"** button at the bottom of the sandbox

## 🎯 Test Cases

### Test Case 1: Full Profile (Default)

**Steps:**
1. Navigate through wizard steps
2. On "Installation Profile" step, ensure "Full" is selected by default
3. Verify profile summary shows all 28 components
4. Click "Next" - Component Selection should be HIDDEN
5. Complete all steps
6. Check outputs panel for `deployToggles` - all should be `true`

**Expected Results:**
```json
{
  "deployToggles": {
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
}
```

### Test Case 2: Core Profile

**Steps:**
1. Click "Previous" to go back to Installation Profile
2. Select "Core - Essential AI Services"
3. Verify profile summary shows 11 components
4. Click "Next" - Component Selection should be HIDDEN
5. Complete wizard
6. Check outputs for `deployToggles`

**Expected Results:**
```json
{
  "deployToggles": {
    "logAnalytics": true,
    "appInsights": true,
    "containerEnv": false,
    "containerRegistry": true,
    "cosmosDb": true,
    "keyVault": true,
    "storageAccount": true,
    "searchService": true,
    "groundingWithBingSearch": false,
    "appConfig": true,
    "apiManagement": false,
    "applicationGateway": false,
    "applicationGatewayPublicIp": false,
    "firewall": false,
    "containerApps": false,
    "buildVm": false,
    "bastionHost": false,
    "jumpVm": false,
    "virtualNetwork": true,
    "wafPolicy": false,
    "agentNsg": true,
    "peNsg": true,
    "applicationGatewayNsg": false,
    "apiManagementNsg": false,
    "acaEnvironmentNsg": false,
    "jumpboxNsg": false,
    "devopsBuildAgentsNsg": false
  }
}
```

### Test Case 3: Custom Profile

**Steps:**
1. Go back to Installation Profile
2. Select "Custom - Select Individual Components"
3. Click "Next" - Component Selection should be VISIBLE
4. Verify all checkboxes are UNCHECKED by default
5. Check a few components:
   - Networking: Virtual Network, Agent NSG
   - AI/ML Core: Azure AI Search, Key Vault, Storage Account
   - Observability: Log Analytics
6. Continue through wizard
7. Check outputs

**Expected Results:**
Only selected components should be `true`:
```json
{
  "deployToggles": {
    "logAnalytics": true,
    "appInsights": false,
    "containerEnv": false,
    "containerRegistry": false,
    "cosmosDb": false,
    "keyVault": true,
    "storageAccount": true,
    "searchService": true,
    "groundingWithBingSearch": false,
    "appConfig": false,
    "apiManagement": false,
    "applicationGateway": false,
    "applicationGatewayPublicIp": false,
    "firewall": false,
    "containerApps": false,
    "buildVm": false,
    "bastionHost": false,
    "jumpVm": false,
    "virtualNetwork": true,
    "wafPolicy": false,
    "agentNsg": true,
    "peNsg": false,
    "applicationGatewayNsg": false,
    "apiManagementNsg": false,
    "acaEnvironmentNsg": false,
    "jumpboxNsg": false,
    "devopsBuildAgentsNsg": false
  }
}
```

### Test Case 4: Network Configuration

**Steps:**
1. Navigate to "Network Configuration" step
2. Toggle "Platform Landing Zone Integration" checkbox
3. Verify info box appears when enabled
4. Select "Use existing VNet" option
5. Verify warning appears about providing resource ID
6. Continue to Advanced Configuration
7. Verify "Virtual Network Resource ID" field appears

**Expected Results:**
- Platform LZ toggle works
- Info boxes appear/disappear correctly
- VNet mode selection works
- UI responds to selections

### Test Case 5: Advanced Configuration

**Steps:**
1. Navigate to "Advanced Configuration" step
2. Enter a test Virtual Network Resource ID:
   ```
   /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet
   ```
3. Verify validation accepts it
4. Enter invalid ID (e.g., "test")
5. Verify validation error appears
6. Test other resource ID fields

**Expected Results:**
- Valid resource IDs accepted
- Invalid formats show validation errors
- Empty values accepted (optional fields)

### Test Case 6: Basics Step

**Steps:**
1. Go back to Basics (step 1)
2. Test "Base Name" field:
   - Enter valid: "myailz"
   - Enter invalid: "MyAILZ123" (too long)
   - Enter invalid: "MY-AILZ" (uppercase, dash)
3. Test "Resource Token" field similarly
4. Toggle "Enable Telemetry"

**Expected Results:**
- Validation enforces lowercase, alphanumeric only
- Max length 12 for baseName, 13 for resourceToken
- Fields are optional
- Telemetry defaults to "Yes"

## 📋 Verification Checklist

### Visual/UX
- [ ] Wizard loads without errors
- [ ] All 6 steps appear in navigation
- [ ] Step titles are clear
- [ ] Info boxes render correctly
- [ ] Help text (tooltips) appears on hover
- [ ] Navigation (Next/Previous) works

### Installation Profiles
- [ ] Dropdown shows 3 options
- [ ] Full profile summary displays
- [ ] Core profile summary displays
- [ ] Profile selection persists when navigating steps

### Component Selection (Custom)
- [ ] Step only visible in Custom mode
- [ ] All 28 checkboxes present
- [ ] Grouped into 6 sections
- [ ] All start unchecked
- [ ] Selections persist

### Network Configuration
- [ ] Platform LZ checkbox works
- [ ] Info box appears when enabled
- [ ] VNet mode selector works
- [ ] Warning appears for existing VNet

### Advanced Configuration
- [ ] Tags section displays
- [ ] Resource ID fields validate correctly
- [ ] Regex validation works
- [ ] Empty values allowed

### Outputs
- [ ] Output panel shows all parameters
- [ ] Profile selection controls deployToggles
- [ ] Custom mode uses checkbox values
- [ ] resourceIds object populated correctly
- [ ] All required parameters present

## 🐛 Common Issues & Fixes

### Issue: UI doesn't load
**Fix:** Check browser console for errors, verify JSON is valid

### Issue: Component Selection always visible
**Fix:** Check conditional visibility logic in step definition

### Issue: Profile outputs wrong values
**Fix:** Review conditional logic in outputs section

### Issue: Validation too strict/loose
**Fix:** Adjust regex patterns in constraints

### Issue: Outputs panel empty
**Fix:** Check all step names match in outputs section

## 📸 Expected Screenshots

### Step 1: Basics
- Subscription selector
- Resource Group selector
- Location (region) dropdown
- Base Name text box
- Resource Token text box
- Enable Telemetry toggle

### Step 2: Installation Profile
- Profile dropdown (Full/Core/Custom)
- Info box with link
- Profile summary (for Full/Core)
- Component counts visible

### Step 3: Component Selection (Custom only)
- 6 collapsible sections
- 28 checkboxes total
- All unchecked initially

### Step 4: Network Configuration
- Platform LZ checkbox
- Conditional info box
- VNet mode selector
- Conditional warning

### Step 5: Advanced Configuration
- Tags section (placeholder)
- Existing Resources section
- 6 resource ID text boxes

### Step 6: Review + Create
- Deployment summary
- Profile name
- Region
- Platform LZ status

## 🎓 Testing Tips

1. **Use browser dev tools** (F12) to see console errors
2. **Check the Outputs panel** after each navigation
3. **Test edge cases** (empty values, max lengths, special chars)
4. **Navigate backwards** to ensure state persists
5. **Clear and reload** to test fresh experience

## ✅ Success Criteria

The UI definition is ready for deployment if:

- ✅ All 6 steps render without errors
- ✅ All 3 profiles work correctly
- ✅ Custom mode shows/hides Component Selection
- ✅ All 28 components appear in Custom mode
- ✅ Outputs match expected values for each profile
- ✅ Validation works on text inputs
- ✅ Navigation works forward and backward
- ✅ No console errors in browser

## 📝 Test Results Template

```markdown
## Test Results - [Date]

**Tester:** [Your Name]
**Browser:** [Chrome/Edge/Firefox] [Version]
**Test Duration:** [X minutes]

### Test Case Results
- [ ] TC1: Full Profile - PASS/FAIL
- [ ] TC2: Core Profile - PASS/FAIL
- [ ] TC3: Custom Profile - PASS/FAIL
- [ ] TC4: Network Config - PASS/FAIL
- [ ] TC5: Advanced Config - PASS/FAIL
- [ ] TC6: Basics - PASS/FAIL

### Issues Found
1. [Issue description]
2. [Issue description]

### Screenshots
[Attach screenshots of each step]

### Recommendation
[ ] Ready for deployment
[ ] Needs fixes (see issues above)
```

---

**Ready to test?** Open the sandbox link at the top and follow the test cases!
