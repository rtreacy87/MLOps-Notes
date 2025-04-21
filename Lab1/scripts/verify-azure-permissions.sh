#!/bin/bash
# Script to verify Azure permissions

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
