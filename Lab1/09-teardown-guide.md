# Tearing Down Your MLOps Environment

This guide covers how to properly tear down all the resources you've set up in this lab, ensuring you don't incur unexpected costs and maintain a clean environment.

## Why Proper Teardown is Important

Properly tearing down your environment is crucial for several reasons:

1. **Cost Management**: Azure resources continue to incur costs until explicitly deleted
2. **Resource Limits**: Azure subscriptions have limits on the number of resources you can create
3. **Security**: Unused resources can pose security risks if not properly maintained
4. **Cleanliness**: Keeping your environment clean makes it easier to manage

## Teardown Checklist

Before running any teardown scripts, make sure you:

1. **Back up important data**: Export any data you want to keep
2. **Document your setup**: If you plan to recreate it later
3. **Check dependencies**: Ensure you're not deleting resources that other systems depend on

## Tearing Down Azure Resources

### Using Azure CLI

The simplest way to tear down all Azure resources is to delete the resource group:

```bash
# Delete a resource group and all its resources
az group delete --name mlops-resources --yes
```

### Creating a Comprehensive Teardown Script

Let's create a script that tears down all the resources we've created:

```bash
#!/bin/bash
# Save this as teardown-mlops-environment.sh

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
```

Make the script executable and run it:

```bash
chmod +x teardown-mlops-environment.sh
./teardown-mlops-environment.sh my-mlops-project
```

## Tearing Down Azure DevOps Resources

If you want to keep your Azure DevOps organization but remove specific resources:

### Delete a DevOps Project

```bash
# Delete a DevOps project
az devops project delete --project "MLOps-Project" --yes
```

### Delete a Service Connection

```bash
# List service connections
az devops service-endpoint list --query "[].{Name:name, Id:id}" -o table

# Delete a service connection
az devops service-endpoint delete --id <service-connection-id> --yes
```

### Delete a Pipeline

```bash
# List pipelines
az pipelines list --query "[].{Name:name, Id:id}" -o table

# Delete a pipeline
az pipelines delete --id <pipeline-id> --yes
```

## Tearing Down Local Environment

### WSL Cleanup

If you want to reset your WSL environment:

```powershell
# List WSL distributions
wsl --list

# Unregister a distribution (removes it completely)
wsl --unregister Ubuntu
```

### VS Code Cleanup

To reset VS Code settings:

```powershell
# Remove VS Code user settings
Remove-Item -Path "$env:APPDATA\Code\User\settings.json" -Force
```

## Creating a Complete Environment Teardown Script

Let's create a comprehensive script that tears down everything:

```bash
#!/bin/bash
# Save this as complete-teardown.sh

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
```

Make the script executable and run it:

```bash
chmod +x complete-teardown.sh
./complete-teardown.sh my-mlops-project
```

## Verifying Teardown

After running the teardown scripts, verify that all resources have been properly deleted:

### Azure Resources

```bash
# Verify resource group is gone
az group show --name mlops-resources
# Should return "Resource group 'mlops-resources' could not be found."
```

### Azure DevOps Resources

```bash
# Verify project is gone
az devops project show --project "MLOps-Project"
# Should return an error
```

### Local Environment

Check that configuration files have been removed:

```bash
ls -la *mlops*
# Should not show any of the configuration files
```

## Best Practices for Future Projects

1. **Use Infrastructure as Code**: Makes it easier to recreate and tear down environments
2. **Document Your Setup**: Keep notes on what you've created
3. **Use Resource Groups**: Group related resources for easier management
4. **Set Up Cost Alerts**: Get notified before costs become significant
5. **Regular Cleanup**: Periodically review and clean up unused resources

## Conclusion

By following this guide, you've learned how to properly tear down all the resources created during this lab. This ensures you don't incur unexpected costs and maintain a clean environment for future projects.

Remember that proper resource management is an important part of MLOps and cloud computing in general. Always clean up resources you no longer need, and use infrastructure as code to make this process easier and more reliable.
