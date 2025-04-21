# Linking DevOps Board to Azure Account

This guide covers how to integrate your Azure DevOps board with your Azure account using scripts and automation.

## Prerequisites

- [Azure DevOps board set up](06-devops-board-setup.md)
- [Azure account set up](07-azure-account-setup.md)
- Azure CLI and Azure DevOps CLI extension installed

## Understanding the Integration

Integrating Azure DevOps with your Azure account provides several benefits:

1. **Service Connections**: Connect your DevOps project to Azure subscriptions
2. **Work Item Integration**: Link work items to Azure resources
3. **Pipeline Integration**: Deploy to Azure resources from CI/CD pipelines
4. **Dashboard Integration**: Monitor Azure resources from DevOps dashboards

## Setting Up Service Connections

Service connections allow your DevOps pipelines to access your Azure resources.

### Creating a Service Connection with Azure CLI

```bash
# Log in to Azure
az login

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create a service principal for the connection
SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --name "devops-service-connection" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID --output json)

# Extract values from the service principal
APP_ID=$(echo $SERVICE_PRINCIPAL | jq -r '.appId')
PASSWORD=$(echo $SERVICE_PRINCIPAL | jq -r '.password')
TENANT_ID=$(echo $SERVICE_PRINCIPAL | jq -r '.tenant')

# Create the service connection in Azure DevOps
az devops service-endpoint azurerm create \
  --name "Azure Connection" \
  --azure-rm-service-principal-id "$APP_ID" \
  --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
  --azure-rm-subscription-name "$(az account show --query name -o tsv)" \
  --azure-rm-tenant-id "$TENANT_ID" \
  --azure-rm-service-principal-key "$PASSWORD"
```

### Creating a Script to Automate Service Connection Setup

```bash
#!/bin/bash
# Save this as setup-service-connection.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-service-connection.sh project_name [connection_name]"
    exit 1
fi

PROJECT_NAME=$1
CONNECTION_NAME=${2:-"Azure Connection"}

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# Check if Azure DevOps CLI is configured
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -z "$DEVOPS_ORG" ]; then
    echo "Azure DevOps CLI not configured. Please run 'az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION'"
    exit 1
fi

# Set default project
az devops configure --defaults project="$PROJECT_NAME"

# Get subscription details
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo "Creating service connection from project '$PROJECT_NAME' to Azure subscription '$SUBSCRIPTION_NAME'..."

# Create a service principal for the connection
echo "Creating service principal..."
SERVICE_PRINCIPAL=$(az ad sp create-for-rbac \
    --name "devops-$PROJECT_NAME-$(date +%Y%m%d)" \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID \
    --output json)

# Extract values from the service principal
APP_ID=$(echo $SERVICE_PRINCIPAL | jq -r '.appId')
PASSWORD=$(echo $SERVICE_PRINCIPAL | jq -r '.password')
TENANT_ID=$(echo $SERVICE_PRINCIPAL | jq -r '.tenant')

# Store credentials in pass if available
if command -v pass &> /dev/null; then
    echo "Storing service principal credentials in password manager..."
    echo "$SERVICE_PRINCIPAL" | pass insert -e "azure/devops-integration/$PROJECT_NAME"
fi

# Create the service connection in Azure DevOps
echo "Creating service connection in Azure DevOps..."
az devops service-endpoint azurerm create \
    --name "$CONNECTION_NAME" \
    --azure-rm-service-principal-id "$APP_ID" \
    --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
    --azure-rm-subscription-name "$SUBSCRIPTION_NAME" \
    --azure-rm-tenant-id "$TENANT_ID" \
    --azure-rm-service-principal-key "$PASSWORD"

# Get the service connection ID
SERVICE_CONNECTION_ID=$(az devops service-endpoint list --query "[?name=='$CONNECTION_NAME'].id" -o tsv)

# Grant access permission to all pipelines
echo "Granting access permission to all pipelines..."
az devops service-endpoint update \
    --id "$SERVICE_CONNECTION_ID" \
    --enable-for-all true

echo "Service connection setup complete!"
echo "Connection Name: $CONNECTION_NAME"
echo "Service Principal: devops-$PROJECT_NAME-$(date +%Y%m%d)"
```

