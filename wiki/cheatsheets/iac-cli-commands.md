# Infrastructure as Code CLI Commands Cheatsheet

This cheatsheet provides a quick reference for Infrastructure as Code (IaC) CLI commands commonly used in MLOps workflows, including Azure Resource Manager (ARM), Terraform, and Bicep.

## Table of Contents
- [Azure Resource Manager (ARM)](#azure-resource-manager-arm)
- [Terraform](#terraform)
- [Bicep](#bicep)
- [Azure CLI for Resource Management](#azure-cli-for-resource-management)
- [GitHub Actions for IaC](#github-actions-for-iac)
- [Azure DevOps for IaC](#azure-devops-for-iac)

## Azure Resource Manager (ARM)

### ARM Template Deployment

```bash
# Validate an ARM template
az deployment group validate \
  --resource-group myresourcegroup \
  --template-file azureml.json \
  --parameters azureml.parameters.json

# Deploy an ARM template to a resource group
az deployment group create \
  --name mydeployment \
  --resource-group myresourcegroup \
  --template-file azureml.json \
  --parameters azureml.parameters.json

# Deploy an ARM template at subscription level
az deployment sub create \
  --name mydeployment \
  --location eastus \
  --template-file subscription-level.json \
  --parameters subscription-level.parameters.json

# List deployments in a resource group
az deployment group list \
  --resource-group myresourcegroup

# Show deployment details
az deployment group show \
  --name mydeployment \
  --resource-group myresourcegroup

# Export a resource group to an ARM template
az group export \
  --name myresourcegroup \
  --include-parameter-default-value \
  --include-comments \
  --skip-resource-name-params \
  > exported-template.json
```

### ARM Template Examples

#### Azure ML Workspace ARM Template

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workspaceName": {
      "type": "string",
      "metadata": {
        "description": "Name of the Azure ML workspace"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for all resources"
      }
    },
    "storageAccountName": {
      "type": "string",
      "metadata": {
        "description": "Name of the storage account"
      }
    },
    "keyVaultName": {
      "type": "string",
      "metadata": {
        "description": "Name of the key vault"
      }
    },
    "appInsightsName": {
      "type": "string",
      "metadata": {
        "description": "Name of the application insights"
      }
    },
    "containerRegistryName": {
      "type": "string",
      "metadata": {
        "description": "Name of the container registry"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-04-01",
      "name": "[parameters('storageAccountName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2",
      "properties": {
        "encryption": {
          "services": {
            "blob": {
              "enabled": true
            },
            "file": {
              "enabled": true
            }
          },
          "keySource": "Microsoft.Storage"
        },
        "supportsHttpsTrafficOnly": true
      }
    },
    {
      "type": "Microsoft.KeyVault/vaults",
      "apiVersion": "2021-06-01-preview",
      "name": "[parameters('keyVaultName')]",
      "location": "[parameters('location')]",
      "properties": {
        "tenantId": "[subscription().tenantId]",
        "sku": {
          "name": "standard",
          "family": "A"
        },
        "accessPolicies": []
      }
    },
    {
      "type": "Microsoft.Insights/components",
      "apiVersion": "2020-02-02",
      "name": "[parameters('appInsightsName')]",
      "location": "[parameters('location')]",
      "kind": "web",
      "properties": {
        "Application_Type": "web",
        "Request_Source": "rest"
      }
    },
    {
      "type": "Microsoft.ContainerRegistry/registries",
      "apiVersion": "2021-06-01-preview",
      "name": "[parameters('containerRegistryName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard"
      },
      "properties": {
        "adminUserEnabled": true
      }
    },
    {
      "type": "Microsoft.MachineLearningServices/workspaces",
      "apiVersion": "2022-01-01-preview",
      "name": "[parameters('workspaceName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]",
        "[resourceId('Microsoft.KeyVault/vaults', parameters('keyVaultName'))]",
        "[resourceId('Microsoft.Insights/components', parameters('appInsightsName'))]",
        "[resourceId('Microsoft.ContainerRegistry/registries', parameters('containerRegistryName'))]"
      ],
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "friendlyName": "[parameters('workspaceName')]",
        "storageAccount": "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]",
        "keyVault": "[resourceId('Microsoft.KeyVault/vaults', parameters('keyVaultName'))]",
        "applicationInsights": "[resourceId('Microsoft.Insights/components', parameters('appInsightsName'))]",
        "containerRegistry": "[resourceId('Microsoft.ContainerRegistry/registries', parameters('containerRegistryName'))]"
      }
    }
  ],
  "outputs": {
    "workspaceId": {
      "type": "string",
      "value": "[resourceId('Microsoft.MachineLearningServices/workspaces', parameters('workspaceName'))]"
    }
  }
}
```

## Terraform

### Terraform Commands

```bash
# Initialize a Terraform working directory
terraform init

# Format Terraform files
terraform fmt

# Validate Terraform files
terraform validate

# Plan Terraform changes
terraform plan -out=tfplan

# Apply Terraform changes
terraform apply tfplan

# Apply Terraform changes without a plan file
terraform apply -auto-approve

# Destroy Terraform-managed infrastructure
terraform destroy -auto-approve

# Show Terraform state
terraform show

# List Terraform state resources
terraform state list

# Import existing resources into Terraform state
terraform import azurerm_machine_learning_workspace.example /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.MachineLearningServices/workspaces/myworkspace

# Export Terraform configuration
terraform state show -json azurerm_machine_learning_workspace.example > workspace.json

# Refresh Terraform state
terraform refresh

# Create a Terraform workspace
terraform workspace new dev

# List Terraform workspaces
terraform workspace list

# Select a Terraform workspace
terraform workspace select prod
```

### Terraform with Azure CLI

```bash
# Login to Azure
az login

# Set active subscription
az account set --subscription <subscription-id>

# Create a service principal for Terraform
az ad sp create-for-rbac --name "TerraformSP" --role Contributor --scopes /subscriptions/<subscription-id>

# Store Terraform state in Azure Storage
az storage account create --name tfstate$RANDOM --resource-group myresourcegroup --sku Standard_LRS

# Create a container for Terraform state
az storage container create --name tfstate --account-name <storage-account-name>

# Generate SAS token for Terraform state
az storage account generate-sas --account-name <storage-account-name> --services blob --resource-types container,object --permissions rwdlacup --expiry $(date -u -d "1 year" '+%Y-%m-%dT%H:%MZ')
```

### Terraform Example for Azure ML

```hcl
# main.tf
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "ml-resources"
  location = "East US"
}

