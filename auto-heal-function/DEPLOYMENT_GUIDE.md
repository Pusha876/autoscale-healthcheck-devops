# Auto-Heal Function Testing and Deployment Guide

## Overview
This guide provides steps to test and deploy the auto-heal Azure Functions for container restart functionality.

## Available Functions

### 1. HTTP Trigger Function (`auto_heal_trigger`)
- **Purpose**: Responds to Azure Monitor alerts via webhook
- **Trigger**: HTTP POST requests from Azure Monitor
- **Location**: `auto_heal_trigger/`
- **Features**:
  - Parses Azure Monitor alert payloads
  - Performs health checks before restarting
  - Verifies restart success
  - Comprehensive logging

### 2. Timer Trigger Function (`timer_heal_trigger`)
- **Purpose**: Periodic health checks and auto-restart
- **Trigger**: Timer (every 5 minutes)
- **Location**: `timer_heal_trigger/`
- **Features**:
  - Automated health monitoring
  - Restart on health check failure
  - Verification of restart success

### 3. Simple Timer Function (`simple_heal_trigger`)
- **Purpose**: Simple periodic restart using Azure CLI
- **Trigger**: Timer (every 10 minutes)
- **Location**: `simple_heal_trigger/`
- **Features**:
  - Uses Azure CLI commands directly
  - Minimal dependencies
  - Simplified error handling

## Manual Testing

### Test the Container Restart Function

1. **Manual Container Restart via Azure CLI**:
   ```bash
   # Test direct container restart
   az container restart -g autoscale-rg -n autoscale-healthcheck
   
   # Verify restart
   az container show -g autoscale-rg -n autoscale-healthcheck --query "instanceView.state"
   ```

2. **Test Health Check Endpoint**:
   ```bash
   # Check if health endpoint is responding
   curl http://autoscale-healthcheck.westus2.azurecontainer.io:5000/health
   
   # Expected response: {"status": "healthy", "timestamp": "..."}
   ```

3. **Simulate Container Failure**:
   ```bash
   # Stop the container to simulate failure
   az container stop -g autoscale-rg -n autoscale-healthcheck
   
   # Check that health endpoint is unreachable
   curl http://autoscale-healthcheck.westus2.azurecontainer.io:5000/health
   # Should timeout or return connection error
   ```

## Function Deployment

### Option 1: Using Azure CLI (Recommended)
```bash
# Navigate to function directory
cd auto-heal-function

# Create deployment package
tar -czf function-package.tar.gz *

# Deploy using Azure CLI
az functionapp deployment source config-zip \
    --resource-group autoscale-rg \
    --name autoscale-heal-func \
    --src function-package.tar.gz
```

### Option 2: Using Azure Functions Core Tools
```bash
# Install Azure Functions Core Tools (if not installed)
npm install -g azure-functions-core-tools@4

# Deploy from function directory
cd auto-heal-function
func azure functionapp publish autoscale-heal-func
```

### Option 3: Manual Deployment via Portal
1. Open Azure Portal
2. Navigate to Function App: `autoscale-heal-func`
3. Go to "Deployment Center"
4. Choose "ZIP Deploy"
5. Upload the function package ZIP file

## Testing the Deployed Functions

### Test HTTP Trigger Function
```bash
# Get function URL
FUNCTION_URL=$(az functionapp function show \
    --resource-group autoscale-rg \
    --name autoscale-heal-func \
    --function-name auto_heal_trigger \
    --query "invokeUrlTemplate" -o tsv)

# Test with sample alert payload
curl -X POST "$FUNCTION_URL" \
    -H "Content-Type: application/json" \
    -d '{
        "data": {
            "essentials": {
                "severity": "Sev1",
                "alertRule": "auto-heal-test"
            }
        }
    }'
```

### Test Timer Functions
Timer functions will execute automatically based on their schedule:
- `timer_heal_trigger`: Every 5 minutes
- `simple_heal_trigger`: Every 10 minutes

Monitor execution in the Function App logs:
```bash
# View function logs
az webapp log tail --resource-group autoscale-rg --name autoscale-heal-func
```

## Monitoring and Troubleshooting

### Function App Status
```bash
# Check function app status
az functionapp show --resource-group autoscale-rg --name autoscale-heal-func \
    --query "{name:name,state:state,defaultHostName:defaultHostName}" --output table

# List deployed functions
az functionapp function list --resource-group autoscale-rg --name autoscale-heal-func --output table
```

### View Logs
```bash
# Enable detailed logging
az webapp log config --resource-group autoscale-rg --name autoscale-heal-func \
    --application-logging filesystem --level verbose

# View live logs
az webapp log tail --resource-group autoscale-rg --name autoscale-heal-func
```

### Alert Testing
To test the alert-based auto-heal:

1. **Generate errors in the container**:
   ```bash
   # Make requests that will generate errors
   for i in {1..10}; do
       curl http://autoscale-healthcheck.westus2.azurecontainer.io:5000/error || true
   done
   ```

2. **Check alert triggers**:
   - Wait 5-10 minutes for alert evaluation
   - Check Azure Monitor for fired alerts
   - Verify function execution in logs

## Environment Variables

The function app is configured with these environment variables:
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
- `RESOURCE_GROUP_NAME`: autoscale-rg
- `CONTAINER_GROUP_NAME`: autoscale-healthcheck
- `HEALTH_CHECK_URL`: http://autoscale-healthcheck.westus2.azurecontainer.io:5000/health

## Security Considerations

1. **Managed Identity**: The function uses user-assigned managed identity for authentication
2. **RBAC**: The identity has Contributor role on the resource group
3. **Network Security**: Function app is publicly accessible but requires proper authentication
4. **Logging**: All function executions are logged for audit purposes

## Troubleshooting Common Issues

### Function Not Deploying
- Check that the function app is in "Running" state
- Verify that the ZIP package contains all required files
- Ensure `host.json` and `requirements.txt` are in the root directory

### Function Not Executing
- Check function app configuration and runtime version
- Verify environment variables are set correctly
- Review function logs for errors

### Container Restart Fails
- Verify managed identity has proper permissions
- Check if container group exists and is accessible
- Ensure Azure CLI is available in the function environment

### Health Check Fails
- Verify container is running and accessible
- Check if health endpoint is responding correctly
- Confirm network connectivity from function app to container

## Next Steps

1. **Deploy Functions**: Use one of the deployment methods above
2. **Monitor Alerts**: Check that alerts are properly configured and firing
3. **Test Auto-Heal**: Simulate failures and verify automatic recovery
4. **Optimize Configuration**: Adjust alert thresholds and function schedules as needed
5. **Enhanced Monitoring**: Add more detailed logging and monitoring dashboards
