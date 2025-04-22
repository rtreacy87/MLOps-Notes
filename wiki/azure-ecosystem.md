# Azure Ecosystem Integration for MLOps

This guide covers how to connect Azure ML with other Azure services like Databricks and Synapse Analytics using command-line tools.

## Table of Contents
- [Introduction to Azure Ecosystem Integration](#introduction-to-azure-ecosystem-integration)
- [Azure Databricks Integration](#azure-databricks-integration)
- [Azure Synapse Analytics Integration](#azure-synapse-analytics-integration)
- [Azure Data Factory Integration](#azure-data-factory-integration)
- [Azure DevOps Integration](#azure-devops-integration)
- [Azure Key Vault Integration](#azure-key-vault-integration)
- [Azure Monitor and Log Analytics](#azure-monitor-and-log-analytics)
- [Azure Container Registry](#azure-container-registry)
- [Azure Kubernetes Service](#azure-kubernetes-service)

## Introduction to Azure Ecosystem Integration

Azure ML works best when integrated with other Azure services to create end-to-end ML workflows. Key integration points include:

- Data storage and processing
- Model training at scale
- CI/CD pipelines
- Monitoring and logging
- Security and access control
- Deployment and serving

## Azure Databricks Integration

### Linking Azure Databricks and Azure ML

```bash
# Create a linked service to Databricks
az ml linked-service create --file databricks-link.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example linked service YAML:

```yaml
# databricks-link.yml
$schema: https://azuremlschemas.azureedge.net/latest/databricks.schema.json
name: databricks-compute
type: databricks
workspace_name: mydatabricksworkspace
resource_id: /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.Databricks/workspaces/mydatabricksworkspace
access_token: {access-token}  # Store this securely in Key Vault
```

### Running Azure ML Jobs on Databricks

```bash
# Create a compute target for Databricks
az ml compute create --file databricks-compute.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example compute YAML:

```yaml
# databricks-compute.yml
$schema: https://azuremlschemas.azureedge.net/latest/databricks.schema.json
name: databricks-compute
type: databricks
resource_id: /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.Databricks/workspaces/mydatabricksworkspace
workspace_name: mydatabricksworkspace
```

### Submitting a Job to Databricks

```bash
# Submit a job to run on Databricks
az ml job create --file databricks-job.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example job YAML:

```yaml
# databricks-job.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python train.py 
  --data-path ${{inputs.training_data}}
  --learning-rate 0.01
inputs:
  training_data:
    path: azureml:training-data:1
    mode: ro_mount
environment: azureml:training-env:1
compute: azureml:databricks-compute
```

## Azure Synapse Analytics Integration

### Linking Azure Synapse and Azure ML

```bash
# Create a linked service to Synapse
az ml linked-service create --file synapse-link.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example linked service YAML:

```yaml
# synapse-link.yml
$schema: https://azuremlschemas.azureedge.net/latest/synapse.schema.json
name: synapse-link
type: synapse
resource_id: /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.Synapse/workspaces/mysynapseworkspace
```

### Creating a Datastore for Synapse

```bash
# Create a datastore for Synapse data
az ml datastore create --file synapse-datastore.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example datastore YAML:

```yaml
# synapse-datastore.yml
$schema: https://azuremlschemas.azureedge.net/latest/synapse.schema.json
name: synapse-datastore
type: synapse
description: Synapse Analytics datastore
workspace_name: mysynapseworkspace
spark_pool_name: sparkpool
```

### Running ML Jobs with Synapse Data

```bash
# Create a dataset from Synapse
az ml data create --file synapse-dataset.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example dataset YAML:

```yaml
# synapse-dataset.yml
$schema: https://azuremlschemas.azureedge.net/latest/data.schema.json
name: synapse-data
description: Data from Synapse Analytics
path: azureml://datastores/synapse-datastore/paths/data/
type: mltable
```

## Azure Data Factory Integration

### Creating Data Factory Pipelines for ML

```bash
# Create a Data Factory
az datafactory create --name myadf --resource-group myresourcegroup --location eastus

# Create a pipeline that triggers Azure ML
az datafactory pipeline create --name ml-data-pipeline --factory-name myadf --resource-group myresourcegroup --pipeline @adf-ml-pipeline.json
```

Example ADF pipeline JSON:

```json
{
  "name": "MLDataPipeline",
  "properties": {
    "activities": [
      {
        "name": "CopyDataToBlob",
        "type": "Copy",
        "inputs": [...],
        "outputs": [...],
        "typeProperties": {...}
      },
      {
        "name": "TriggerMLPipeline",
        "type": "AzureMLExecutePipeline",
        "dependsOn": [
          {
            "activity": "CopyDataToBlob",
            "dependencyConditions": ["Succeeded"]
          }
        ],
        "typeProperties": {
          "mlPipelineId": "azureml://experiments/my-experiment/pipelines/my-pipeline-id",
          "mlWorkspaceName": "myworkspace",
          "mlResourceGroupName": "myresourcegroup"
        },
        "linkedServiceName": {
          "referenceName": "AzureMLService",
          "type": "LinkedServiceReference"
        }
      }
    ]
  }
}
```

## Azure DevOps Integration

### Setting Up CI/CD for ML with Azure DevOps

```bash
# Install the Azure DevOps CLI extension
az extension add --name azure-devops

# Create a service connection to Azure ML
az devops service-endpoint azurerm create --name "AzureMLConnection" \
  --azure-rm-service-principal-id "00000000-0000-0000-0000-000000000000" \
  --azure-rm-subscription-id "00000000-0000-0000-0000-000000000000" \
  --azure-rm-subscription-name "My Subscription" \
  --azure-rm-tenant-id "00000000-0000-0000-0000-000000000000" \
  --organization "https://dev.azure.com/myorg/" \
  --project "myproject"
```

Example Azure DevOps pipeline YAML:

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - ml/**

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.8'
    addToPath: true

- script: |
    pip install azure-cli azure-ml
  displayName: 'Install Azure ML CLI'

- task: AzureCLI@2
  inputs:
    azureSubscription: 'AzureMLConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az ml job create --file ml/pipeline.yml --workspace-name myworkspace --resource-group myresourcegroup
  displayName: 'Run ML Pipeline'
```

## Azure Key Vault Integration

### Storing Secrets for ML Workflows

```bash
# Create a Key Vault
az keyvault create --name ml-keyvault --resource-group myresourcegroup --location eastus

# Add a secret to Key Vault
az keyvault secret set --vault-name ml-keyvault --name "databricks-token" --value "your-token-value"

# Grant Azure ML access to Key Vault
az keyvault set-policy --name ml-keyvault \
  --object-id $(az ml workspace show --name myworkspace --resource-group myresourcegroup --query identity.principalId -o tsv) \
  --secret-permissions get list
```

### Using Key Vault in ML Pipelines

```bash
# Create a linked service to Key Vault
az ml linked-service create --file keyvault-link.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example linked service YAML:

```yaml
# keyvault-link.yml
$schema: https://azuremlschemas.azureedge.net/latest/azureKeyVault.schema.json
name: ml-keyvault-link
type: key_vault
key_vault_uri: https://ml-keyvault.vault.azure.net/
```

## Azure Monitor and Log Analytics

### Setting Up Monitoring for ML

```bash
# Create a Log Analytics workspace
az monitor log-analytics workspace create --workspace-name ml-logs --resource-group myresourcegroup --location eastus

# Enable diagnostic settings for ML workspace
az monitor diagnostic-settings create \
  --name ml-diagnostics \
  --resource $(az ml workspace show --name myworkspace --resource-group myresourcegroup --query id -o tsv) \
  --logs '[{"category": "AmlComputeClusterEvent","enabled": true},{"category": "AmlComputeJobEvent","enabled": true}]' \
  --workspace $(az monitor log-analytics workspace show --workspace-name ml-logs --resource-group myresourcegroup --query id -o tsv)
```

### Creating Custom Dashboards

```bash
# Create a custom dashboard for ML monitoring
az portal dashboard create --name "ML-Monitoring" --resource-group myresourcegroup --location eastus --input-path dashboard.json
```

## Azure Container Registry

### Using ACR with Azure ML

```bash
# Create a Container Registry
az acr create --name mlregistry --resource-group myresourcegroup --sku Standard --location eastus

# Grant Azure ML access to ACR
az role assignment create \
  --assignee $(az ml workspace show --name myworkspace --resource-group myresourcegroup --query identity.principalId -o tsv) \
  --role AcrPull \
  --scope $(az acr show --name mlregistry --resource-group myresourcegroup --query id -o tsv)
```

### Building Custom Environments with ACR

```bash
# Create a custom environment using ACR
az ml environment create --file custom-env.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example environment YAML:

```yaml
# custom-env.yml
$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json
name: custom-env
version: 1
image: mlregistry.azurecr.io/custom-ml-image:latest
description: Custom environment from ACR
```

## Azure Kubernetes Service

### Deploying Models to AKS

```bash
# Create an AKS cluster
az aks create --name ml-aks --resource-group myresourcegroup --node-count 3 --enable-managed-identity

# Attach AKS to Azure ML
az ml compute attach --file aks-compute.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example AKS compute YAML:

```yaml
# aks-compute.yml
$schema: https://azuremlschemas.azureedge.net/latest/kubernetesonline.schema.json
name: ml-aks
type: kubernetes
resource_id: /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.ContainerService/managedClusters/ml-aks
```

### Deploying to AKS

```bash
# Deploy a model to AKS
az ml online-endpoint create --file aks-endpoint.yml --workspace-name myworkspace --resource-group myresourcegroup
az ml online-deployment create --file aks-deployment.yml --endpoint-name aks-endpoint --workspace-name myworkspace --resource-group myresourcegroup
```

Example AKS deployment YAML:

```yaml
# aks-deployment.yml
$schema: https://azuremlschemas.azureedge.net/latest/kubernetesOnlineDeployment.schema.json
name: production
endpoint_name: aks-endpoint
model: azureml:mymodel:1
environment: azureml:serving-env:1
compute: azureml:ml-aks
instance_type: Standard_DS3_v2
instance_count: 3
```

## Next Steps

- Explore [advanced features](advanced-features.md) of Azure ML
- Learn about [daily MLOps workflows](daily-workflows.md)
- Check out the [command-line cheat sheets](cheatsheets/aml-cli-commands.md) for quick reference
