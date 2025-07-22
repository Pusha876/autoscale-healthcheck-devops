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

if ($useExisting -eq "true") {
    Write-Host "use_existing_identity is true, attempting to import existing container group..." -ForegroundColor Cyan
    
    $containerGroupId = "/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$resourceGroup/providers/Microsoft.ContainerInstance/containerGroups/$appName"
    
    # Check if resource already exists in state
    try {
        terraform state show azurerm_container_group.app | Out-Null
        Write-Host "Container group already in Terraform state, skipping import" -ForegroundColor Green
    }
    catch {
        Write-Host "Container group not in state, checking if it exists in Azure..." -ForegroundColor Yellow
        
        # Check if the Azure resource actually exists
        try {
            az container show --name $appName --resource-group $resourceGroup | Out-Null
            Write-Host "Azure container group exists, importing to Terraform state..." -ForegroundColor Cyan
            terraform import azurerm_container_group.app $containerGroupId
            Write-Host "Import completed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "Azure container group does not exist, will be created by Terraform" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "use_existing_identity is false, no import needed" -ForegroundColor Green
}

Write-Host "=== Pipeline Import Script Completed ===" -ForegroundColor Green
