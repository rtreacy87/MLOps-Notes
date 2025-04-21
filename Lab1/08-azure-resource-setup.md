# Setting Up Azure Resources for ML Development

This guide covers how to set up Azure resources for ML development using infrastructure as code (IaC), focusing on a hybrid setup where data is stored in Azure while model training is done locally.

## Prerequisites

- [Azure account set up](06-azure-account-setup.md)
- [DevOps-Azure integration configured](07-devops-azure-integration.md)
- Azure CLI installed and configured

## Infrastructure as Code Options

There are several options for defining your Azure infrastructure as code:

1. **ARM Templates**: JSON-based templates for Azure resources
2. **Bicep**: Domain-specific language that compiles to ARM templates
3. **Terraform**: Multi-cloud infrastructure as code tool
4. **Azure CLI Scripts**: Scripted approach using Azure CLI commands

This guide will cover all four approaches, allowing you to choose the one that best fits your needs.

## Setting Up Resource Groups

A resource group is a container that holds related resources for an Azure solution.

### Using Azure CLI

```bash
# Create a resource group
az group create --name mlops-resources --location eastus
```

### Using ARM Template

```json
// Save as resource-group.json
{
  "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "rgName": {
      "type": "string",
      "defaultValue": "mlops-resources"
    },
    "rgLocation": {
      "type": "string",
      "defaultValue": "eastus"
    }
  },
  "resources": [
    {
      "type": "Microsoft.Resources/resourceGroups",
      "apiVersion": "2021-04-01",
      "name": "[parameters('rgName')]",
      "location": "[parameters('rgLocation')]",
      "properties": {}
    }
  ],
  "outputs": {
    "resourceGroupName": {
      "type": "string",
      "value": "[parameters('rgName')]"
    }
  }
}
```

Deploy the ARM template:

```bash
az deployment sub create \
  --name rgDeployment \
  --location eastus \
  --template-file resource-group.json
```

### Using Bicep

```bicep
// Save as resource-group.bicep
targetScope = 'subscription'

param rgName string = 'mlops-resources'
param rgLocation string = 'eastus'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: rgLocation
}

output resourceGroupName string = resourceGroup.name
```

Deploy the Bicep file:

```bash
az deployment sub create \
  --name rgDeployment \
  --location eastus \
  --template-file resource-group.bicep
```

### Using Terraform

```hcl
# Save as main.tf
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "mlops" {
  name     = "mlops-resources"
  location = "eastus"
}

output "resource_group_name" {
  value = azurerm_resource_group.mlops.name
}
```

Deploy with Terraform:

```bash
terraform init
terraform apply
```

## Setting Up Storage Resources

### Storage Account with Azure CLI

```bash
# Create a storage account
az storage account create \
  --name mlopsstorage \
  --resource-group mlops-resources \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Create containers
az storage container create \
  --name data \
  --account-name mlopsstorage

az storage container create \
  --name models \
  --account-name mlopsstorage

az storage container create \
  --name outputs \
  --account-name mlopsstorage
```

### Storage Account with ARM Template

```json
// Save as storage.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "type": "string",
      "defaultValue": "mlopsstorage"
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]"
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
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "apiVersion": "2021-04-01",
      "name": "[concat(parameters('storageAccountName'), '/default/data')]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
      ],
      "properties": {
        "publicAccess": "None"
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "apiVersion": "2021-04-01",
      "name": "[concat(parameters('storageAccountName'), '/default/models')]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
      ],
      "properties": {
        "publicAccess": "None"
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "apiVersion": "2021-04-01",
      "name": "[concat(parameters('storageAccountName'), '/default/outputs')]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
      ],
      "properties": {
        "publicAccess": "None"
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
```

Deploy the ARM template:

```bash
az deployment group create \
  --name storageDeployment \
  --resource-group mlops-resources \
  --template-file storage.json
```

### Storage Account with Bicep

```bicep
// Save as storage.bicep
param storageAccountName string = 'mlopsstorage'
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource dataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccountName}/default/data'
  dependsOn: [
    storageAccount
  ]
  properties: {
    publicAccess: 'None'
  }
}

resource modelsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccountName}/default/models'
  dependsOn: [
    storageAccount
  ]
  properties: {
    publicAccess: 'None'
  }
}

resource outputsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccountName}/default/outputs'
  dependsOn: [
    storageAccount
  ]
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storageAccount.name
```

