# Pipeline script to handle existing resource imports (PowerShell version)
# This script should be run before terraform apply in the pipeline

param(
    [string]$TerraformPath = "."
)

Write-Host "=== Pipeline Import Script (PowerShell) ===" -ForegroundColor Green

# Change to terraform directory
Set-Location $TerraformPath

# Read terraform.tfvars
$tfvarsContent = Get-Content "terraform.tfvars"
$useExisting = ($tfvarsContent | Select-String "use_existing_identity" | ForEach-Object { $_.Line.Split('=')[1].Trim() })
$resourceGroup = ($tfvarsContent | Select-String "resource_group_name" | ForEach-Object { $_.Line.Split('"')[1] })
$appName = ($tfvarsContent | Select-String "app_name" | ForEach-Object { $_.Line.Split('"')[1] })

Write-Host "USE_EXISTING_IDENTITY: $useExisting" -ForegroundColor Yellow
Write-Host "RESOURCE_GROUP: $resourceGroup" -ForegroundColor Yellow
Write-Host "APP_NAME: $appName" -ForegroundColor Yellow

# Function to import resource if it exists in Azure but not in Terraform state
function Import-IfNeeded {
    param(
        [string]$TerraformResource,
        [string]$AzureResourceId,
        [string]$AzureCheckCommand,
        [string]$ResourceName
    )
    
    Write-Host "Checking $ResourceName..." -ForegroundColor Cyan
    
    # Check if resource already exists in state
    try {
        terraform state show $TerraformResource | Out-Null
        Write-Host "$ResourceName already in Terraform state, skipping import" -ForegroundColor Green
    }
    catch {
        Write-Host "$ResourceName not in state, checking if it exists in Azure..." -ForegroundColor Yellow
        
        # Check if the Azure resource actually exists
        try {
            Invoke-Expression $AzureCheckCommand | Out-Null
            Write-Host "Azure $ResourceName exists, importing to Terraform state..." -ForegroundColor Cyan
            terraform import $TerraformResource $AzureResourceId
            Write-Host "$ResourceName import completed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "Azure $ResourceName does not exist, will be created by Terraform" -ForegroundColor Yellow
        }
    }
}

# Import container group if needed
if ($useExisting -eq "true") {
    $containerGroupId = "/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$resourceGroup/providers/Microsoft.ContainerInstance/containerGroups/$appName"
    Import-IfNeeded "azurerm_container_group.app" $containerGroupId "az container show --name $appName --resource-group $resourceGroup" "Container Group"
}

# Import Log Analytics Workspace if it exists
$lawId = "/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$resourceGroup/providers/Microsoft.OperationalInsights/workspaces/autoscale-law"
Import-IfNeeded "azurerm_log_analytics_workspace.log" $lawId "az monitor log-analytics workspace show --resource-group $resourceGroup --workspace-name autoscale-law" "Log Analytics Workspace"

# Import User Assigned Identity if it exists
$identityId = "/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$resourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/container-identity"
Import-IfNeeded "azurerm_user_assigned_identity.container_identity" $identityId "az identity show --name container-identity --resource-group $resourceGroup" "User Assigned Identity"

# Import Function App if it exists
$functionId = "/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/autoscale-heal-func"
Import-IfNeeded "azurerm_linux_function_app.auto_heal" $functionId "az functionapp show --name autoscale-heal-func --resource-group $resourceGroup" "Function App"

# Import Service Plan if it exists
$planId = "/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$resourceGroup/providers/Microsoft.Web/serverFarms/autoscale-heal-plan"
Import-IfNeeded "azurerm_service_plan.function_plan" $planId "az appservice plan show --name autoscale-heal-plan --resource-group $resourceGroup" "Service Plan"

Write-Host "=== Pipeline Import Script Completed ===" -ForegroundColor Green