Make the script executable and run it:

```bash
chmod +x setup-service-connection.sh
./setup-service-connection.sh "MLOps-Project"
```

## Setting Up Work Item Integration

### Creating a Script to Link Work Items to Azure Resources

```bash
#!/bin/bash
# Save this as link-workitem-to-resource.sh

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    echo "Please provide work item ID, resource group, and resource name"
    echo "Usage: ./link-workitem-to-resource.sh work_item_id resource_group resource_name [resource_type]"
    exit 1
fi

WORK_ITEM_ID=$1
RESOURCE_GROUP=$2
RESOURCE_NAME=$3
RESOURCE_TYPE=${4:-"Microsoft.Resources/deployments"}

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# Check if Azure DevOps CLI is configured
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -z "$DEVOPS_ORG" ]; then
    echo "Azure DevOps CLI not configured. Please run 'az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION'"
    exit 1
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get resource ID
RESOURCE_ID=$(az resource show --resource-group "$RESOURCE_GROUP" --name "$RESOURCE_NAME" --resource-type "$RESOURCE_TYPE" --query id -o tsv 2>/dev/null)

if [ -z "$RESOURCE_ID" ]; then
    echo "Resource not found. Please check the resource group, name, and type."
    exit 1
fi

# Create a link between the work item and the Azure resource
echo "Linking work item $WORK_ITEM_ID to Azure resource $RESOURCE_NAME..."

# Create a temporary JSON file for the link
cat > temp_link.json << EOF
{
  "op": "add",
  "path": "/relations/-",
  "value": {
    "rel": "Hyperlink",
    "url": "https://portal.azure.com/#resource$RESOURCE_ID",
    "attributes": {
      "comment": "Link to Azure resource: $RESOURCE_NAME"
    }
  }
}
EOF

# Add the link to the work item
az boards work-item update --id "$WORK_ITEM_ID" --path-patch "$(cat temp_link.json)"

# Clean up
rm temp_link.json

echo "Work item $WORK_ITEM_ID linked to Azure resource $RESOURCE_NAME"
```

Make the script executable and run it:

```bash
chmod +x link-workitem-to-resource.sh
./link-workitem-to-resource.sh 42 "my-resource-group" "my-storage-account" "Microsoft.Storage/storageAccounts"
```

## Setting Up Pipeline Integration

### Creating a YAML Pipeline for Azure Deployment

Create a YAML pipeline file that uses the service connection to deploy to Azure:

```yaml
# Save this as azure-deploy-pipeline.yml
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
```

### Creating a Script to Set Up a Complete CI/CD Pipeline

```bash
#!/bin/bash
# Save this as setup-azure-pipeline.sh

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
```

Make the script executable and run it:

```bash
chmod +x setup-azure-pipeline.sh
./setup-azure-pipeline.sh "MLOps-Project" "infrastructure"
```

## Setting Up Dashboard Integration

### Creating a Dashboard with Azure Resource Widgets

```bash
#!/bin/bash
# Save this as setup-azure-dashboard.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-azure-dashboard.sh project_name"
    exit 1
fi

PROJECT_NAME=$1

# Check if Azure DevOps CLI is configured
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -z "$DEVOPS_ORG" ]; then
    echo "Azure DevOps CLI not configured. Please run 'az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION'"
    exit 1
fi

# Set default project
az devops configure --defaults project="$PROJECT_NAME"

# Create a dashboard
echo "Creating dashboard..."
DASHBOARD_ID=$(az boards dashboard create --name "Azure Resources" --description "Dashboard for Azure resources" --query id -o tsv)

echo "Dashboard created with ID: $DASHBOARD_ID"
echo "You can now add Azure resource widgets to this dashboard through the Azure DevOps web interface."
```

Make the script executable and run it:

```bash
chmod +x setup-azure-dashboard.sh
./setup-azure-dashboard.sh "MLOps-Project"
```

## Next Steps

After linking your DevOps board to your Azure account, proceed to [setting up Azure resources](09-azure-resource-setup.md) for your ML development environment.
