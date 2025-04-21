#!/bin/bash
# Script to set up a complete MLOps environment using Azure CLI

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
