#!/bin/bash
# Script to set up a complete CI/CD pipeline in Azure DevOps

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-azure-pipeline.sh project_name [repository_name]"
    exit 1
fi

PROJECT_NAME=$1
REPOSITORY_NAME=${2:-"infrastructure"}

# Check if Azure DevOps CLI is configured
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -z "$DEVOPS_ORG" ]; then
    echo "Azure DevOps CLI not configured. Please run 'az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION'"
    exit 1
fi

# Set default project
az devops configure --defaults project="$PROJECT_NAME"

# Check if repository exists
REPO_CHECK=$(az repos show --repository "$REPOSITORY_NAME" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Repository '$REPOSITORY_NAME' not found. Creating it..."
    az repos create --name "$REPOSITORY_NAME"
fi

# Create pipeline YAML file
echo "Creating pipeline YAML file..."
mkdir -p pipeline-files
cat > pipeline-files/azure-deploy-pipeline.yml << 'EOF'
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  resourceGroupName: 'mlops-resources'
  location: 'eastus'

stages:
- stage: Deploy
  displayName: 'Deploy to Azure'
  jobs:
  - job: DeployResources
    displayName: 'Deploy Azure Resources'
    steps:
    - task: AzureCLI@2
      displayName: 'Create Resource Group'
      inputs:
        azureSubscription: 'Azure Connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az group create --name $(resourceGroupName) --location $(location)
          
    - task: AzureCLI@2
      displayName: 'Deploy Storage Account'
      inputs:
        azureSubscription: 'Azure Connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az storage account create \
            --name mlopsdata$RANDOM \
            --resource-group $(resourceGroupName) \
            --location $(location) \
            --sku Standard_LRS
EOF

# Create ARM template for Azure resources
echo "Creating ARM template..."
mkdir -p pipeline-files/templates
cat > pipeline-files/templates/mlops-resources.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "type": "string",
      "metadata": {
        "description": "Name of the storage account"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for all resources"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-04-01",
      "name": "[parameters('storageAccountName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2",
      "properties": {
        "supportsHttpsTrafficOnly": true,
        "minimumTlsVersion": "TLS1_2"
      }
    }
  ],
  "outputs": {
    "storageAccountName": {
      "type": "string",
      "value": "[parameters('storageAccountName')]"
    }
  }
}
EOF

# Create a README file
echo "Creating README file..."
cat > pipeline-files/README.md << 'EOF'
# Azure Infrastructure Deployment

This repository contains infrastructure as code for deploying Azure resources.

## Pipeline

The Azure DevOps pipeline automatically deploys the following resources:
- Resource Group
- Storage Account

## ARM Templates

The `templates` directory contains ARM templates for deploying resources.

## How to Use

1. Clone this repository
2. Modify the templates as needed
3. Push changes to trigger the pipeline
EOF

# Initialize git repository and push files
echo "Initializing git repository and pushing files..."
cd pipeline-files
git init
git add .
git commit -m "Initial commit with pipeline and templates"

# Get the repository URL
REPO_URL=$(az repos show --repository "$REPOSITORY_NAME" --query remoteUrl -o tsv)

# Add remote and push
git remote add origin "$REPO_URL"
git push -u origin --force main

cd ..

# Create the pipeline
echo "Creating pipeline..."
az pipelines create \
    --name "Azure Deployment" \
    --repository "$REPOSITORY_NAME" \
    --branch main \
    --yml-path azure-deploy-pipeline.yml

echo "Pipeline setup complete!"
echo "You can now view and run the pipeline in Azure DevOps."
