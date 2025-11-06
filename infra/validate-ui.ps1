#!/usr/bin/env pwsh
# Quick validation script for createUiDefinition.json

param(
    [string]$FilePath = "$PSScriptRoot/createUiDefinition.json"
)

Write-Host "🔍 Validating createUiDefinition.json..." -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $FilePath)) {
    Write-Host "❌ File not found: $FilePath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ File exists" -ForegroundColor Green

# Try to parse as JSON
try {
    $json = Get-Content $FilePath -Raw | ConvertFrom-Json
    Write-Host "✅ Valid JSON syntax" -ForegroundColor Green
}
catch {
    Write-Host "❌ Invalid JSON syntax" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Check schema
$expectedSchema = "https://schema.management.azure.com/schemas/0.1.2-preview/CreateUIDefinition.MultiVm.json#"
if ($json.'$schema' -eq $expectedSchema) {
    Write-Host "✅ Correct schema version: 0.1.2-preview" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Schema: $($json.'$schema')" -ForegroundColor Yellow
}

# Check handler
if ($json.handler -eq "Microsoft.Azure.CreateUIDef") {
    Write-Host "✅ Correct handler" -ForegroundColor Green
}
else {
    Write-Host "❌ Invalid handler: $($json.handler)" -ForegroundColor Red
}

# Check version
if ($json.version -eq "0.1.2-preview") {
    Write-Host "✅ Correct version" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Version: $($json.version)" -ForegroundColor Yellow
}

# Check steps count
$stepCount = $json.parameters.steps.Count
Write-Host "✅ Steps defined: $stepCount" -ForegroundColor Green

# List steps
Write-Host ""
Write-Host "📋 Wizard Steps:" -ForegroundColor Cyan
for ($i = 0; $i -lt $stepCount; $i++) {
    $step = $json.parameters.steps[$i]
    Write-Host "  $($i + 1). $($step.label) ($($step.name))" -ForegroundColor Gray
}

# Check outputs
Write-Host ""
Write-Host "📤 Output Parameters:" -ForegroundColor Cyan
$json.parameters.outputs.PSObject.Properties | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Gray
}

# Count elements in Component Selection step
$componentStep = $json.parameters.steps | Where-Object { $_.name -eq "componentSelection" }
if ($componentStep) {
    $totalComponents = 0
    $componentStep.elements | ForEach-Object {
        if ($_.type -eq "Microsoft.Common.Section") {
            $totalComponents += $_.elements.Count
        }
    }
    Write-Host ""
    Write-Host "✅ Component Selection: $totalComponents components" -ForegroundColor Green
}

# File size
$fileSize = (Get-Item $FilePath).Length
$fileSizeKB = [math]::Round($fileSize / 1KB, 2)
Write-Host ""
Write-Host "📏 File size: $fileSizeKB KB" -ForegroundColor Cyan

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✨ Validation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open Azure Portal Sandbox:" -ForegroundColor White
Write-Host "     https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Click 'Load Create UI Definition'" -ForegroundColor White
Write-Host ""
Write-Host "  3. Select this file:" -ForegroundColor White
Write-Host "     $FilePath" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Click 'Preview' to test the wizard" -ForegroundColor White
Write-Host ""
Write-Host "  5. Follow test cases in SANDBOX_TESTING.md" -ForegroundColor White
Write-Host ""
Write-Host "📚 Documentation: PORTAL_DEPLOYMENT.md" -ForegroundColor Cyan
Write-Host ""
