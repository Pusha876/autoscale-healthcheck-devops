#!/bin/bash

# Auto-Heal Function Deployment Script
set -e

echo "🚀 Starting Auto-Heal Azure Function Deployment..."

# Configuration
FUNCTION_APP_NAME="autoscale-heal-func"
RESOURCE_GROUP="autoscale-rg"
FUNCTION_DIR="auto-heal-function"

# Check if Azure CLI is logged in
if ! az account show > /dev/null 2>&1; then
    echo "❌ Please log in to Azure CLI first: az login"
    exit 1
fi

# Check if function directory exists
if [ ! -d "$FUNCTION_DIR" ]; then
    echo "❌ Function directory not found: $FUNCTION_DIR"
    exit 1
fi

echo "📦 Preparing function package..."

# Create a temporary directory for deployment
TEMP_DIR=$(mktemp -d)
cp -r $FUNCTION_DIR/* $TEMP_DIR/

# Create deployment package
cd $TEMP_DIR
zip -r function-package.zip . -x "*.pyc" "__pycache__/*" ".git/*"

echo "☁️ Deploying to Azure Function App: $FUNCTION_APP_NAME"

# Deploy the function
az functionapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP \
    --name $FUNCTION_APP_NAME \
    --src function-package.zip

echo "🔧 Configuring function app settings..."

# Update function app configuration
az functionapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $FUNCTION_APP_NAME \
    --settings \
        "FUNCTIONS_WORKER_RUNTIME=python" \
        "AzureWebJobsFeatureFlags=EnableWorkerIndexing" \
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false"

echo "🩺 Testing function health..."

# Get function URL
FUNCTION_URL=$(az functionapp function show \
    --resource-group $RESOURCE_GROUP \
    --name $FUNCTION_APP_NAME \
    --function-name auto_heal_trigger \
    --query "invokeUrlTemplate" -o tsv)

if [ -n "$FUNCTION_URL" ]; then
    echo "✅ Function deployed successfully!"
    echo "📍 Function URL: $FUNCTION_URL"
    echo "🔗 You can test the function using the Azure portal or direct HTTP calls"
else
    echo "⚠️ Function deployed but URL not available yet. Check Azure portal."
fi

# Cleanup
rm -rf $TEMP_DIR

echo "🎉 Auto-Heal function deployment completed!"
echo ""
echo "📋 Next steps:"
echo "1. Verify the function is running in Azure portal"
echo "2. Test the auto-heal functionality"
echo "3. Monitor alert integrations"
echo ""
echo "🔍 To check function logs:"
echo "az functionapp logs tail --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME"
