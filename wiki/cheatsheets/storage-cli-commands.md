# Azure Storage CLI Commands Cheat Sheet

This cheat sheet provides a quick reference for common Azure Storage CLI commands used in MLOps workflows.

## Authentication and Setup

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <subscription-id>

# Get storage account key
az storage account keys list --account-name <storage-account-name> --resource-group <resource-group> --query "[0].value" -o tsv
```

## Storage Account Management

```bash
# Create storage account
az storage account create --name <storage-account-name> --resource-group <resource-group> \
                          --location <location> --sku Standard_LRS

# List storage accounts
az storage account list --resource-group <resource-group> --output table

# Get storage account connection string
az storage account show-connection-string --name <storage-account-name> \
                                          --resource-group <resource-group> --query connectionString -o tsv

# Enable hierarchical namespace (for Data Lake Storage Gen2)
az storage account create --name <storage-account-name> --resource-group <resource-group> \
                          --location <location> --sku Standard_LRS --kind StorageV2 \
                          --enable-hierarchical-namespace true
```

## Blob Storage Operations

### Container Management

```bash
# Create a container
az storage container create --name <container-name> --account-name <storage-account-name> \
                            --account-key <account-key>

# List containers
az storage container list --account-name <storage-account-name> --account-key <account-key> \
                          --output table

# Set container access level
az storage container set-permission --name <container-name> --public-access blob \
                                    --account-name <storage-account-name> --account-key <account-key>
```

### Blob Operations

```bash
# Upload a file to blob storage
az storage blob upload --container-name <container-name> --file <local-file-path> \
                       --name <blob-name> --account-name <storage-account-name> \
                       --account-key <account-key>

# Upload a directory to blob storage
az storage blob upload-batch --source <local-directory> --destination <container-name> \
                             --account-name <storage-account-name> --account-key <account-key>

# List blobs in a container
az storage blob list --container-name <container-name> --output table \
                     --account-name <storage-account-name> --account-key <account-key>

# Download a blob
az storage blob download --container-name <container-name> --name <blob-name> \
                         --file <local-file-path> --account-name <storage-account-name> \
                         --account-key <account-key>

# Download all blobs in a container
az storage blob download-batch --source <container-name> --destination <local-directory> \
                               --account-name <storage-account-name> --account-key <account-key>

# Copy a blob
az storage blob copy start --source-uri <source-blob-url> \
                           --destination-container <destination-container> \
                           --destination-blob <destination-blob-name> \
                           --account-name <storage-account-name> --account-key <account-key>

# Delete a blob
az storage blob delete --container-name <container-name> --name <blob-name> \
                       --account-name <storage-account-name> --account-key <account-key>

# Delete multiple blobs
az storage blob delete-batch --source <container-name> --pattern "*.csv" \
                             --account-name <storage-account-name> --account-key <account-key>
