# Azure Data Orchestration Services

This guide covers using Azure Data Factory and Azure Synapse Analytics for data orchestration and processing, with a focus on Python integration and supplementary R support.

## Overview of Azure Orchestration Services

| Service | Primary Use Case | Key Features |
|---------|-----------------|--------------|
| **Azure Data Factory** | Data integration and ETL/ELT | Visual pipeline designer, 90+ connectors, serverless |
| **Azure Synapse Analytics** | End-to-end analytics | Combines data integration, warehousing, and analytics |
| **Azure Functions** | Event-driven processing | Serverless, trigger-based, stateless |
| **Azure Databricks** | Big data processing | Apache Spark-based, collaborative notebooks |

## Azure Data Factory (ADF)

Azure Data Factory is a cloud-based data integration service that allows you to create data-driven workflows for orchestrating data movement and transforming data at scale.

### Key Components

- **Pipelines**: Logical groupings of activities that perform a task
- **Activities**: Processing steps in a pipeline (copy data, transform data, control flow)
- **Datasets**: Data structures pointing to data in linked services
- **Linked Services**: Connection strings to data sources
- **Integration Runtime**: Compute infrastructure for activity execution

### Connecting to Data Sources

#### Cloud Data Sources

```python
# Python example using Azure SDK to create a linked service
from azure.mgmt.datafactory import DataFactoryManagementClient
from azure.mgmt.datafactory.models import LinkedServiceResource, AzureBlobStorageLinkedService

# Create Azure Blob Storage linked service
blob_storage_linked_service = LinkedServiceResource(
    properties=AzureBlobStorageLinkedService(
        connection_string="DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=mykey;")
)

adf_client.linked_services.create_or_update(
    resource_group_name="myResourceGroup",
    factory_name="myDataFactory",
    linked_service_name="AzureBlobStorage",
    linked_service=blob_storage_linked_service
)
```

#### On-Premises Data Sources

1. Install and configure Self-hosted Integration Runtime
2. Create linked service using the self-hosted IR
3. Create datasets and pipelines that use the linked service

### Python in ADF

#### Custom Python Activities

1. **Create Python Script**:
```python
# process_data.py
import pandas as pd
import numpy as np
from datetime import datetime

# Log start time
print(f"Processing started at {datetime.now()}")

# Read data
df = pd.read_csv('/path/to/input.csv')

# Transform data
df['processed_column'] = df['raw_column'].apply(lambda x: x.upper())
df['timestamp'] = datetime.now()

# Write results
df.to_csv('/path/to/output.csv', index=False)

print(f"Processing completed at {datetime.now()}")
```

2. **Package Script**:
   - Create a zip file containing your Python script and dependencies
   - Upload to Azure Storage or other accessible location

3. **Create Custom Activity in ADF**:
   - Use the Azure Batch linked service
   - Reference your Python package
   - Configure inputs and outputs

### Monitoring and Alerting

- Use Azure Monitor for pipeline runs
- Set up alerts for failed runs
- Implement custom logging in your scripts

## Azure Synapse Analytics

Azure Synapse Analytics extends ADF capabilities with integrated analytics and additional features.

### Key Components

- **Synapse Pipelines**: Similar to ADF pipelines
- **Synapse Spark**: Apache Spark pools for big data processing
- **Synapse SQL**: SQL pools for data warehousing
- **Synapse Link**: Real-time analytics on operational data
- **Synapse Studio**: Integrated development environment

### Python in Synapse

#### Synapse Spark Notebooks

```python
# Example Synapse Spark notebook
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, udf
from pyspark.sql.types import StringType
import pandas as pd

# Create Spark session
spark = SparkSession.builder.appName("DataProcessing").getOrCreate()

# Read data
df = spark.read.csv("abfss://container@storageaccount.dfs.core.windows.net/path/to/data.csv",
                    header=True, inferSchema=True)

# Transform data
def transform_value(value):
    # Custom transformation logic
    return value.upper() if value else ""

# Register UDF
transform_udf = udf(transform_value, StringType())

# Apply transformation
result_df = df.withColumn("transformed_column", transform_udf(col("original_column")))

# Write results
result_df.write.mode("overwrite").parquet("abfss://container@storageaccount.dfs.core.windows.net/path/to/output/")
```