resource "azurerm_storage_account" "example" {
  name                     = "mlstorage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault" "example" {
  name                = "mlkeyvault${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_application_insights" "example" {
  name                = "mlappinsights${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  application_type    = "web"
}

resource "azurerm_container_registry" "example" {
  name                = "mlacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_machine_learning_workspace" "example" {
  name                    = "mlworkspace${random_string.suffix.result}"
  location                = azurerm_resource_group.example.location
  resource_group_name     = azurerm_resource_group.example.name
  application_insights_id = azurerm_application_insights.example.id
  key_vault_id            = azurerm_key_vault.example.id
  storage_account_id      = azurerm_storage_account.example.id
  container_registry_id   = azurerm_container_registry.example.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_machine_learning_compute_cluster" "example" {
  name                          = "cpu-cluster"
  location                      = azurerm_resource_group.example.location
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_DS3_v2"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.example.id

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 4
    scale_down_nodes_after_idle_duration = "PT30M" # 30 minutes
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

data "azurerm_client_config" "current" {}
```

## Bicep

### Bicep Commands

```bash
# Install Bicep CLI
az bicep install

# Build a Bicep file to ARM template
az bicep build --file main.bicep

# Decompile an ARM template to Bicep
az bicep decompile --file azureml.json

# Validate a Bicep file
az deployment group validate \
  --resource-group myresourcegroup \
  --template-file main.bicep \
  --parameters params.json

# Deploy a Bicep file to a resource group
az deployment group create \
  --name mydeployment \
  --resource-group myresourcegroup \
  --template-file main.bicep \
  --parameters params.json

# Deploy a Bicep file at subscription level
az deployment sub create \
  --name mydeployment \
  --location eastus \
  --template-file main.bicep \
  --parameters params.json
```

### Bicep Example for Azure ML

```bicep
// main.bicep
param workspaceName string
param location string = resourceGroup().location
param storageAccountName string
param keyVaultName string
param appInsightsName string
param containerRegistryName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource workspace 'Microsoft.MachineLearningServices/workspaces@2022-01-01-preview' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: appInsights.id
    containerRegistry: containerRegistry.id
  }
}

resource computeCluster 'Microsoft.MachineLearningServices/workspaces/computes@2022-01-01-preview' = {
  parent: workspace
  name: 'cpu-cluster'
  location: location
  properties: {
    computeType: 'AmlCompute'
    properties: {
      vmSize: 'Standard_DS3_v2'
      vmPriority: 'Dedicated'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 4
        nodeIdleTimeBeforeScaleDown: 'PT30M'
      }
    }
  }
}

output workspaceId string = workspace.id
```

## Azure CLI for Resource Management

```bash
# Create a resource group
az group create --name myresourcegroup --location eastus

# List resource groups
az group list --query "[].{Name:name, Location:location}" -o table

# Create a deployment from a template
az deployment group create \
  --name mydeployment \
  --resource-group myresourcegroup \
  --template-file azureml.json \
  --parameters azureml.parameters.json

# List resources in a resource group
az resource list --resource-group myresourcegroup -o table

# Show resource details
az resource show \
  --resource-group myresourcegroup \
  --name myworkspace \
  --resource-type "Microsoft.MachineLearningServices/workspaces"

# Delete a resource
az resource delete \
  --resource-group myresourcegroup \
  --name myworkspace \
  --resource-type "Microsoft.MachineLearningServices/workspaces"

# Export a resource group template
az group export \
  --name myresourcegroup \
  --include-parameter-default-value \
  > template.json

# Create a tag on a resource group
az group update --name myresourcegroup --tags Environment=Dev Project=MLOps

# List all resources with a specific tag
az resource list --tag Environment=Dev -o table
```

## GitHub Actions for IaC

### GitHub Actions Workflow Examples

```yaml
# terraform-deploy.yml
name: 'Terraform Deploy'

on:
  push:
    branches: [ main ]
    paths:
      - 'terraform/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'terraform/**'

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v2
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      
    - name: Terraform Init
      run: terraform init
      working-directory: ./terraform
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
        
    - name: Terraform Format
      run: terraform fmt -check
      working-directory: ./terraform
      
    - name: Terraform Plan
      run: terraform plan -out=tfplan
      working-directory: ./terraform
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
        
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve tfplan
      working-directory: ./terraform
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

```yaml
# arm-deploy.yml
name: 'ARM Template Deploy'

on:
  push:
    branches: [ main ]
    paths:
      - 'arm-templates/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'arm-templates/**'

jobs:
  deploy:
    name: 'Deploy ARM Template'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v2
      
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Deploy ARM Template
      uses: azure/arm-deploy@v1
      with:
        resourceGroupName: myresourcegroup
        template: ./arm-templates/azureml.json
        parameters: ./arm-templates/azureml.parameters.json
```

```yaml
# bicep-deploy.yml
name: 'Bicep Deploy'

on:
  push:
    branches: [ main ]
    paths:
      - 'bicep/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'bicep/**'

jobs:
  deploy:
    name: 'Deploy Bicep'
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v2
      
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Deploy Bicep
      uses: azure/arm-deploy@v1
      with:
        resourceGroupName: myresourcegroup
        template: ./bicep/main.bicep
        parameters: ./bicep/params.json
```

## Azure DevOps for IaC

### Azure DevOps Pipeline Examples

```yaml
# terraform-pipeline.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - terraform/**

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Validate
  jobs:
  - job: Validate
    steps:
    - task: TerraformInstaller@0
      inputs:
        terraformVersion: 'latest'
    
    - task: TerraformTaskV2@2
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
        backendServiceArm: 'AzureConnection'
        backendAzureRmResourceGroupName: 'terraform-state-rg'
        backendAzureRmStorageAccountName: 'tfstate$(Build.BuildId)'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'terraform.tfstate'
    
    - task: TerraformTaskV2@2
      inputs:
        provider: 'azurerm'
        command: 'validate'
        workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
    
    - task: TerraformTaskV2@2
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
        environmentServiceNameAzureRM: 'AzureConnection'

- stage: Deploy
  dependsOn: Validate
  condition: succeeded()
  jobs:
  - job: Deploy
    steps:
    - task: TerraformInstaller@0
      inputs:
        terraformVersion: 'latest'
    
    - task: TerraformTaskV2@2
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
        backendServiceArm: 'AzureConnection'
        backendAzureRmResourceGroupName: 'terraform-state-rg'
        backendAzureRmStorageAccountName: 'tfstate$(Build.BuildId)'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'terraform.tfstate'
    
    - task: TerraformTaskV2@2
      inputs:
        provider: 'azurerm'
        command: 'apply'
        workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
        environmentServiceNameAzureRM: 'AzureConnection'
```

```yaml
# arm-pipeline.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - arm-templates/**

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureResourceManagerTemplateDeployment@3
  inputs:
    deploymentScope: 'Resource Group'
    azureResourceManagerConnection: 'AzureConnection'
    subscriptionId: '$(subscriptionId)'
    action: 'Create Or Update Resource Group'
    resourceGroupName: 'myresourcegroup'
    location: 'East US'
    templateLocation: 'Linked artifact'
    csmFile: '$(System.DefaultWorkingDirectory)/arm-templates/azureml.json'
    csmParametersFile: '$(System.DefaultWorkingDirectory)/arm-templates/azureml.parameters.json'
    deploymentMode: 'Incremental'
```

```yaml
# bicep-pipeline.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - bicep/**

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: 'AzureConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az bicep install
      az deployment group create \
        --name $(Build.BuildId) \
        --resource-group myresourcegroup \
        --template-file $(System.DefaultWorkingDirectory)/bicep/main.bicep \
        --parameters $(System.DefaultWorkingDirectory)/bicep/params.json
```
