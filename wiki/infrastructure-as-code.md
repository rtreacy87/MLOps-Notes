# Infrastructure as Code for Azure ML

This guide covers how to manage Azure Machine Learning infrastructure using Infrastructure as Code (IaC) tools, focusing on command-line approaches.

## Why Infrastructure as Code for ML?

Using IaC for your ML infrastructure provides several benefits:
- Reproducibility of environments
- Version control for infrastructure
- Automated deployment and updates
- Consistent environments across development, testing, and production
- Easier collaboration among team members

## ARM Templates for ML Resources

Azure Resource Manager (ARM) templates are JSON files that define the infrastructure and configuration for your Azure resources.

### Creating an ARM Template for an Azure ML Workspace

```bash
# Create a directory for your ARM templates
mkdir -p arm-templates
cd arm-templates

# Create an ARM template for an ML workspace
cat > ml-workspace.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workspaceName": {
      "type": "string",
      "metadata": {
        "description": "Name of the Azure Machine Learning workspace."
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for all resources."
      }
    },
    "storageAccountName": {
      "type": "string",
      "defaultValue": "[concat('sa', uniqueString(resourceGroup().id))]",
      "metadata": {
        "description": "Name of the storage account."
      }
    },
    "keyVaultName": {
      "type": "string",
      "defaultValue": "[concat('kv', uniqueString(resourceGroup().id))]",
      "metadata": {
        "description": "Name of the key vault."
      }
    },
    "applicationInsightsName": {
      "type": "string",
      "defaultValue": "[concat('ai', uniqueString(resourceGroup().id))]",
      "metadata": {
        "description": "Name of the application insights."
      }
    },
    "containerRegistryName": {
      "type": "string",
      "defaultValue": "[concat('cr', uniqueString(resourceGroup().id))]",
      "metadata": {
        "description": "Name of the container registry."
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
      "name": "[parameters('applicationInsightsName')]",
      "location": "[parameters('location')]",
      "kind": "web",
      "properties": {
        "Application_Type": "web"
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
      "apiVersion": "2021-07-01",
      "name": "[parameters('workspaceName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]",
        "[resourceId('Microsoft.KeyVault/vaults', parameters('keyVaultName'))]",
        "[resourceId('Microsoft.Insights/components', parameters('applicationInsightsName'))]",
        "[resourceId('Microsoft.ContainerRegistry/registries', parameters('containerRegistryName'))]"
      ],
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "friendlyName": "[parameters('workspaceName')]",
        "storageAccount": "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]",
        "keyVault": "[resourceId('Microsoft.KeyVault/vaults', parameters('keyVaultName'))]",
        "applicationInsights": "[resourceId('Microsoft.Insights/components', parameters('applicationInsightsName'))]",
        "containerRegistry": "[resourceId('Microsoft.ContainerRegistry/registries', parameters('containerRegistryName'))]"
      }
    }
  ],
  "outputs": {
    "workspaceResource": {
      "type": "object",
      "value": "[reference(resourceId('Microsoft.MachineLearningServices/workspaces', parameters('workspaceName')))]"
    }
  }
}
EOF

# Create a parameters file
cat > ml-workspace.parameters.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workspaceName": {
      "value": "mlops-workspace"
    }
  }
}
EOF
```

### Deploying the ARM Template

```bash
# Deploy the ARM template
az deployment group create --resource-group <resource-group> \
                           --template-file ml-workspace.json \
                           --parameters @ml-workspace.parameters.json
```

### Creating an ARM Template for Compute Resources

```bash
cat > compute-resources.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workspaceName": {
      "type": "string",
      "metadata": {
        "description": "Name of the Azure Machine Learning workspace."
      }
    },
    "clusterName": {
      "type": "string",
      "metadata": {
        "description": "Name of the Azure Machine Learning compute cluster."
      }
    },
    "vmSize": {
      "type": "string",
      "defaultValue": "Standard_DS3_v2",
      "metadata": {
        "description": "VM size for the compute cluster."
      }
    },
    "minNodeCount": {
      "type": "int",
      "defaultValue": 0,
      "metadata": {
        "description": "Minimum node count for the compute cluster."
      }
    },
    "maxNodeCount": {
      "type": "int",
      "defaultValue": 4,
      "metadata": {
        "description": "Maximum node count for the compute cluster."
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.MachineLearningServices/workspaces/computes",
      "apiVersion": "2021-07-01",
      "name": "[concat(parameters('workspaceName'), '/', parameters('clusterName'))]",
      "location": "[resourceGroup().location]",
      "properties": {
        "computeType": "AmlCompute",
        "properties": {
          "vmSize": "[parameters('vmSize')]",
          "scaleSettings": {
            "minNodeCount": "[parameters('minNodeCount')]",
            "maxNodeCount": "[parameters('maxNodeCount')]"
          },
          "remoteLoginPortPublicAccess": "Disabled"
        }
      }
    }
  ]
}
EOF

# Create a parameters file
cat > compute-resources.parameters.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workspaceName": {
      "value": "mlops-workspace"
    },
    "clusterName": {
      "value": "cpu-cluster"
    }
  }
}
EOF
```

