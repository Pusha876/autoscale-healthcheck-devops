#!/bin/bash

# Pipeline script to handle existing resource imports
# This script should be run before terraform apply in the pipeline

set -e

echo "=== Pipeline Import Script ==="
echo "Checking if container group needs to be imported..."

# Source variables from terraform.tfvars
USE_EXISTING=$(grep "use_existing_identity" terraform.tfvars | cut -d' ' -f3)
RESOURCE_GROUP=$(grep "resource_group_name" terraform.tfvars | cut -d'"' -f2)
APP_NAME=$(grep "app_name" terraform.tfvars | cut -d'"' -f2)

echo "USE_EXISTING_IDENTITY: $USE_EXISTING"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"
echo "APP_NAME: $APP_NAME"

if [[ "$USE_EXISTING" == "true" ]]; then
    echo "use_existing_identity is true, attempting to import existing container group..."
    
    CONTAINER_GROUP_ID="/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerInstance/containerGroups/$APP_NAME"
    
    # Check if resource already exists in state
    if terraform state show azurerm_container_group.app > /dev/null 2>&1; then
        echo "Container group already in Terraform state, skipping import"
    else
        echo "Importing existing container group: $CONTAINER_GROUP_ID"
        
        # Check if the Azure resource actually exists
        if az container show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
            echo "Azure container group exists, importing to Terraform state..."
            terraform import azurerm_container_group.app "$CONTAINER_GROUP_ID"
            echo "Import completed successfully"
        else
            echo "Azure container group does not exist, will be created by Terraform"
        fi
    fi
else
    echo "use_existing_identity is false, no import needed"
fi

echo "=== Pipeline Import Script Completed ==="
