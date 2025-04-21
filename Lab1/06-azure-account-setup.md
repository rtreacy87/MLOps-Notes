# Setting Up an Azure Account

This guide covers how to set up an Azure account and configure it for MLOps using automation and infrastructure as code.

## Prerequisites

- [WSL with Ubuntu installed](02-wsl-setup.md)
- [Azure CLI installed](05-devops-board-setup.md#installing-azure-cli)
- Microsoft account (personal) or work/school account

## Creating an Azure Account

### Step 1: Sign Up for Azure

1. Visit [https://azure.microsoft.com/free](https://azure.microsoft.com/free)
2. Click "Start free" or "Try Azure for free"
3. Sign in with your Microsoft account or create a new one
4. Complete the registration process, which requires:
   - Identity verification by phone
   - Credit card information (for identity verification, you won't be charged unless you explicitly upgrade)
   - Agreement to terms and conditions

### Step 2: Verify Your Account Setup

After creating your account, verify it's working correctly:

```bash
# Log in to Azure
az login

# List your subscriptions
az account list --output table
```

You should see your subscription listed with a status of "Enabled".

## Setting Up Azure CLI Configuration

Create a script to configure Azure CLI for your environment:

```bash
#!/bin/bash
# Save this as configure-azure-cli.sh

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# List available subscriptions
echo "Available subscriptions:"
az account list --output table

# Prompt for subscription selection
read -p "Enter the subscription ID to use: " SUBSCRIPTION_ID

# Set the active subscription
echo "Setting active subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Verify the selected subscription
echo "Current subscription:"
az account show --output table

# Create a service principal for automation
echo "Creating a service principal for automation..."
SP_NAME="mlops-automation-$(date +%Y%m%d)"
SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" --role Contributor --output json)

# Save the service principal credentials securely
echo "Saving service principal credentials..."
echo "$SP_OUTPUT" > sp-credentials.json
chmod 600 sp-credentials.json

# Extract credentials
APP_ID=$(echo "$SP_OUTPUT" | grep appId | cut -d '"' -f 4)
PASSWORD=$(echo "$SP_OUTPUT" | grep password | cut -d '"' -f 4)
TENANT=$(echo "$SP_OUTPUT" | grep tenant | cut -d '"' -f 4)

# Store credentials in pass if available
if command -v pass &> /dev/null; then
    echo "Storing credentials in password manager..."
    echo "$APP_ID" | pass insert -e "azure/service-principal/app-id"
    echo "$PASSWORD" | pass insert -e "azure/service-principal/password"
    echo "$TENANT" | pass insert -e "azure/service-principal/tenant"
    echo "$SUBSCRIPTION_ID" | pass insert -e "azure/service-principal/subscription-id"
    
    # Remove the JSON file after storing in pass
    rm sp-credentials.json
    echo "Credentials stored in password manager. JSON file removed."
else
    echo "pass not found. Credentials saved to sp-credentials.json"
    echo "IMPORTANT: Keep this file secure and consider moving it to a secure location."
fi

# Set environment variables for current session
export AZURE_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export AZURE_TENANT_ID="$TENANT"
export AZURE_CLIENT_ID="$APP_ID"
export AZURE_CLIENT_SECRET="$PASSWORD"

# Add environment variables to .bashrc
echo "Adding environment variables to .bashrc..."
cat >> ~/.bashrc << EOF

# Azure service principal credentials
export AZURE_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export AZURE_TENANT_ID="$TENANT"
export AZURE_CLIENT_ID="$APP_ID"
export AZURE_CLIENT_SECRET="$PASSWORD"
EOF

echo "Azure CLI configuration complete!"
echo "Service principal created: $SP_NAME"
echo "Environment variables have been set for the current session and added to .bashrc"
```

Make the script executable and run it:

```bash
chmod +x configure-azure-cli.sh
./configure-azure-cli.sh
```

## Setting Up Azure CLI Defaults

Configure default values for Azure CLI to simplify commands:

```bash
# Set default location
az configure --defaults location=eastus

# Set default resource group (if you have one)
az configure --defaults group=myResourceGroup
```

## Installing Azure ML CLI Extension

If you plan to use Azure Machine Learning, install the ML extension:

```bash
# Install the Azure ML CLI extension
az extension add -n ml

# Verify installation
az ml -h
```

## Creating a Script to Verify Azure Permissions

Create a script to verify that your account has the necessary permissions:

```bash
#!/bin/bash
# Save this as verify-azure-permissions.sh

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "Checking permissions for subscription: $SUBSCRIPTION"

# Check resource group creation permission
echo "Checking resource group creation permission..."
TEMP_RG="permission-test-$(date +%s)"
RG_RESULT=$(az group create --name "$TEMP_RG" --location eastus 2>&1)
if [ $? -eq 0 ]; then
    echo "✅ Can create resource groups"
    # Clean up the test resource group
    az group delete --name "$TEMP_RG" --yes --no-wait
else
    echo "❌ Cannot create resource groups: $RG_RESULT"
fi

# Check storage account permissions
echo "Checking storage account permissions..."
if az storage account list &>/dev/null; then
    echo "✅ Can list storage accounts"
else
    echo "❌ Cannot list storage accounts"
fi

# Check virtual machine permissions
echo "Checking virtual machine permissions..."
if az vm list &>/dev/null; then
    echo "✅ Can list virtual machines"
else
    echo "❌ Cannot list virtual machines"
fi

# Check Azure ML workspace permissions
echo "Checking Azure ML workspace permissions..."
if az extension show -n ml &>/dev/null; then
    if az ml workspace list &>/dev/null; then
        echo "✅ Can list Azure ML workspaces"
    else
        echo "❌ Cannot list Azure ML workspaces"
    fi
else
    echo "⚠️ Azure ML CLI extension not installed. Skipping ML workspace check."
fi

echo "Permission check complete!"
```

Make the script executable and run it:

```bash
chmod +x verify-azure-permissions.sh
./verify-azure-permissions.sh
```

## Setting Up Azure Cloud Shell

Azure Cloud Shell provides a browser-based shell environment with Azure CLI pre-installed:

1. Visit [https://shell.azure.com](https://shell.azure.com)
2. Choose Bash or PowerShell
3. If this is your first time, you'll be prompted to create storage for Cloud Shell

You can also access Cloud Shell from the Azure portal by clicking the Cloud Shell icon in the top navigation bar.

## Creating a Script to Set Up a Complete Azure Environment

```bash
#!/bin/bash
# Save this as setup-azure-environment.sh

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
```

Make the script executable and run it:

```bash
chmod +x setup-azure-environment.sh
./setup-azure-environment.sh my-mlops-project eastus
```

## Next Steps

After setting up your Azure account, proceed to [linking your DevOps board to your Azure account](07-devops-azure-integration.md).
