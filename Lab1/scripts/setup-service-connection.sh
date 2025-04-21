#!/bin/bash
# Script to set up a service connection between Azure DevOps and Azure

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