#### Integrating with R

```r
# Example R code in Synapse Spark
library(SparkR)
library(dplyr)

# Initialize SparkR session
sparkR.session()

# Read data
df <- read.df("abfss://container@storageaccount.dfs.core.windows.net/path/to/data.csv",
              source = "csv", header = "true", inferSchema = "true")

# Transform data
result_df <- df %>%
  mutate(transformed_column = toupper(original_column))

# Write results
write.df(result_df,
         path = "abfss://container@storageaccount.dfs.core.windows.net/path/to/output/",
         source = "parquet", mode = "overwrite")
```

## Infrastructure as Code with Bicep

We use Bicep as our preferred Infrastructure as Code (IaC) tool for deploying Azure Data Factory and Synapse Analytics resources.

### Deploying Azure Data Factory with Bicep

```bicep
@description('The name of the Azure Data Factory')
param dataFactoryName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {}

// Create Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// Create Azure Storage linked service
resource storageLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: 'AzureStorageLinkedService'
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey}'
    }
  }
}

// Create a simple pipeline
resource pipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: 'CopyDataPipeline'
  properties: {
    activities: [
      {
        name: 'CopyFromBlobToBlob'
        type: 'Copy'
        typeProperties: {
          source: {
            type: 'BlobSource'
            recursive: true
          }
          sink: {
            type: 'BlobSink'
            copyBehavior: 'PreserveHierarchy'
          }
        }
        inputs: [
          {
            referenceName: 'InputDataset'
            type: 'DatasetReference'
          }
        ]
        outputs: [
          {
            referenceName: 'OutputDataset'
            type: 'DatasetReference'
          }
        ]
      }
    ]
  }
}

output dataFactoryId string = dataFactory.id
```

### Deploying Azure Synapse Analytics with Bicep

```bicep
@description('The name of the Synapse workspace')
param synapseWorkspaceName string

@description('The name of the SQL admin account')
param sqlAdministratorLogin string

@description('The password for the SQL admin account')
@secure()
param sqlAdministratorPassword string

@description('The name of the storage account')
param storageAccountName string

@description('The name of the storage account container')
param storageAccountContainer string = 'synapse'

@description('Location for all resources')
param location string = resourceGroup().location

// Create Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Create Storage Account container
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storageAccount.name}/default/${storageAccountContainer}'
}

// Create Synapse workspace
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${storageAccountName}.dfs.core.windows.net'
      filesystem: storageAccountContainer
    }
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorPassword
  }
}

// Create Spark Pool
resource sparkPool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  parent: synapseWorkspace
  name: 'sparkpool'
  location: location
  properties: {
    nodeCount: 3
    nodeSizeFamily: 'MemoryOptimized'
    nodeSize: 'Small'
    autoScale: {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 10
    }
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    sparkVersion: '3.1'
  }
}

output synapseWorkspaceId string = synapseWorkspace.id
output sparkPoolId string = sparkPool.id
```

### Deployment Process

1. Save the Bicep files to your project
2. Create parameter files for different environments
3. Deploy using Azure CLI:

```bash
# Deploy Data Factory
az deployment group create \
  --resource-group myResourceGroup \
  --template-file data-factory.bicep \
  --parameters @data-factory.parameters.json

# Deploy Synapse Analytics
az deployment group create \
  --resource-group myResourceGroup \
  --template-file synapse.bicep \
  --parameters @synapse.parameters.json
```

## Next Steps

For more detailed information, see:
- [Azure Functions for Serverless Processing](azure-functions-wiki.md)
- [Azure Databricks for Spark Processing](azure-databricks-wiki.md)
