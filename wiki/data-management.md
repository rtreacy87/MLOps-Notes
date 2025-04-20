# Data Management in Azure ML

This guide covers command-line approaches for managing data in Azure Machine Learning, including storage options, versioning, and monitoring data drift.

## Azure Storage Options

Azure provides several storage options for ML workloads:

### 1. Azure Blob Storage

Blob storage is ideal for unstructured data like images, text files, and CSV files.

```bash
# Create a storage account
az storage account create --name <storage-account-name> --resource-group <resource-group> \
                          --location <location> --sku Standard_LRS

# Create a container
az storage container create --name <container-name> --account-name <storage-account-name> \
                            --account-key <account-key>

# Upload data to blob storage
az storage blob upload-batch --source <local-directory> --destination <container-name> \
                             --account-name <storage-account-name> --account-key <account-key>
```

### 2. Azure Data Lake Storage Gen2

Data Lake Storage is optimized for big data analytics with hierarchical namespace support.

```bash
# Create a storage account with hierarchical namespace
az storage account create --name <storage-account-name> --resource-group <resource-group> \
                          --location <location> --sku Standard_LRS --kind StorageV2 \
                          --enable-hierarchical-namespace true

# Create a filesystem
az storage fs create --name <filesystem-name> --account-name <storage-account-name> \
                     --account-key <account-key>

# Create directories
az storage fs directory create --name <directory-path> --filesystem <filesystem-name> \
                               --account-name <storage-account-name> --account-key <account-key>

# Upload files
az storage fs file upload --path <destination-path> --source <local-file-path> \
                          --filesystem <filesystem-name> \
                          --account-name <storage-account-name> --account-key <account-key>
```

### 3. Azure SQL Database

For structured data that requires relational capabilities:

```bash
# Create an Azure SQL server
az sql server create --name <server-name> --resource-group <resource-group> \
                     --location <location> --admin-user <admin-username> \
                     --admin-password <admin-password>

# Create a database
az sql db create --name <database-name> --server <server-name> \
                 --resource-group <resource-group> --service-objective S0

# Configure firewall rules
az sql server firewall-rule create --name AllowAzureServices \
                                   --server <server-name> \
                                   --resource-group <resource-group> \
                                   --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```

## Registering Datastores in Azure ML

Datastores provide a layer of abstraction over Azure storage services.

```bash
# Register a blob storage as a datastore
az ml datastore create --name <datastore-name> --type azure_blob \
                       --account-name <storage-account-name> --container-name <container-name> \
                       --account-key <account-key> \
                       --workspace-name <workspace-name> --resource-group <resource-group>

# Register a Data Lake Storage Gen2 as a datastore
az ml datastore create --name <datastore-name> --type azure_data_lake_gen2 \
                       --account-name <storage-account-name> --filesystem <filesystem-name> \
                       --account-key <account-key> \
                       --workspace-name <workspace-name> --resource-group <resource-group>

# Register an Azure SQL database as a datastore
az ml datastore create --name <datastore-name> --type azure_sql_database \
                       --server-name <server-name>.database.windows.net \
                       --database-name <database-name> \
                       --username <username> --password <password> \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

## Creating Data Assets

Data assets (formerly datasets) represent specific data you want to use for ML.

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

# Create a data asset from a SQL query
cat > sql-query.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/data.schema.json
name: sql-data
version: 1
description: Data from SQL query
type: mltable
path:
  sql_query: SELECT * FROM my_table
  datastore: sql_datastore
EOF

az ml data create --file sql-query.yml \
                  --workspace-name <workspace-name> --resource-group <resource-group>
```

## Data Versioning and Lineage Tracking

### Data Versioning

```bash
# Create a new version of an existing data asset
az ml data create --name <data-asset-name> --version 2 \
                  --path azureml://datastores/<datastore-name>/paths/<updated-container-path>/ \
                  --type uri_folder \
                  --workspace-name <workspace-name> --resource-group <resource-group>

# List all versions of a data asset
az ml data list --name <data-asset-name> \
                --workspace-name <workspace-name> --resource-group <resource-group>

# Show a specific version
az ml data show --name <data-asset-name> --version 1 \
                --workspace-name <workspace-name> --resource-group <resource-group>
```

### Lineage Tracking

Lineage tracking is built into Azure ML and can be viewed through the CLI:

```bash
# Get job details including inputs and outputs
az ml job show --name <job-name> \
               --workspace-name <workspace-name> --resource-group <resource-group>

# Get model details including the training job that created it
az ml model show --name <model-name> --version 1 \
                 --workspace-name <workspace-name> --resource-group <resource-group>
```

## Data Drift Detection and Monitoring

### Setting Up Data Drift Monitoring

