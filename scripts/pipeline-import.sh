#!/bin/bash

# Pipeline script to handle existing resource imports
# This script should be run before terraform apply in the pipeline

set -e

echo "=== Pipeline Import Script ==="
echo "Checking if resources need to be imported..."

# Source variables from terraform.tfvars
USE_EXISTING=$(grep "use_existing_identity" terraform.tfvars | cut -d' ' -f3)
RESOURCE_GROUP=$(grep "resource_group_name" terraform.tfvars | cut -d'"' -f2)
APP_NAME=$(grep "app_name" terraform.tfvars | cut -d'"' -f2)

echo "USE_EXISTING_IDENTITY: $USE_EXISTING"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"
echo "APP_NAME: $APP_NAME"

# Function to import resource if it exists in Azure but not in Terraform state
import_if_needed() {
    local terraform_resource=$1
    local azure_resource_id=$2
    local azure_check_command=$3
    local resource_name=$4
    
    echo "Checking $resource_name..."
    
    # Check if resource already exists in state
    if terraform state show $terraform_resource > /dev/null 2>&1; then
        echo "$resource_name already in Terraform state, skipping import"
    else
        echo "$resource_name not in state, checking if it exists in Azure..."
        
        # Check if the Azure resource actually exists
        if eval $azure_check_command > /dev/null 2>&1; then
            echo "Azure $resource_name exists, importing to Terraform state..."
            # Use MSYS_NO_PATHCONV=1 to prevent Git Bash path conversion on Windows
            MSYS_NO_PATHCONV=1 terraform import $terraform_resource "$azure_resource_id"
            echo "$resource_name import completed successfully"
        else
            echo "Azure $resource_name does not exist, will be created by Terraform"
        fi
    fi
}

# Import container group if needed
if [[ "$USE_EXISTING" == "true" ]]; then
    CONTAINER_GROUP_ID="/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerInstance/containerGroups/$APP_NAME"
    import_if_needed "azurerm_container_group.app" "$CONTAINER_GROUP_ID" "az container show --name $APP_NAME --resource-group $RESOURCE_GROUP" "Container Group"
fi

# Import Log Analytics Workspace if it exists
LAW_ID="/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/autoscale-law"
import_if_needed "azurerm_log_analytics_workspace.log" "$LAW_ID" "az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP --workspace-name autoscale-law" "Log Analytics Workspace"

# Import User Assigned Identity if it exists
IDENTITY_ID="/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/container-identity"
import_if_needed "azurerm_user_assigned_identity.container_identity" "$IDENTITY_ID" "az identity show --name container-identity --resource-group $RESOURCE_GROUP" "User Assigned Identity"

# Import Function App if it exists
FUNCTION_ID="/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/autoscale-heal-func"
import_if_needed "azurerm_linux_function_app.auto_heal" "$FUNCTION_ID" "az functionapp show --name autoscale-heal-func --resource-group $RESOURCE_GROUP" "Function App"

# Import Service Plan if it exists
PLAN_ID="/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/serverFarms/autoscale-heal-plan"
import_if_needed "azurerm_service_plan.function_plan" "$PLAN_ID" "az appservice plan show --name autoscale-heal-plan --resource-group $RESOURCE_GROUP" "Service Plan"

echo "=== Pipeline Import Script Completed ==="
