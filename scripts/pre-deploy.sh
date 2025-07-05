#!/bin/bash

# Pre-deployment script to check existing resources and set Terraform variables
# This script runs before Terraform to detect existing resources

set -e

echo "🔍 Checking for existing Azure resources..."

# Set default values
USE_EXISTING_IDENTITY=false
RESOURCES_FOUND=""

# Check if user-assigned identity exists
echo "Checking for existing user-assigned identity 'container-identity'..."
if az identity show --name "container-identity" --resource-group "autoscale-rg" > /dev/null 2>&1; then
    echo "✅ Found existing user-assigned identity 'container-identity'"
    USE_EXISTING_IDENTITY=true
    RESOURCES_FOUND="$RESOURCES_FOUND user-assigned-identity"
else
    echo "❌ User-assigned identity 'container-identity' not found"
fi

# Check if container group exists
echo "Checking for existing container group 'autoscale-healthcheck'..."
if az container show --name "autoscale-healthcheck" --resource-group "autoscale-rg" > /dev/null 2>&1; then
    echo "✅ Found existing container group 'autoscale-healthcheck'"
    RESOURCES_FOUND="$RESOURCES_FOUND container-group"
    
    # If container group exists, we might want to delete it for fresh deployment
    echo "🔄 Existing container group found. Considering cleanup..."
    echo "Container group will be recreated with new image."
else
    echo "❌ Container group 'autoscale-healthcheck' not found"
fi

# Check if ACR exists and is accessible
echo "Checking Azure Container Registry access..."
if az acr show --name "autoscalehealthcheckacr" --resource-group "autoscale-rg" > /dev/null 2>&1; then
    echo "✅ Azure Container Registry 'autoscalehealthcheckacr' is accessible"
else
    echo "❌ Azure Container Registry 'autoscalehealthcheckacr' not accessible"
    exit 1
fi

# Create terraform.tfvars file with detected settings
echo "📝 Creating terraform.tfvars with detected settings..."
cat > terraform.tfvars << EOF
# Auto-generated terraform.tfvars based on existing resources
use_existing_identity = $USE_EXISTING_IDENTITY
resource_group_name = "autoscale-rg"
location = "westus2"
app_name = "autoscale-healthcheck"
image_tag = "${IMAGE_TAG:-latest}"
EOF

echo "✅ terraform.tfvars created successfully"

# Display summary
echo ""
echo "📊 Resource Detection Summary:"
echo "================================"
echo "Resources found: ${RESOURCES_FOUND:-none}"
echo "Use existing identity: $USE_EXISTING_IDENTITY"
echo "Image tag: ${IMAGE_TAG:-latest}"
echo ""

# Display the tfvars content
echo "📄 Generated terraform.tfvars:"
cat terraform.tfvars

echo ""
echo "🚀 Ready for Terraform deployment!"
