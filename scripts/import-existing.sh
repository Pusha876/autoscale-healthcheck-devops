#!/bin/bash

# Terraform import script for existing resources
# Run this script if you need to import existing resources into Terraform state

set -e

echo "🔄 Terraform Import Script for Existing Resources"
echo "================================================="

# Function to check if resource exists in state
check_state() {
    terraform state show "$1" > /dev/null 2>&1
}

# Function to import resource if it exists in Azure but not in state
import_if_exists() {
    local resource_type=$1
    local resource_name=$2
    local azure_id=$3
    
    if ! check_state "$resource_type.$resource_name"; then
        echo "Attempting to import $resource_type.$resource_name..."
        if terraform import "$resource_type.$resource_name" "$azure_id"; then
            echo "✅ Successfully imported $resource_type.$resource_name"
        else
            echo "❌ Failed to import $resource_type.$resource_name (may not exist)"
        fi
    else
        echo "ℹ️  Resource $resource_type.$resource_name already in state"
    fi
}

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Import user-assigned identity if it exists
echo ""
echo "Checking user-assigned identity..."
IDENTITY_ID="/subscriptions/b2dd5abd-3642-48b8-929e-2cafb8b4257d/resourceGroups/autoscale-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/container-identity"
import_if_exists "azurerm_user_assigned_identity" "container_identity" "$IDENTITY_ID"

# Note: We don't import role assignments as they can be recreated
# Note: We don't import container groups as they should be fresh deployments

echo ""
echo "✅ Import process completed!"
echo ""
echo "💡 Tips:"
echo "- Run 'terraform plan' to see what will be created/updated"
echo "- Role assignments will be recreated if they don't exist"
echo "- Container groups will always be created fresh with unique names"
