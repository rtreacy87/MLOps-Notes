#!/bin/bash
# Script for complete MLOps environment teardown

echo "===== COMPLETE MLOPS ENVIRONMENT TEARDOWN ====="
echo "This script will tear down all components of your MLOps environment."
echo "WARNING: This will delete resources and cannot be undone."
echo ""

# Check if project name is provided
if [ $# -eq 0 ]; then
    read -p "Enter your project name: " PROJECT_NAME
else
    PROJECT_NAME=$1
fi

echo "Project name: $PROJECT_NAME"
echo ""

# 1. Azure Resources
echo "===== STEP 1: Azure Resources ====="
ENV_FILE="${PROJECT_NAME}-mlops-env.json"

if [ -f "$ENV_FILE" ]; then
    RESOURCE_GROUP=$(jq -r '.resourceGroup' "$ENV_FILE")
    echo "Found resource group '$RESOURCE_GROUP' in environment file."
else
    read -p "Environment file not found. Enter the resource group name to delete: " RESOURCE_GROUP
fi

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

read -p "Delete Azure resource group '$RESOURCE_GROUP'? (y/n): " DELETE_RG
if [[ $DELETE_RG == "y" || $DELETE_RG == "Y" ]]; then
    echo "Deleting resource group '$RESOURCE_GROUP'..."
    az group delete --name "$RESOURCE_GROUP" --yes
    echo "Resource group deleted."
else
    echo "Skipping resource group deletion."
fi
echo ""

# 2. Azure DevOps Resources
echo "===== STEP 2: Azure DevOps Resources ====="
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -n "$DEVOPS_ORG" ]; then
    echo "Found Azure DevOps organization: $DEVOPS_ORG"
    
    read -p "Delete Azure DevOps project '$PROJECT_NAME'? (y/n): " DELETE_DEVOPS
    if [[ $DELETE_DEVOPS == "y" || $DELETE_DEVOPS == "Y" ]]; then
        echo "Deleting Azure DevOps project '$PROJECT_NAME'..."
        az devops project delete --project "$PROJECT_NAME" --yes
        echo "DevOps project deleted."
    else
        echo "Skipping DevOps project deletion."
    fi
else
    echo "Azure DevOps CLI not configured. Skipping DevOps resources."
fi
echo ""

# 3. Local Configuration Files
echo "===== STEP 3: Local Configuration Files ====="
CONFIG_FILES=(
    "${PROJECT_NAME}-mlops-env.json"
    "${PROJECT_NAME}-config.py"
    "access-azure-resources.py"
    "setup-mlops-environment.sh"
    "setup-local-azure-access.sh"
)

echo "The following local configuration files will be deleted:"
for FILE in "${CONFIG_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo "  - $FILE"
    fi
done

read -p "Delete these local configuration files? (y/n): " DELETE_LOCAL
if [[ $DELETE_LOCAL == "y" || $DELETE_LOCAL == "Y" ]]; then
    echo "Deleting local configuration files..."
    for FILE in "${CONFIG_FILES[@]}"; do
        if [ -f "$FILE" ]; then
            rm -f "$FILE"
            echo "  - Deleted $FILE"
        fi
    done
    echo "Local configuration files deleted."
else
    echo "Skipping local configuration files deletion."
fi
echo ""

# 4. Service Principal Cleanup
echo "===== STEP 4: Service Principal Cleanup ====="
if command -v pass &> /dev/null; then
    if pass show "azure/service-principal/app-id" &> /dev/null; then
        echo "Found service principal credentials in password store."
        
        read -p "Delete service principal? (y/n): " DELETE_SP
        if [[ $DELETE_SP == "y" || $DELETE_SP == "Y" ]]; then
            # Get the app ID
            APP_ID=$(pass show "azure/service-principal/app-id")
            
            # Delete the service principal
            echo "Deleting service principal..."
            az ad sp delete --id "$APP_ID"
            
            # Remove from password store
            pass rm "azure/service-principal/app-id"
            pass rm "azure/service-principal/password"
            pass rm "azure/service-principal/tenant"
            pass rm "azure/service-principal/subscription-id"
            
            echo "Service principal deleted."
        else
            echo "Skipping service principal deletion."
        fi
    else
        echo "No service principal credentials found in password store."
    fi
else
    echo "pass not installed. Skipping service principal cleanup."
fi
echo ""

echo "===== TEARDOWN COMPLETE ====="
echo "Your MLOps environment has been torn down."
echo "Note: If you installed VS Code or WSL, those installations remain on your system."
echo "To uninstall them, use Windows Add/Remove Programs or WSL commands."
