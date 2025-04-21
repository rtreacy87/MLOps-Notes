#!/bin/bash
# Script to configure Azure CLI for MLOps

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
