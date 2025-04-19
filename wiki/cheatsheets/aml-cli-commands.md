# Azure ML CLI Commands Cheat Sheet

This cheat sheet provides a quick reference for common Azure ML CLI commands.

## Installation and Setup

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Ubuntu/Debian
brew install azure-cli  # macOS

# Install Azure ML extension
az extension add -n ml

# Login to Azure
az login

# Set default subscription
az account set --subscription <subscription-id>
```

## Workspace Management

```bash
# Create workspace
az ml workspace create --name <workspace-name> --resource-group <resource-group>

# List workspaces
az ml workspace list --resource-group <resource-group>

# Show workspace details
az ml workspace show --name <workspace-name> --resource-group <resource-group>

# Delete workspace
az ml workspace delete --name <workspace-name> --resource-group <resource-group>
```

## Compute Management

```bash
# Create compute cluster
az ml compute create --name <compute-name> --type amlcompute --min-nodes 0 --max-nodes 4 \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# Create compute instance
az ml compute create --name <instance-name> --type computeinstance --size Standard_DS3_v2 \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# List compute resources
az ml compute list --workspace-name <workspace-name> --resource-group <resource-group>

# Start compute instance
az ml compute start --name <instance-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Stop compute instance
az ml compute stop --name <instance-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Delete compute
az ml compute delete --name <compute-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

## Data Management

```bash
# Create datastore
az ml datastore create --name <datastore-name> --type azure_blob --account-name <storage-account> \
                       --container-name <container> --workspace-name <workspace-name> \
                       --resource-group <resource-group>

# List datastores
az ml datastore list --workspace-name <workspace-name> --resource-group <resource-group>

# Create data asset
az ml data create --name <data-name> --version 1 --path <path-to-data> \
                  --type uri_file --workspace-name <workspace-name> --resource-group <resource-group>

# List data assets
az ml data list --workspace-name <workspace-name> --resource-group <resource-group>
```

## Model Management

```bash
# Register model
az ml model create --name <model-name> --version 1 --path <path-to-model> \
                   --workspace-name <workspace-name> --resource-group <resource-group>

# List models
az ml model list --workspace-name <workspace-name> --resource-group <resource-group>

# Show model details
az ml model show --name <model-name> --version 1 \
                 --workspace-name <workspace-name> --resource-group <resource-group>

# Download model
az ml model download --name <model-name> --version 1 --download-path <local-path> \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# Delete model
az ml model delete --name <model-name> --version 1 \
                   --workspace-name <workspace-name> --resource-group <resource-group>
```

## Environment Management

```bash
# Create environment from conda file
az ml environment create --name <env-name> --version 1 --conda-file <path-to-conda-file> \
                         --workspace-name <workspace-name> --resource-group <resource-group>

# List environments
az ml environment list --workspace-name <workspace-name> --resource-group <resource-group>

# Show environment details
az ml environment show --name <env-name> --version 1 \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

## Job Management

```bash
# Submit a command job
az ml job create --file job.yml --workspace-name <workspace-name> --resource-group <resource-group>

# List jobs
az ml job list --workspace-name <workspace-name> --resource-group <resource-group>

# Show job details
az ml job show --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Stream job logs
az ml job stream --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Cancel job
az ml job cancel --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

## Endpoint Management

```bash
# Create online endpoint
az ml online-endpoint create --name <endpoint-name> \
                             --workspace-name <workspace-name> --resource-group <resource-group>

# Create online deployment
az ml online-deployment create --name <deployment-name> --endpoint-name <endpoint-name> \
                               --model-name <model-name> --model-version 1 \
                               --workspace-name <workspace-name> --resource-group <resource-group>

# List endpoints
az ml online-endpoint list --workspace-name <workspace-name> --resource-group <resource-group>

# Get endpoint details
az ml online-endpoint show --name <endpoint-name> \
                           --workspace-name <workspace-name> --resource-group <resource-group>

# Invoke endpoint
az ml online-endpoint invoke --name <endpoint-name> --request-file <input-data-file> \
                             --workspace-name <workspace-name> --resource-group <resource-group>

# Delete endpoint
az ml online-endpoint delete --name <endpoint-name> \
                             --workspace-name <workspace-name> --resource-group <resource-group> --yes
```

## Pipeline Management

```bash
# Create pipeline
az ml pipeline create --file pipeline.yml \
                      --workspace-name <workspace-name> --resource-group <resource-group>

# List pipelines
az ml pipeline list --workspace-name <workspace-name> --resource-group <resource-group>

# Show pipeline details
az ml pipeline show --name <pipeline-name> \
                    --workspace-name <workspace-name> --resource-group <resource-group>

# Create pipeline job
az ml pipeline job create --name <job-name> --pipeline-name <pipeline-name> \
                          --workspace-name <workspace-name> --resource-group <resource-group>
```

## Asset Export/Import

```bash
# Export model
az ml model export --name <model-name> --version 1 --output-path <local-path> \
                   --workspace-name <workspace-name> --resource-group <resource-group>

# Import model
az ml model import --file <model-metadata-file> \
                   --workspace-name <workspace-name> --resource-group <resource-group>
```
