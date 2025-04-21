#!/bin/bash
# Script to tear down MLOps environment

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./teardown-mlops-environment.sh project_name"
    exit 1
fi

PROJECT_NAME=$1
ENV_FILE="${PROJECT_NAME}-mlops-env.json"

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file '$ENV_FILE' not found."
    
    # Ask for resource group name
    read -p "Enter the resource group name to delete: " RESOURCE_GROUP
else
    # Extract resource group from environment file
    RESOURCE_GROUP=$(jq -r '.resourceGroup' "$ENV_FILE")
    echo "Found resource group '$RESOURCE_GROUP' in environment file."
fi

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# Confirm deletion
echo "WARNING: This will delete the resource group '$RESOURCE_GROUP' and ALL resources within it."
echo "This action CANNOT be undone."
read -p "Are you sure you want to proceed? (y/n): " CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Teardown cancelled."
    exit 0
fi

# Delete the resource group
echo "Deleting resource group '$RESOURCE_GROUP'..."
az group delete --name "$RESOURCE_GROUP" --yes

# Check if Azure DevOps CLI is configured
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -n "$DEVOPS_ORG" ]; then
    # Ask if user wants to delete DevOps project
    read -p "Do you want to delete the Azure DevOps project '$PROJECT_NAME'? (y/n): " DELETE_DEVOPS
    
    if [[ $DELETE_DEVOPS == "y" || $DELETE_DEVOPS == "Y" ]]; then
        echo "Deleting Azure DevOps project '$PROJECT_NAME'..."
        az devops project delete --project "$PROJECT_NAME" --yes
    fi
fi

# Clean up local files
read -p "Do you want to delete local configuration files? (y/n): " DELETE_LOCAL
if [[ $DELETE_LOCAL == "y" || $DELETE_LOCAL == "Y" ]]; then
    echo "Deleting local configuration files..."
    rm -f "${PROJECT_NAME}-mlops-env.json" "${PROJECT_NAME}-config.py" "access-azure-resources.py"
fi

echo "Teardown complete!"
