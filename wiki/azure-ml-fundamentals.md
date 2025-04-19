# Azure ML Fundamentals

This guide covers the essential command-line operations for working with Azure Machine Learning workspaces and resources.

## Azure Machine Learning Workspace Architecture

An Azure ML workspace is the top-level resource that provides a centralized place to work with all the artifacts you create in Azure ML.

### Creating a Workspace via CLI

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <subscription-id>

# Create resource group
az group create --name myResourceGroup --location eastus

# Create ML workspace
az ml workspace create --name myworkspace --resource-group myResourceGroup
```

### Viewing Workspace Information

```bash
# List all workspaces in a resource group
az ml workspace list --resource-group myResourceGroup

# Get details of a specific workspace
az ml workspace show --name myworkspace --resource-group myResourceGroup
```

## Key Components

### 1. Compute Resources

Compute resources are used for model training and inference.

```bash
# List compute targets in a workspace
az ml compute list --workspace-name myworkspace --resource-group myResourceGroup

# Create a compute cluster
az ml compute create --name cpu-cluster --type amlcompute --min-nodes 0 --max-nodes 4 \
                     --workspace-name myworkspace --resource-group myResourceGroup

# Create a compute instance
az ml compute create --name myinstance --type computeinstance --size Standard_DS3_v2 \
                     --workspace-name myworkspace --resource-group myResourceGroup
```

### 2. Data Management

```bash
# Register a datastore
az ml datastore create --name mydatastore --type azure_blob --account-name mystorageaccount \
                       --container-name mycontainer --workspace-name myworkspace \
                       --resource-group myResourceGroup

# List datastores
az ml datastore list --workspace-name myworkspace --resource-group myResourceGroup

# Create a data asset
az ml data create --name mydataset --version 1 --path https://mystorageaccount.blob.core.windows.net/mycontainer/mydata.csv \
                  --type uri_file --workspace-name myworkspace --resource-group myResourceGroup
```

### 3. Models

```bash
# Register a model
az ml model create --name mymodel --version 1 --path ./model.pkl --type custom_model \
                   --workspace-name myworkspace --resource-group myResourceGroup

# List models
az ml model list --workspace-name myworkspace --resource-group myResourceGroup

# Download a model
az ml model download --name mymodel --version 1 --download-path ./downloaded-model \
                     --workspace-name myworkspace --resource-group myResourceGroup
```

### 4. Endpoints

```bash
# Create an online endpoint
az ml online-endpoint create --name myendpoint --workspace-name myworkspace \
                             --resource-group myResourceGroup

# Create a deployment for an endpoint
az ml online-deployment create --name mydeployment --endpoint-name myendpoint \
                               --model-name mymodel --model-version 1 \
                               --workspace-name myworkspace --resource-group myResourceGroup

# Get endpoint details
az ml online-endpoint show --name myendpoint --workspace-name myworkspace \
                           --resource-group myResourceGroup
```

## Authentication and Access Control

### Service Principal Authentication

```bash
# Create a service principal
az ad sp create-for-rbac --name "ml-auth" --role contributor \
                         --scopes /subscriptions/<subscription-id>/resourceGroups/myResourceGroup

# Login with service principal
az login --service-principal --username <app-id> --password <password> --tenant <tenant-id>
```

### Managing Access Control

```bash
# Assign a role to a user
az role assignment create --assignee user@example.com --role "AzureML Data Scientist" \
                          --scope /subscriptions/<subscription-id>/resourceGroups/myResourceGroup/providers/Microsoft.MachineLearningServices/workspaces/myworkspace
```

## Azure Resource Manager Concepts

### Resource Groups

```bash
# Create a resource group
az group create --name myResourceGroup --location eastus

# List resource groups
az group list --output table

# Delete a resource group
az group delete --name myResourceGroup --yes
```

### Resource Locks

```bash
# Create a read-only lock on a workspace
az lock create --name mylock --resource-group myResourceGroup \
               --resource-name myworkspace --lock-type ReadOnly \
               --resource-type Microsoft.MachineLearningServices/workspaces
```

## Next Steps

Now that you understand the fundamentals of Azure ML through the command line, proceed to:

1. [Development Environment Setup](development-environment.md)
2. [Data Management in Azure](data-management.md)

## Troubleshooting Common Issues

### Authentication Errors

If you encounter authentication errors:

```bash
# Verify your login status
az account show

# Refresh your authentication token
az login
```

### Resource Not Found Errors

If resources aren't found:

```bash
# Verify your current subscription
az account show

# List all resources in the resource group
az resource list --resource-group myResourceGroup
```
