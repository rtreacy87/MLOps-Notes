# Security Best Practices for Azure ML

This guide covers how to implement secure configurations for your ML environments using command-line tools.

## Table of Contents
- [Introduction to ML Security](#introduction-to-ml-security)
- [Network Security](#network-security)
- [Identity and Access Management](#identity-and-access-management)
- [Data Protection](#data-protection)
- [Compute Security](#compute-security)
- [Model Security](#model-security)
- [Monitoring and Threat Detection](#monitoring-and-threat-detection)
- [Compliance and Governance](#compliance-and-governance)

## Introduction to ML Security

Machine learning systems face unique security challenges:
- Protection of sensitive training data
- Securing model artifacts
- Preventing adversarial attacks
- Ensuring deployment security
- Maintaining compliance with regulations

## Network Security

### Private Link and VNet Integration

```bash
# Create a workspace with private link
az ml workspace create --name secure-workspace \
  --resource-group myresourcegroup \
  --location eastus \
  --public-network-access Disabled \
  --image-build-compute-name secure-build-compute

# Configure private endpoints
az network private-endpoint create \
  --name ml-pe \
  --resource-group myresourcegroup \
  --vnet-name ml-vnet \
  --subnet ml-subnet \
  --private-connection-resource-id $(az ml workspace show --name secure-workspace --resource-group myresourcegroup --query id -o tsv) \
  --group-id amlworkspace \
  --connection-name ml-pe-connection
```

### Network Security Groups

```bash
# Create NSG rules for ML traffic
az network nsg rule create \
  --resource-group myresourcegroup \
  --nsg-name ml-nsg \
  --name AllowAzureMLOutbound \
  --priority 100 \
  --direction Outbound \
  --source-address-prefixes VirtualNetwork \
  --source-port-ranges '*' \
  --destination-address-prefixes AzureMachineLearning \
  --destination-port-ranges 443 \
  --protocol Tcp \
  --access Allow
```

### Firewall Configuration

```bash
# Configure Azure Firewall for ML traffic
az network firewall application-rule create \
  --collection-name AzureML \
  --firewall-name ml-firewall \
  --name AllowAzureML \
  --protocols https=443 \
  --resource-group myresourcegroup \
  --target-fqdns '*.azureml.ms' '*.experiments.azureml.net' '*.modelmanagement.azureml.net' '*.azuremlsolutions.com' \
  --source-addresses 10.0.0.0/24 \
  --priority 100 \
  --action Allow
```

## Identity and Access Management

### Role-Based Access Control (RBAC)

```bash
# Assign ML-specific roles
az role assignment create \
  --assignee user@example.com \
  --role "AzureML Data Scientist" \
  --scope /subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/Microsoft.MachineLearningServices/workspaces/myworkspace

# Create custom role for specific ML operations
az role definition create --role-definition '{
  "Name": "ML Model Deployer",
  "Description": "Can deploy models but cannot modify them",
  "Actions": [
    "Microsoft.MachineLearningServices/workspaces/models/read",
    "Microsoft.MachineLearningServices/workspaces/endpoints/*",
    "Microsoft.MachineLearningServices/workspaces/deployments/*"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/{subscription-id}"]
}'
```

### Managed Identities

```bash
# Create a workspace with system-assigned managed identity
az ml workspace create --name secure-workspace \
  --resource-group myresourcegroup \
  --location eastus \
  --identity-type SystemAssigned

# Grant the workspace identity access to Key Vault
az keyvault set-policy \
  --name ml-keyvault \
  --object-id $(az ml workspace show --name secure-workspace --resource-group myresourcegroup --query identity.principalId -o tsv) \
  --secret-permissions get list \
  --key-permissions get list
```

### Authentication for Deployments

```bash
# Create an endpoint with key-based authentication
az ml online-endpoint create --file endpoint.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example endpoint YAML with authentication:

```yaml
# endpoint.yml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
name: secure-endpoint
auth_mode: key  # Options: key, aml_token

# For token-based auth:
# auth_mode: aml_token
```

## Data Protection

### Data Encryption

```bash
# Create a workspace with customer-managed keys
az ml workspace create --name secure-workspace \
  --resource-group myresourcegroup \
  --location eastus \
  --encryption-key-name ml-encryption-key \
  --encryption-key-version 00000000000000000000000000000000 \
  --encryption-key-vault https://ml-keyvault.vault.azure.net/
```

### Secure Data Access

```bash
# Create a datastore with managed identity authentication
az ml datastore create --file datastore.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example datastore YAML with secure access:

```yaml
# datastore.yml
$schema: https://azuremlschemas.azureedge.net/latest/azureBlob.schema.json
name: secure-datastore
type: azure_blob
description: Datastore with managed identity authentication
account_name: mystorageaccount
container_name: data
credentials:
  credential_type: msi
```

### Secure Data Transfer

```bash
# Create a dataset with secure transfer
az ml data create --file dataset.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example dataset YAML with secure transfer:

```yaml
# dataset.yml
$schema: https://azuremlschemas.azureedge.net/latest/data.schema.json
name: secure-dataset
description: Dataset with secure transfer
path: azureml://datastores/secure-datastore/paths/data/
type: uri_folder
```

## Compute Security

### Secure Compute Configuration

```bash
# Create a compute cluster with network isolation
az ml compute create --name secure-cluster \
  --type AmlCompute \
  --min-instances 0 \
  --max-instances 4 \
  --size Standard_DS3_v2 \
  --vnet-name ml-vnet \
  --subnet ml-subnet \
  --workspace-name myworkspace \
  --resource-group myresourcegroup
```

### Environment Security

```bash
# Create a secure environment
az ml environment create --file environment.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example environment YAML with security:

```yaml
# environment.yml
$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json
name: secure-env
version: 1
image: mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04:latest
conda_file: ./conda.yml
description: Secure environment with minimal dependencies
```

## Model Security

### Secure Model Registration

```bash
# Register a model with access control
az ml model create --name secure-model \
  --version 1 \
  --path azureml://jobs/<job-id>/outputs/model \
  --type mlflow_model \
  --workspace-name myworkspace \
  --resource-group myresourcegroup
```

### Secure Model Deployment

```bash
# Deploy a model with security configurations
az ml online-deployment create --file deployment.yml --endpoint-name secure-endpoint --workspace-name myworkspace --resource-group myresourcegroup
```

Example deployment YAML with security:

```yaml
# deployment.yml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: secure-deployment
endpoint_name: secure-endpoint
model: azureml:secure-model:1
environment: azureml:secure-env:1
instance_type: Standard_DS3_v2
instance_count: 1
request_settings:
  max_concurrent_requests_per_instance: 1
  request_timeout_ms: 3000
  max_queue_wait_ms: 3000
liveness_probe:
  initial_delay: 30
  period: 5
  timeout: 2
  success_threshold: 1
  failure_threshold: 3
readiness_probe:
  initial_delay: 30
  period: 5
  timeout: 2
  success_threshold: 1
  failure_threshold: 3
```

## Monitoring and Threat Detection

### Security Monitoring

```bash
# Enable diagnostic settings for ML workspace
az monitor diagnostic-settings create \
  --name ml-diagnostics \
  --resource $(az ml workspace show --name myworkspace --resource-group myresourcegroup --query id -o tsv) \
  --logs '[{"category": "AmlComputeClusterEvent","enabled": true},{"category": "AmlComputeJobEvent","enabled": true}]' \
  --workspace $(az monitor log-analytics workspace show --workspace-name ml-logs --resource-group myresourcegroup --query id -o tsv)
```

### Threat Detection

```bash
# Enable Microsoft Defender for Cloud for ML
az security pricing create -n ContainerRegistry --tier Standard
az security pricing create -n KeyVaults --tier Standard
az security pricing create -n StorageAccounts --tier Standard
az security pricing create -n VirtualMachines --tier Standard
```

## Compliance and Governance

### Compliance Monitoring

```bash
# Check compliance with Azure Policy
az policy assignment list --disable-scope-strict-match

# Create a policy assignment for ML security
az policy assignment create \
  --name "ml-security-policy" \
  --display-name "Machine Learning Security Standards" \
  --policy-set-definition "1f3afdf9-d0c9-4c3d-847f-89da613e70a8" \  # Azure Security Benchmark
  --scope /subscriptions/{subscription-id}/resourceGroups/myresourcegroup \
  --assign-identity
```

### Security Scanning

```bash
# Scan container images for vulnerabilities
az acr run --registry myregistry --cmd 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image myregistry.azurecr.io/mymodel:latest' /dev/null
```

### Security Auditing

```bash
# Export security audit logs
az monitor activity-log list \
  --resource-group myresourcegroup \
  --caller user@example.com \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-31T23:59:59Z \
  --query "[?authorization.action=='Microsoft.MachineLearningServices/workspaces/write']" \
  --output json > security_audit.json
```

## Next Steps

- Learn about [Password Management and Security](security-password-management.md) for securely handling credentials
- Implement [infrastructure as code](11.infrastructure-as-code.md) for your ML resources
- Learn about [Azure ecosystem integration](azure-ecosystem.md) for secure ML workflows
- Explore [advanced features](advanced-features.md) with security considerations