### Deploying Compute Resources

```bash
az deployment group create --resource-group <resource-group> \
                           --template-file compute-resources.json \
                           --parameters @compute-resources.parameters.json
```

## Terraform Configurations for Azure ML

Terraform is a popular IaC tool that supports multiple cloud providers, including Azure.

### Setting Up Terraform

```bash
# Install Terraform (Ubuntu/Debian)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Verify installation
terraform version
```

### Creating Terraform Configuration Files

```bash
# Create a directory for your Terraform files
mkdir -p terraform
cd terraform

# Create a provider configuration file
cat > provider.tf << 'EOF'
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.90.0"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF

# Create a main configuration file for Azure ML resources
cat > main.tf << 'EOF'
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_application_insights" "ai" {
  name                = "${var.prefix}-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault" "kv" {
  name                = "${var.prefix}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}sa"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_machine_learning_workspace" "mlw" {
  name                    = "${var.prefix}-mlw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.sa.id
  container_registry_id   = azurerm_container_registry.acr.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_machine_learning_compute_cluster" "compute" {
  name                  = var.compute_name
  location              = azurerm_resource_group.rg.location
  vm_priority           = "Dedicated"
  vm_size               = var.vm_size
  machine_learning_workspace_id = azurerm_machine_learning_workspace.mlw.id

  scale_settings {
    min_node_count                       = var.min_node_count
    max_node_count                       = var.max_node_count
    scale_down_nodes_after_idle_duration = "PT30M" # 30 minutes
  }
}

data "azurerm_client_config" "current" {}
EOF

# Create a variables file
cat > variables.tf << 'EOF'
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "mlops"
}

variable "compute_name" {
  description = "Name of the compute cluster"
  type        = string
  default     = "cpu-cluster"
}

variable "vm_size" {
  description = "VM size for the compute cluster"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "min_node_count" {
  description = "Minimum node count for the compute cluster"
  type        = number
  default     = 0
}

variable "max_node_count" {
  description = "Maximum node count for the compute cluster"
  type        = number
  default     = 4
}
EOF

# Create a terraform.tfvars file
cat > terraform.tfvars << 'EOF'
resource_group_name = "mlops-rg"
location            = "eastus"
prefix              = "mlops"
compute_name        = "cpu-cluster"
vm_size             = "Standard_DS3_v2"
min_node_count      = 0
max_node_count      = 4
EOF
```

### Deploying with Terraform

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the deployment
terraform apply tfplan
```

## Bicep for ML Infrastructure

Bicep is a domain-specific language (DSL) for deploying Azure resources, which provides a more concise syntax than ARM templates.

### Creating Bicep Files

```bash
# Create a directory for your Bicep files
mkdir -p bicep
cd bicep

# Create a Bicep file for an ML workspace
cat > ml-workspace.bicep << 'EOF'
param workspaceName string
param location string = resourceGroup().location
param storageAccountName string = 'sa${uniqueString(resourceGroup().id)}'
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'
param appInsightsName string = 'ai${uniqueString(resourceGroup().id)}'
param containerRegistryName string = 'cr${uniqueString(resourceGroup().id)}'

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

resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2021-07-01' = {
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

output workspaceId string = mlWorkspace.id
EOF

# Create a Bicep file for compute resources
cat > compute.bicep << 'EOF'
param workspaceName string
param clusterName string
param vmSize string = 'Standard_DS3_v2'
param minNodeCount int = 0
param maxNodeCount int = 4
param location string = resourceGroup().location

resource computeCluster 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  name: '${workspaceName}/${clusterName}'
  location: location
  properties: {
    computeType: 'AmlCompute'
    properties: {
      vmSize: vmSize
      scaleSettings: {
        minNodeCount: minNodeCount
        maxNodeCount: maxNodeCount
      }
      remoteLoginPortPublicAccess: 'Disabled'
    }
  }
}
EOF

# Create a parameters file
cat > ml-workspace.parameters.json << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workspaceName": {
      "value": "mlops-workspace"
    }
  }
}
EOF
```

### Deploying with Bicep

```bash
# Deploy the Bicep file for ML workspace
az deployment group create --resource-group <resource-group> \
                           --template-file ml-workspace.bicep \
                           --parameters @ml-workspace.parameters.json