```

### SAS Token Generation

```bash
# Generate a SAS token for a container
az storage container generate-sas --name <container-name> \
                                  --permissions racwdl \
                                  --expiry $(date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ') \
                                  --account-name <storage-account-name> \
                                  --account-key <account-key> -o tsv

# Generate a SAS token for a blob
az storage blob generate-sas --container-name <container-name> --name <blob-name> \
                             --permissions r --expiry $(date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ') \
                             --account-name <storage-account-name> --account-key <account-key> -o tsv

# Generate a SAS token for the storage account
az storage account generate-sas --permissions cdlruwap --services b \
                                --resource-types sco --expiry $(date -u -d "1 day" '+%Y-%m-%dT%H:%MZ') \
                                --account-name <storage-account-name> --account-key <account-key> -o tsv
```

## Azure Data Lake Storage Gen2 Operations

### Filesystem Management

```bash
# Create a filesystem (equivalent to a container in Blob storage)
az storage fs create --name <filesystem-name> --account-name <storage-account-name> \
                     --account-key <account-key>

# List filesystems
az storage fs list --account-name <storage-account-name> --account-key <account-key> \
                   --output table
```

### Directory and File Operations

```bash
# Create a directory
az storage fs directory create --name <directory-path> --filesystem <filesystem-name> \
                               --account-name <storage-account-name> --account-key <account-key>

# List directories and files
az storage fs list --filesystem <filesystem-name> --path <directory-path> \
                   --account-name <storage-account-name> --account-key <account-key> \
                   --output table

# Upload a file
az storage fs file upload --path <destination-path> --source <local-file-path> \
                          --filesystem <filesystem-name> \
                          --account-name <storage-account-name> --account-key <account-key>

# Download a file
az storage fs file download --path <file-path> --destination <local-file-path> \
                            --filesystem <filesystem-name> \
                            --account-name <storage-account-name> --account-key <account-key>

# Delete a file
az storage fs file delete --path <file-path> --filesystem <filesystem-name> \
                          --account-name <storage-account-name> --account-key <account-key>

# Delete a directory
az storage fs directory delete --name <directory-path> --filesystem <filesystem-name> \
                               --account-name <storage-account-name> --account-key <account-key> \
                               --recursive
```

## Azure Files Operations

### Share Management

```bash
# Create a file share
az storage share create --name <share-name> --account-name <storage-account-name> \
                        --account-key <account-key>

# List file shares
az storage share list --account-name <storage-account-name> --account-key <account-key> \
                      --output table

# Set quota for a file share
az storage share update --name <share-name> --quota 100 \
                        --account-name <storage-account-name> --account-key <account-key>
```

### File Operations

```bash
# Create a directory in a file share
az storage directory create --name <directory-name> --share-name <share-name> \
                            --account-name <storage-account-name> --account-key <account-key>

# Upload a file to a file share
az storage file upload --share-name <share-name> --source <local-file-path> \
                       --path <file-path> --account-name <storage-account-name> \
                       --account-key <account-key>

# List files and directories
az storage file list --share-name <share-name> --path <directory-path> \
                     --account-name <storage-account-name> --account-key <account-key> \
                     --output table

# Download a file
az storage file download --share-name <share-name> --path <file-path> \
                         --dest <local-file-path> --account-name <storage-account-name> \
                         --account-key <account-key>

# Delete a file
az storage file delete --share-name <share-name> --path <file-path> \
                       --account-name <storage-account-name> --account-key <account-key>
```

## Azure ML Datastore Operations

```bash
# Register a blob storage as a datastore
az ml datastore create --name <datastore-name> --type azure_blob \
                       --account-name <storage-account-name> --container-name <container-name> \
                       --account-key <account-key> \
                       --workspace-name <workspace-name> --resource-group <resource-group>

# Register an ADLS Gen2 storage as a datastore
az ml datastore create --name <datastore-name> --type azure_data_lake_gen2 \
                       --account-name <storage-account-name> --filesystem <filesystem-name> \
                       --account-key <account-key> \
                       --workspace-name <workspace-name> --resource-group <resource-group>

# List datastores
az ml datastore list --workspace-name <workspace-name> --resource-group <resource-group> \
                     --output table

# Show datastore details
az ml datastore show --name <datastore-name> \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# Set a datastore as the default
az ml datastore update --name <datastore-name> --set-default \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

## Data Asset Management

```bash
# Create a data asset from files in a datastore
az ml data create --name <data-asset-name> --version 1 \
                  --path azureml://datastores/<datastore-name>/paths/<container-path>/ \
                  --type uri_folder \
                  --workspace-name <workspace-name> --resource-group <resource-group>

# Create a data asset from a specific file
az ml data create --name <data-asset-name> --version 1 \
                  --path azureml://datastores/<datastore-name>/paths/<container-path>/<filename> \
                  --type uri_file \
                  --workspace-name <workspace-name> --resource-group <resource-group>

# List data assets
az ml data list --workspace-name <workspace-name> --resource-group <resource-group> \
                --output table

# Show data asset details
az ml data show --name <data-asset-name> --version 1 \
                --workspace-name <workspace-name> --resource-group <resource-group>
```

## Common MLOps Storage Workflows

### Setting Up a Data Pipeline

```bash
# Create a storage account for raw data
az storage account create --name <raw-data-account> --resource-group <resource-group> \
                          --location <location> --sku Standard_LRS

# Create a container for raw data
az storage container create --name raw-data --account-name <raw-data-account> \
                            --account-key <raw-data-account-key>

# Create a container for processed data
az storage container create --name processed-data --account-name <raw-data-account> \
                            --account-key <raw-data-account-key>

# Register datastores in Azure ML
az ml datastore create --name raw-data --type azure_blob \
                       --account-name <raw-data-account> --container-name raw-data \
                       --account-key <raw-data-account-key> \
                       --workspace-name <workspace-name> --resource-group <resource-group>

az ml datastore create --name processed-data --type azure_blob \
                       --account-name <raw-data-account> --container-name processed-data \
                       --account-key <raw-data-account-key> \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

### Syncing Data for Training

```bash
# Upload training data to blob storage
az storage blob upload-batch --source ./training-data --destination raw-data \
                             --account-name <raw-data-account> --account-key <raw-data-account-key>

# Create a data asset for the training data
az ml data create --name training-data --version 1 \
                  --path azureml://datastores/raw-data/paths/training-data/ \
                  --type uri_folder \
                  --workspace-name <workspace-name> --resource-group <resource-group>
```

### Storing Model Outputs

```bash
# Create a container for model outputs
az storage container create --name model-outputs --account-name <storage-account-name> \
                            --account-key <account-key>

# Register as a datastore
az ml datastore create --name model-outputs --type azure_blob \
                       --account-name <storage-account-name> --container-name model-outputs \
                       --account-key <account-key> \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

## Troubleshooting Storage Issues

```bash
# Check storage account health
az storage account show --name <storage-account-name> --resource-group <resource-group> \
                        --query statusOfPrimary

# Check if a blob exists
az storage blob exists --container-name <container-name> --name <blob-name> \
                       --account-name <storage-account-name> --account-key <account-key>

# Check storage account metrics
az monitor metrics list --resource <storage-account-resource-id> \
                        --metric "Transactions" --interval PT1H

# Check storage account logs
az storage logging show --account-name <storage-account-name> --account-key <account-key>
```
