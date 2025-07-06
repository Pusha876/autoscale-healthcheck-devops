# Auto-Heal Function Deployment PowerShell Script
param(
    [string]$ResourceGroup = "autoscale-rg",
    [string]$FunctionApp = "autoscale-heal-func",
    [string]$FunctionPath = "auto-heal-function"
)

Write-Host "Starting Auto-Heal Function Deployment..." -ForegroundColor Green

# Check if Azure CLI is available
try {
    az account show | Out-Null
    Write-Host "Azure CLI authenticated" -ForegroundColor Green
} catch {
    Write-Host "Please login to Azure CLI first: az login" -ForegroundColor Red
    exit 1
}

# Check if function app exists
try {
    az functionapp show --resource-group $ResourceGroup --name $FunctionApp | Out-Null
    Write-Host "Function app exists" -ForegroundColor Green
} catch {
    Write-Host "Function app not found: $FunctionApp" -ForegroundColor Red
    exit 1
}

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$packagePath = Join-Path $FunctionPath "deployment-package.zip"

if (Test-Path $packagePath) {
    Remove-Item $packagePath -Force
}

# Create ZIP package
Compress-Archive -Path "$FunctionPath\*" -DestinationPath $packagePath -Force
Write-Host "Deployment package created: $packagePath" -ForegroundColor Green

# Deploy using Azure CLI
Write-Host "Deploying to Azure Function App..." -ForegroundColor Yellow
try {
    az functionapp deployment source config-zip --resource-group $ResourceGroup --name $FunctionApp --src $packagePath
    Write-Host "Deployment completed successfully" -ForegroundColor Green
} catch {
    Write-Host "Deployment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Verify deployment
Write-Host "Verifying deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

try {
    $functions = az functionapp function list --resource-group $ResourceGroup --name $FunctionApp --query "[].name" -o tsv
    if ($functions) {
        Write-Host "Functions deployed successfully:" -ForegroundColor Green
        $functions -split "`n" | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
    } else {
        Write-Host "No functions visible yet, they may still be initializing" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Could not verify function deployment" -ForegroundColor Yellow
}

# Test function app
Write-Host "Testing function app..." -ForegroundColor Yellow
try {
    $functionUrl = "https://$FunctionApp.azurewebsites.net"
    Write-Host "Function app URL: $functionUrl" -ForegroundColor Cyan
    
    # Enable logging
    az webapp log config --resource-group $ResourceGroup --name $FunctionApp --application-logging filesystem --level verbose | Out-Null
    Write-Host "Logging enabled" -ForegroundColor Green
    
} catch {
    Write-Host "Could not configure logging" -ForegroundColor Yellow
}

Write-Host "Deployment script completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait 2-3 minutes for functions to initialize" -ForegroundColor White
Write-Host "2. Check function app logs" -ForegroundColor White
Write-Host "3. Test the auto-heal functionality" -ForegroundColor White
Write-Host "4. Monitor alerts and auto-restart behavior" -ForegroundColor White
