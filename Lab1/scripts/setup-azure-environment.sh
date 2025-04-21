#!/bin/bash
# Script to set up a complete Azure environment for MLOps

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-azure-environment.sh project_name [location]"
    exit 1
fi

PROJECT_NAME=$1
LOCATION=${2:-eastus}
RESOURCE_GROUP="${PROJECT_NAME}-rg"

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "Setting up Azure environment for project '$PROJECT_NAME' in subscription '$SUBSCRIPTION'..."

# Create resource group
echo "Creating resource group '$RESOURCE_GROUP'..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create storage account (name must be globally unique and lowercase)
STORAGE_ACCOUNT="${PROJECT_NAME}storage"
STORAGE_ACCOUNT=$(echo "$STORAGE_ACCOUNT" | tr '[:upper:]' '[:lower:]' | tr -d '-')
echo "Creating storage account '$STORAGE_ACCOUNT'..."
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2

# Create storage containers
echo "Creating storage containers..."
STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query "[0].value" -o tsv)

for CONTAINER in "data" "models" "notebooks" "outputs"; do
    echo "Creating container '$CONTAINER'..."
    az storage container create \
        --name "$CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$STORAGE_KEY"
done

# Create Key Vault
KEYVAULT_NAME="${PROJECT_NAME}-kv"
echo "Creating Key Vault '$KEYVAULT_NAME'..."
az keyvault create \
    --name "$KEYVAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

# Create Application Insights
APPINSIGHTS_NAME="${PROJECT_NAME}-appinsights"
echo "Creating Application Insights '$APPINSIGHTS_NAME'..."
az monitor app-insights component create \
    --app "$APPINSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

# Create Azure ML workspace (if ml extension is installed)
if az extension show -n ml &>/dev/null; then
    ML_WORKSPACE="${PROJECT_NAME}-ml"
    echo "Creating Azure ML workspace '$ML_WORKSPACE'..."
    az ml workspace create \
        --name "$ML_WORKSPACE" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --storage-account "$STORAGE_ACCOUNT" \
        --key-vault "$KEYVAULT_NAME" \
        --application-insights "$APPINSIGHTS_NAME"
else
    echo "Azure ML CLI extension not installed. Skipping ML workspace creation."
fi

# Save environment information
echo "Saving environment information..."
cat > "${PROJECT_NAME}-azure-env.json" << EOF
{
    "project": "$PROJECT_NAME",
    "subscription": "$(az account show --query id -o tsv)",
    "resourceGroup": "$RESOURCE_GROUP",
    "location": "$LOCATION",
    "storageAccount": "$STORAGE_ACCOUNT",
    "keyVault": "$KEYVAULT_NAME",
    "appInsights": "$APPINSIGHTS_NAME",
    "mlWorkspace": "$ML_WORKSPACE"
}
EOF

echo "Azure environment setup complete!"
echo "Environment information saved to ${PROJECT_NAME}-azure-env.json"