Deploy the Bicep file:

```bash
az deployment group create \
  --name storageDeployment \
  --resource-group mlops-resources \
  --template-file storage.bicep
```

### Storage Account with Terraform

```hcl
# Save as storage.tf
resource "azurerm_storage_account" "mlops" {
  name                     = "mlopsstorage"
  resource_group_name      = azurerm_resource_group.mlops.name
  location                 = azurerm_resource_group.mlops.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.mlops.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "models" {
  name                  = "models"
  storage_account_name  = azurerm_storage_account.mlops.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "outputs" {
  name                  = "outputs"
  storage_account_name  = azurerm_storage_account.mlops.name
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.mlops.name
}
```

## Setting Up Key Vault

Key Vault is used to securely store secrets, keys, and certificates.

### Key Vault with Azure CLI

```bash
# Create a Key Vault
az keyvault create \
  --name mlops-keyvault \
  --resource-group mlops-resources \
  --location eastus

# Add a secret
az keyvault secret set \
  --vault-name mlops-keyvault \
  --name "StorageConnectionString" \
  --value "$(az storage account show-connection-string --name mlopsstorage --resource-group mlops-resources --query connectionString -o tsv)"
```

### Key Vault with ARM Template

```json
// Save as keyvault.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "keyVaultName": {
      "type": "string",
      "defaultValue": "mlops-keyvault"
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]"
    },
    "tenantId": {
      "type": "string",
      "defaultValue": "[subscription().tenantId]"
    },
    "objectId": {
      "type": "string",
      "metadata": {
        "description": "Object ID of the current user"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.KeyVault/vaults",
      "apiVersion": "2021-04-01-preview",
      "name": "[parameters('keyVaultName')]",
      "location": "[parameters('location')]",
      "properties": {
        "enabledForDeployment": true,
        "enabledForTemplateDeployment": true,
        "enabledForDiskEncryption": true,
        "tenantId": "[parameters('tenantId')]",
        "accessPolicies": [
          {
            "tenantId": "[parameters('tenantId')]",
            "objectId": "[parameters('objectId')]",
            "permissions": {
              "keys": ["all"],
              "secrets": ["all"],
              "certificates": ["all"]
            }
          }
        ],
        "sku": {
          "name": "standard",
          "family": "A"
        }
      }
    }
  ],
  "outputs": {
    "keyVaultName": {
      "type": "string",
      "value": "[parameters('keyVaultName')]"
    }
  }
}
```

Deploy the ARM template:

```bash
# Get your object ID
OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

az deployment group create \
  --name keyvaultDeployment \
  --resource-group mlops-resources \
  --template-file keyvault.json \
  --parameters objectId=$OBJECT_ID
```

## Creating a Complete MLOps Environment

Let's create a script that sets up a complete MLOps environment using your preferred IaC approach.

### Using Azure CLI Script