```bash
# Create a data drift monitor configuration file
cat > data-drift-monitor.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/dataDriftMonitor.schema.json
name: my-data-drift-monitor
target_data_asset:
  name: target-data
  version: 1
baseline_data_asset:
  name: baseline-data
  version: 1
compute:
  instance_type: Standard_DS3_v2
  instance_count: 1
frequency: Day
features_to_monitor:
  - feature1
  - feature2
  - feature3
drift_threshold: 0.3
latency: 1
EOF

# Create the data drift monitor
az ml data-drift-monitor create --file data-drift-monitor.yml \
                                --workspace-name <workspace-name> --resource-group <resource-group>
```

### Checking Data Drift Results

```bash
# List data drift monitors
az ml data-drift-monitor list --workspace-name <workspace-name> --resource-group <resource-group>

# Get data drift monitor details
az ml data-drift-monitor show --name my-data-drift-monitor \
                              --workspace-name <workspace-name> --resource-group <resource-group>

# Get data drift results
az ml data-drift-monitor list-results --name my-data-drift-monitor \
                                      --workspace-name <workspace-name> --resource-group <resource-group>
```

## Feature Stores Implementation

Azure ML integrates with feature stores like Feature Store for Azure Synapse Analytics.

### Setting Up a Feature Store

```bash
# Create a Synapse workspace
az synapse workspace create --name <synapse-workspace-name> --resource-group <resource-group> \
                            --storage-account <storage-account-name> \
                            --file-system <filesystem-name> \
                            --sql-admin-login-user <admin-username> \
                            --sql-admin-login-password <admin-password> \
                            --location <location>

# Create a Spark pool for feature engineering
az synapse spark pool create --name <spark-pool-name> --workspace-name <synapse-workspace-name> \
                             --resource-group <resource-group> --node-count 3 --node-size Medium
```

### Registering Features

```bash
# Create a feature set definition file
cat > feature-set.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/featureSet.schema.json
name: customer_features
version: 1
description: Customer features for churn prediction
entities:
  - name: customer
    description: Customer entity
features:
  - name: age
    description: Customer age
    type: integer
  - name: tenure
    description: Months as a customer
    type: integer
  - name: monthly_charges
    description: Monthly charges
    type: float
materialization:
  type: spark
  path: abfss://<container>@<storage-account>.dfs.core.windows.net/features/customer_features
  spark_config:
    spark.synapse.workspace: <synapse-workspace-name>
    spark.synapse.pool: <spark-pool-name>
EOF

# Register the feature set
az ml feature-set create --file feature-set.yml \
                         --workspace-name <workspace-name> --resource-group <resource-group>
```

## Data Preparation and Transformation

### Creating Data Preparation Pipelines

```bash
# Create a data preparation component
cat > data-prep-component.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/commandComponent.schema.json
name: data_preparation
version: 1
display_name: Data Preparation
type: command
inputs:
  input_data:
    type: uri_folder
outputs:
  output_data:
    type: uri_folder
code: ./src
environment: azureml:data-prep-env:1
command: >-
  python prepare_data.py
  --input-data ${{inputs.input_data}}
  --output-data ${{outputs.output_data}}
EOF

# Create a pipeline that uses the data preparation component
cat > data-pipeline.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/pipelineJob.schema.json
type: pipeline
display_name: Data Preparation Pipeline
jobs:
  prep_data:
    type: command
    component: azureml:data_preparation:1
    inputs:
      input_data:
        path: azureml://datastores/<datastore-name>/paths/<container-path>/
        mode: ro_mount
    outputs:
      output_data:
        mode: rw_mount
compute: azureml:<compute-name>
EOF

# Submit the pipeline
az ml job create --file data-pipeline.yml \
                 --workspace-name <workspace-name> --resource-group <resource-group>
```

## Batch Data Transfer with AzCopy

AzCopy is a command-line utility that provides high-performance data transfer to and from Azure Storage. It's particularly useful for batch operations and large-scale data transfers.

### Installing AzCopy

```bash
# Download AzCopy (Linux)
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/bin/

# Download AzCopy (macOS)
brew install azcopy

# Download AzCopy (Windows PowerShell)
Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile AzCopy.zip
Expand-Archive ./AzCopy.zip ./AzCopy -Force
$PathToAzCopy = Get-ChildItem ./AzCopy/*/azcopy.exe | % {$_.FullName}
# Add to PATH or use the full path
```

### Authentication with AzCopy

```bash
# Login with Microsoft Entra ID (formerly Azure AD)
azcopy login

# Login with SAS token (no need to run login command)
# Just append SAS token to URLs in commands
```

### Batch Upload to Blob Storage