# Deploy compute resources
az deployment group create --resource-group <resource-group> \
                           --template-file compute.bicep \
                           --parameters workspaceName=mlops-workspace clusterName=cpu-cluster
```

## Environment Reproducibility Strategies

### Using Azure ML CLI for Environment Definitions

```bash
# Create an environment definition YAML file
cat > environment.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json
name: sklearn-env
version: 1
conda_file:
  channels:
    - conda-forge
  dependencies:
    - python=3.8
    - pip=21.3.1
    - scikit-learn=1.0.2
    - numpy=1.22.3
    - pandas=1.4.2
    - pip:
      - azureml-defaults>=1.48.0
      - mlflow>=1.26.0
      - azureml-mlflow>=1.48.0
EOF

# Register the environment
az ml environment create --file environment.yml \
                         --workspace-name <workspace-name> --resource-group <resource-group>
```

### Using Docker Containers for Reproducible Environments

```bash
# Create a Dockerfile
cat > Dockerfile << 'EOF'
FROM mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04:latest

# Install Python packages
RUN pip install --no-cache-dir \
    scikit-learn==1.0.2 \
    numpy==1.22.3 \
    pandas==1.4.2 \
    mlflow==1.26.0 \
    azureml-mlflow==1.48.0 \
    azureml-defaults==1.48.0

# Set working directory
WORKDIR /code
EOF

# Build the Docker image
docker build -t myacr.azurecr.io/sklearn-env:1.0 .

# Push to Azure Container Registry
az acr login --name myacr
docker push myacr.azurecr.io/sklearn-env:1.0

# Create an environment using the Docker image
cat > docker-env.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json
name: sklearn-docker-env
version: 1
image: myacr.azurecr.io/sklearn-env:1.0
EOF

az ml environment create --file docker-env.yml \
                         --workspace-name <workspace-name> --resource-group <resource-group>
```

## Best Practices for IaC in ML Projects

### Modularize Your Infrastructure Code

Break down your infrastructure into logical modules:

```bash
# Create a modular structure
mkdir -p iac/modules/{workspace,compute,storage,endpoints}

# Example: Create a module for compute resources
cat > iac/modules/compute/main.tf << 'EOF'
variable "workspace_id" {
  description = "ID of the Azure ML workspace"
  type        = string
}

variable "compute_name" {
  description = "Name of the compute cluster"
  type        = string
}

variable "vm_size" {
  description = "VM size for the compute cluster"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "min_node_count" {
  description = "Minimum node count"
  type        = number
  default     = 0
}

variable "max_node_count" {
  description = "Maximum node count"
  type        = number
  default     = 4
}

resource "azurerm_machine_learning_compute_cluster" "compute" {
  name                          = var.compute_name
  vm_priority                   = "Dedicated"
  vm_size                       = var.vm_size
  machine_learning_workspace_id = var.workspace_id

  scale_settings {
    min_node_count                       = var.min_node_count
    max_node_count                       = var.max_node_count
    scale_down_nodes_after_idle_duration = "PT30M"
  }
}

output "compute_id" {
  value = azurerm_machine_learning_compute_cluster.compute.id
}
EOF
```

### Use Version Control for Infrastructure Code

```bash
# Initialize a Git repository for your IaC
git init
echo "# Azure ML Infrastructure" > README.md
git add .
git commit -m "Initial infrastructure code"

# Create a .gitignore file
cat > .gitignore << 'EOF'
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
*.tfplan
.terraform.lock.hcl

# Bicep
*.bicepparam

# Local .terraform directories
**/.terraform/*

# Crash log files
crash.log

# Sensitive data
*.tfvars

# ARM template parameters
*parameters.json
EOF

git add .gitignore
git commit -m "Add .gitignore for IaC"
```

### Implement CI/CD for Infrastructure

Create a GitHub Actions workflow for Terraform:

```bash
mkdir -p .github/workflows
cat > .github/workflows/terraform.yml << 'EOF'
name: 'Terraform'

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

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
      
    - name: Terraform Format
      run: terraform fmt -check

    - name: Terraform Plan
      run: terraform plan
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve
      env:
        ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
EOF
```

## Next Steps

After setting up your infrastructure as code:

1. Explore [Azure ML Fundamentals](azure-ml-fundamentals.md) to understand how to use the resources you've created
2. Learn about [MLOps Pipeline Implementation](mlops-pipelines.md) to automate your ML workflows
3. Check out [Governance and Compliance](governance-compliance.md) for managing your ML resources
