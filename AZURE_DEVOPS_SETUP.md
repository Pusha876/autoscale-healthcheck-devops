# Azure DevOps Pipeline Setup Guide

This document provides step-by-step instructions for setting up the Azure DevOps pipeline for the Health Check API project.

## Prerequisites

1. Azure DevOps organization and project
2. Azure subscription with appropriate permissions
3. GitHub repository with the project code
4. Azure Container Registry (ACR) already created

## Required Service Connections

You need to create two service connections in Azure DevOps:

### 1. Docker Registry Service Connection

**Name**: `autoscalehealthcheckacr-docker`
**Type**: Docker Registry

**Steps**:
1. Go to Azure DevOps → Project Settings → Service connections
2. Click "New service connection"
3. Select "Docker Registry"
4. Choose "Azure Container Registry"
5. Fill in the details:
   - **Connection name**: `autoscalehealthcheckacr-docker`
   - **Azure subscription**: Select your subscription
   - **Azure container registry**: Select `autoscalehealthcheckacr`
   - **Service connection name**: `autoscalehealthcheckacr-docker`
6. Click "Save"

### 2. Azure Resource Manager Service Connection

**Name**: `autoscalehealthcheckacr-arm`
**Type**: Azure Resource Manager

**Steps**:
1. Go to Azure DevOps → Project Settings → Service connections
2. Click "New service connection"
3. Select "Azure Resource Manager"
4. Choose "Service principal (automatic)"
5. Fill in the details:
   - **Scope level**: Subscription
   - **Subscription**: Select your subscription
   - **Resource group**: Leave empty (full subscription access)
   - **Service connection name**: `autoscalehealthcheckacr-arm`
6. Click "Save"

## Pipeline Setup

1. **Create Pipeline**:
   - Go to Azure DevOps → Pipelines → Create Pipeline
   - Select "GitHub" as source
   - Choose your repository
   - Select "Existing Azure Pipelines YAML file"
   - Choose the path: `/.azure-pipelines/ci-pipeline.yml`

2. **Configure Variables** (Optional):
   - You can override the default variables in the pipeline if needed
   - Go to Pipelines → Edit → Variables
   - Add any environment-specific variables

## Pipeline Stages

The pipeline consists of two main stages:

### Build Stage
- **Python Setup**: Uses Python 3.10
- **Install Dependencies**: Installs packages from requirements.txt
- **Run Tests**: Executes pytest unit tests
- **Build and Push Docker Image**: Builds Docker image and pushes to ACR

### Deploy Stage
- **Install Terraform**: Downloads and installs Terraform
- **Terraform Init**: Initializes Terraform configuration
- **Terraform Plan**: Plans infrastructure changes
- **Terraform Apply**: Applies infrastructure changes
- **Get Deployment Output**: Retrieves the health check URL

## Expected Outputs

Upon successful completion, the pipeline will:
1. Build and test the Python application
2. Create and push a Docker image to ACR
3. Deploy the infrastructure using Terraform
4. Provide the health check URL for verification

## Troubleshooting

### Common Issues

1. **Service Connection Not Found**:
   - Verify service connection names match exactly
   - Check service connection permissions

2. **Docker Push Fails**:
   - Ensure ACR has admin user enabled
   - Verify Docker service connection credentials

3. **Terraform Apply Fails**:
   - Check Azure subscription permissions
   - Verify resource group exists
   - Ensure quota availability for Container Instances
   - Check if tfplan file exists (common issue)

4. **Tests Fail**:
   - Check if test dependencies are installed
   - Verify test file paths and structure

### Specific Error Solutions

#### "tfplan file not found" Error
This error occurs when Terraform Plan step fails but the pipeline continues to Apply step:

**Solution**:
- Check the Terraform Plan step output for errors
- Verify that the `image_tag` variable is properly set
- Ensure Azure CLI authentication is working
- Check if the infrastructure directory contains all required files

#### "Terraform initialization failed" Error
This happens when Terraform can't initialize properly:

**Solution**:
- Verify that main.tf exists in the infrastructure directory
- Check Azure CLI authentication: `az account show`
- Ensure service principal has proper permissions
- Check if there are any syntax errors in Terraform files

#### "Could not get health_check_url output" Error
This occurs when Terraform state is not properly created:

**Solution**:
- Verify that Terraform Apply completed successfully
- Check if terraform.tfstate file exists
- Ensure all resources were created properly
- Verify that outputs.tf contains the health_check_url output

#### Azure CLI Authentication Issues
If you see authentication errors:

**Solution**:
- Verify the Azure Resource Manager service connection is properly configured
- Check that the service principal has Contributor rights to the subscription
- Ensure the subscription ID is correct
- Test the service connection in Azure DevOps

### Verification Steps

After pipeline completion:
1. Check ACR for the new Docker image
2. Verify Container Instance is running in Azure Portal
3. Test the health check endpoint: `http://[fqdn]:5000/health`

## Security Considerations

- Service connections use managed identities where possible
- Terraform state is stored locally (consider remote backend for production)
- Docker images are stored in private ACR
- Container instances use managed identity for ACR authentication

## Next Steps

1. Consider implementing:
   - Remote Terraform backend (Azure Storage)
   - Approval gates for production deployments
   - Multi-environment support (dev/staging/prod)
   - Automated testing of deployed endpoints
   - Monitoring and alerting