```bash
# Upload a directory and all subdirectories to a container
azcopy copy "/local/path/to/directory" "https://<storage-account-name>.blob.core.windows.net/<container-name>" --recursive

# Upload with pattern matching (only .csv and .parquet files)
azcopy copy "/local/path/to/directory" "https://<storage-account-name>.blob.core.windows.net/<container-name>" --recursive --include-pattern "*.csv;*.parquet"

# Upload with SAS token
azcopy copy "/local/path/to/directory" "https://<storage-account-name>.blob.core.windows.net/<container-name>?<sas-token>" --recursive

# Upload with metadata
azcopy copy "/local/path/to/file.csv" "https://<storage-account-name>.blob.core.windows.net/<container-name>/file.csv" --metadata="project=mlops;dataset=training"

# Upload with blob tags (requires appropriate permissions)
azcopy copy "/local/path/to/file.csv" "https://<storage-account-name>.blob.core.windows.net/<container-name>/file.csv" --blob-tags="project=mlops&dataset=training"
```

### Performance Optimization for Large Transfers

```bash
# Increase concurrency for faster uploads (default is 32 * CPU cores)
export AZCOPY_CONCURRENCY_VALUE=256  # Linux/macOS
set AZCOPY_CONCURRENCY_VALUE=256     # Windows

# Limit bandwidth usage (in Megabits per second)
azcopy copy "/local/path/to/directory" "https://<storage-account-name>.blob.core.windows.net/<container-name>" --recursive --cap-mbps 100

# Run a benchmark test to optimize performance
azcopy benchmark "https://<storage-account-name>.blob.core.windows.net/<container-name>"
```

### Synchronizing Directories

```bash
# Sync local directory to blob container (upload only new or modified files)
azcopy sync "/local/path/to/directory" "https://<storage-account-name>.blob.core.windows.net/<container-name>" --recursive

# Sync and delete files in destination that don't exist in source
azcopy sync "/local/path/to/directory" "https://<storage-account-name>.blob.core.windows.net/<container-name>" --recursive --delete-destination=true
```

## Best Practices for Data Management

### 1. Data Organization

```bash
# Create a structured organization in blob storage
az storage container create --name raw-data --account-name <storage-account-name> --account-key <account-key>
az storage container create --name processed-data --account-name <storage-account-name> --account-key <account-key>
az storage container create --name feature-data --account-name <storage-account-name> --account-key <account-key>
az storage container create --name model-data --account-name <storage-account-name> --account-key <account-key>
```

### 2. Data Access Control

```bash
# Create a user-assigned managed identity
az identity create --name <identity-name> --resource-group <resource-group>

# Assign Storage Blob Data Contributor role to the identity
az role assignment create --assignee-object-id <identity-principal-id> \
                          --assignee-principal-type ServicePrincipal \
                          --role "Storage Blob Data Contributor" \
                          --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>

# Create a datastore using the managed identity
az ml datastore create --name <datastore-name> --type azure_blob \
                       --account-name <storage-account-name> --container-name <container-name> \
                       --identity-type user_assigned --identity-id <identity-id> \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

### 3. Data Validation

```bash
# Create a data validation component
cat > data-validation-component.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/commandComponent.schema.json
name: data_validation
version: 1
display_name: Data Validation
type: command
inputs:
  input_data:
    type: uri_folder
outputs:
  validation_report:
    type: uri_folder
code: ./src
environment: azureml:data-validation-env:1
command: >-
  python validate_data.py
  --input-data ${{inputs.input_data}}
  --validation-report ${{outputs.validation_report}}
EOF

# Add validation to your pipeline
cat > validation-pipeline.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/pipelineJob.schema.json
type: pipeline
display_name: Data Validation Pipeline
jobs:
  validate_data:
    type: command
    component: azureml:data_validation:1
    inputs:
      input_data:
        path: azureml://datastores/<datastore-name>/paths/<container-path>/
        mode: ro_mount
    outputs:
      validation_report:
        mode: rw_mount
compute: azureml:<compute-name>
EOF

# Submit the validation pipeline
az ml job create --file validation-pipeline.yml \
                 --workspace-name <workspace-name> --resource-group <resource-group>
```

## Troubleshooting Data Issues

### Common Data Access Issues

```bash
# Check if a datastore is accessible
az ml datastore show --name <datastore-name> \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# Test datastore connectivity
az ml datastore test-connection --name <datastore-name> \
                                --workspace-name <workspace-name> --resource-group <resource-group>

# Check if a blob exists
az storage blob exists --container-name <container-name> --name <blob-name> \
                       --account-name <storage-account-name> --account-key <account-key>
```

### Data Loading Issues

```bash
# Check data asset details
az ml data show --name <data-asset-name> --version 1 \
                --workspace-name <workspace-name> --resource-group <resource-group>

# Download a sample of the data for inspection
az ml data download --name <data-asset-name> --version 1 --download-path ./sample \
                    --workspace-name <workspace-name> --resource-group <resource-group>
```

## Next Steps

After setting up your data management infrastructure:

1. Explore [Model Development](model-development.md) to learn how to use your data for training models
2. Learn about [MLOps Pipeline Implementation](mlops-pipelines.md) to automate your data workflows
3. Check out [Monitoring and Management](monitoring-management.md) for ongoing data monitoring