```bash
#!/bin/bash
# Save this as setup-mlops-environment.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-mlops-environment.sh project_name [location]"
    exit 1
fi

PROJECT_NAME=$1
LOCATION=${2:-eastus}
RESOURCE_GROUP="${PROJECT_NAME}-rg"
STORAGE_ACCOUNT="${PROJECT_NAME}storage"
STORAGE_ACCOUNT=$(echo "$STORAGE_ACCOUNT" | tr '[:upper:]' '[:lower:]' | tr -d '-')
KEYVAULT_NAME="${PROJECT_NAME}-kv"
APPINSIGHTS_NAME="${PROJECT_NAME}-appinsights"

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "Setting up MLOps environment for project '$PROJECT_NAME' in subscription '$SUBSCRIPTION'..."

# Create resource group
echo "Creating resource group '$RESOURCE_GROUP'..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create storage account
echo "Creating storage account '$STORAGE_ACCOUNT'..."
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query "[0].value" -o tsv)

# Create storage containers
echo "Creating storage containers..."
for CONTAINER in "data" "models" "notebooks" "outputs"; do
    echo "Creating container '$CONTAINER'..."
    az storage container create \
        --name "$CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$STORAGE_KEY"
done

# Create Key Vault
echo "Creating Key Vault '$KEYVAULT_NAME'..."
az keyvault create \
    --name "$KEYVAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

# Store storage connection string in Key Vault
echo "Storing storage connection string in Key Vault..."
STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query connectionString -o tsv)
az keyvault secret set \
    --vault-name "$KEYVAULT_NAME" \
    --name "StorageConnectionString" \
    --value "$STORAGE_CONNECTION_STRING"

# Create Application Insights
echo "Creating Application Insights '$APPINSIGHTS_NAME'..."
az monitor app-insights component create \
    --app "$APPINSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

# Save environment information
echo "Saving environment information..."
cat > "${PROJECT_NAME}-mlops-env.json" << EOF
{
    "project": "$PROJECT_NAME",
    "subscription": "$(az account show --query id -o tsv)",
    "resourceGroup": "$RESOURCE_GROUP",
    "location": "$LOCATION",
    "storageAccount": "$STORAGE_ACCOUNT",
    "storageKey": "$STORAGE_KEY",
    "keyVault": "$KEYVAULT_NAME",
    "appInsights": "$APPINSIGHTS_NAME"
}
EOF

# Create a local configuration file for Python scripts
echo "Creating local configuration file..."
cat > "${PROJECT_NAME}-config.py" << EOF
# Azure Configuration for $PROJECT_NAME

# Resource information
RESOURCE_GROUP = "$RESOURCE_GROUP"
STORAGE_ACCOUNT = "$STORAGE_ACCOUNT"
KEYVAULT_NAME = "$KEYVAULT_NAME"

# Connection strings
STORAGE_CONNECTION_STRING = "$STORAGE_CONNECTION_STRING"

# Container names
DATA_CONTAINER = "data"
MODELS_CONTAINER = "models"
OUTPUTS_CONTAINER = "outputs"

# Function to get a secret from Key Vault
def get_secret(secret_name):
    from azure.identity import DefaultAzureCredential
    from azure.keyvault.secrets import SecretClient
    
    credential = DefaultAzureCredential()
    secret_client = SecretClient(vault_url=f"https://{KEYVAULT_NAME}.vault.azure.net/", credential=credential)
    return secret_client.get_secret(secret_name).value
EOF

echo "MLOps environment setup complete!"
echo "Environment information saved to ${PROJECT_NAME}-mlops-env.json"
echo "Python configuration saved to ${PROJECT_NAME}-config.py"
```

Make the script executable and run it:

```bash
chmod +x setup-mlops-environment.sh
./setup-mlops-environment.sh my-mlops-project eastus
```

## Setting Up Local Environment for Azure Access

Now let's create a script to set up your local environment to access the Azure resources:

```bash
#!/bin/bash
# Save this as setup-local-azure-access.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-local-azure-access.sh project_name"
    exit 1
fi

PROJECT_NAME=$1
ENV_FILE="${PROJECT_NAME}-mlops-env.json"

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file '$ENV_FILE' not found. Please run setup-mlops-environment.sh first."
    exit 1
fi

# Extract values from environment file
RESOURCE_GROUP=$(jq -r '.resourceGroup' "$ENV_FILE")
STORAGE_ACCOUNT=$(jq -r '.storageAccount' "$ENV_FILE")
KEYVAULT_NAME=$(jq -r '.keyVault' "$ENV_FILE")

# Install required Python packages
echo "Installing required Python packages..."
pip install azure-storage-blob azure-identity azure-keyvault-secrets

# Create a Python script for accessing Azure resources
echo "Creating Python script for accessing Azure resources..."
cat > "access-azure-resources.py" << EOF
#!/usr/bin/env python3
"""
Script to access Azure resources from local environment.
"""

import os
import sys
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.keyvault.secrets import SecretClient

# Load configuration
sys.path.append('.')
import ${PROJECT_NAME}-config as config

def list_blobs(container_name):
    """List all blobs in a container."""
    try:
        # Create a blob service client
        blob_service_client = BlobServiceClient.from_connection_string(config.STORAGE_CONNECTION_STRING)
        
        # Get a container client
        container_client = blob_service_client.get_container_client(container_name)
        
        # List blobs
        print(f"Blobs in container '{container_name}':")
        for blob in container_client.list_blobs():
            print(f"  {blob.name}")
    except Exception as e:
        print(f"Error listing blobs: {e}")

def upload_blob(container_name, local_file_path, blob_name=None):
    """Upload a file to a container."""
    if blob_name is None:
        blob_name = os.path.basename(local_file_path)
        
    try:
        # Create a blob service client
        blob_service_client = BlobServiceClient.from_connection_string(config.STORAGE_CONNECTION_STRING)
        
        # Get a blob client
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        
        # Upload the file
        with open(local_file_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)
            
        print(f"Uploaded {local_file_path} to {container_name}/{blob_name}")
    except Exception as e:
        print(f"Error uploading blob: {e}")

def download_blob(container_name, blob_name, local_file_path):
    """Download a blob to a local file."""
    try:
        # Create a blob service client
        blob_service_client = BlobServiceClient.from_connection_string(config.STORAGE_CONNECTION_STRING)
        
        # Get a blob client
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        
        # Download the blob
        with open(local_file_path, "wb") as download_file:
            download_file.write(blob_client.download_blob().readall())
            
        print(f"Downloaded {container_name}/{blob_name} to {local_file_path}")
    except Exception as e:
        print(f"Error downloading blob: {e}")

def get_secret(secret_name):
    """Get a secret from Key Vault."""
    try:
        # Create a credential
        credential = DefaultAzureCredential()
        
        # Create a secret client
        secret_client = SecretClient(vault_url=f"https://{config.KEYVAULT_NAME}.vault.azure.net/", credential=credential)
        
        # Get the secret
        secret = secret_client.get_secret(secret_name)
        
        print(f"Retrieved secret '{secret_name}'")
        return secret.value
    except Exception as e:
        print(f"Error getting secret: {e}")
        return None

if __name__ == "__main__":
    # Example usage
    if len(sys.argv) < 2:
        print("Usage: python access-azure-resources.py [list|upload|download|secret]")
        sys.exit(1)
        
    command = sys.argv[1]
    
    if command == "list":
        if len(sys.argv) < 3:
            print("Usage: python access-azure-resources.py list <container_name>")
            sys.exit(1)
        list_blobs(sys.argv[2])
        
    elif command == "upload":
        if len(sys.argv) < 4:
            print("Usage: python access-azure-resources.py upload <container_name> <local_file_path> [blob_name]")
            sys.exit(1)
        blob_name = sys.argv[4] if len(sys.argv) > 4 else None
        upload_blob(sys.argv[2], sys.argv[3], blob_name)
        
    elif command == "download":
        if len(sys.argv) < 5:
            print("Usage: python access-azure-resources.py download <container_name> <blob_name> <local_file_path>")
            sys.exit(1)
        download_blob(sys.argv[2], sys.argv[3], sys.argv[4])
        
    elif command == "secret":
        if len(sys.argv) < 3:
            print("Usage: python access-azure-resources.py secret <secret_name>")
            sys.exit(1)
        secret_value = get_secret(sys.argv[2])
        if secret_value:
            print(f"Secret value: {secret_value}")
    else:
        print(f"Unknown command: {command}")
        print("Usage: python access-azure-resources.py [list|upload|download|secret]")
EOF

chmod +x "access-azure-resources.py"

echo "Local environment setup complete!"
echo "You can now use access-azure-resources.py to interact with your Azure resources."
echo "Examples:"
echo "  ./access-azure-resources.py list data"
echo "  ./access-azure-resources.py upload data ./mydata.csv"
echo "  ./access-azure-resources.py download models model.pkl ./model.pkl"
echo "  ./access-azure-resources.py secret StorageConnectionString"
```

Make the script executable and run it:

```bash
chmod +x setup-local-azure-access.sh
./setup-local-azure-access.sh my-mlops-project
```

## Next Steps

After setting up your Azure resources, proceed to [learning how to tear down your environment](09-teardown-guide.md) when you no longer need it.
