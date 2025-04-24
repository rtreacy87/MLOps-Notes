# Azure Functions for Serverless Processing

This guide covers using Azure Functions for event-driven, serverless processing with a focus on Python and supplementary R support.

## Overview

Azure Functions is a serverless compute service that enables you to run code on-demand without having to explicitly provision or manage infrastructure. It's ideal for:

- Processing data on triggers or schedules
- Building microservices and APIs
- Handling event-driven processing
- Executing short-lived, stateless operations

## Key Concepts

- **Functions**: Individual pieces of code that perform specific tasks
- **Triggers**: Events that cause a function to run (HTTP, timer, blob storage, etc.)
- **Bindings**: Declarative connections to data and services
- **Function App**: Container for functions that share configuration and resources

## Python in Azure Functions

### Setting Up a Python Function App

1. **Prerequisites**:
   - Azure account
   - Azure CLI or Azure Portal
   - Python 3.8+ locally
   - Azure Functions Core Tools

2. **Create a Function App**:
   ```bash
   # Using Azure CLI
   az group create --name myResourceGroup --location eastus
   az storage account create --name mystorageacct --location eastus --resource-group myResourceGroup --sku Standard_LRS
   az functionapp create --resource-group myResourceGroup --consumption-plan-location eastus --runtime python --runtime-version 3.9 --functions-version 4 --name mypythonfunctionapp --storage-account mystorageacct --os-type linux
   ```

3. **Create a Local Function Project**:
   ```bash
   func init MyFunctionProject --python
   cd MyFunctionProject
   func new --name MyHttpTrigger --template "HTTP trigger"
   ```

### Example: HTTP-Triggered Data Processing Function

```python
# __init__.py
import logging
import azure.functions as func
import pandas as pd
import numpy as np
import json
from datetime import datetime

def main(req: func.HttpRequest, outputBlob: func.Out[str]) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        # Get request body
        req_body = req.get_json()
        
        # Convert to DataFrame
        df = pd.DataFrame(req_body['data'])
        
        # Process data
        df['processed_at'] = datetime.now().isoformat()
        df['value_squared'] = df['value'].apply(lambda x: x ** 2)
        
        # Calculate statistics
        stats = {
            'mean': float(df['value'].mean()),
            'median': float(df['value'].median()),
            'std_dev': float(df['value'].std()),
            'count': int(df['value'].count())
        }
        
        # Prepare results
        results = {
            'stats': stats,
            'processed_data': df.to_dict(orient='records')
        }
        
        # Write to blob storage
        outputBlob.set(json.dumps(results))
        
        return func.HttpResponse(
            json.dumps(results),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error processing data: {str(e)}")
        return func.HttpResponse(
            f"Error processing data: {str(e)}",
            status_code=500
        )
```

### Function Configuration (function.json)

```json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    },
    {
      "type": "blob",
      "direction": "out",
      "name": "outputBlob",
      "path": "results/{rand-guid}.json",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

### Dependencies (requirements.txt)

```
azure-functions
pandas
numpy
azure-storage-blob
```

## Integrating with R

While Azure Functions doesn't natively support R, you can use Python as a bridge to execute R code.

### Example: Python Function that Executes R

```python
# __init__.py
import logging
import azure.functions as func
import subprocess
import tempfile
import json
import os

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processing request to execute R code.')
    
    try:
        # Get request body
        req_body = req.get_json()
        input_data = req_body.get('data')
        
        # Create temporary files for input and output
        with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as input_file:
            input_file_path = input_file.name
            json.dump(input_data, input_file)
        
        output_file_path = input_file_path + '_output.json'
        
        # Create R script file
        r_script_path = os.path.join(tempfile.gettempdir(), 'script.R')
        with open(r_script_path, 'w') as r_file:
            r_file.write('''
            # Load libraries
            library(jsonlite)
            library(dplyr)
            
            # Read input data
            input_path <- commandArgs(trailingOnly = TRUE)[1]
            output_path <- commandArgs(trailingOnly = TRUE)[2]
            
            data <- fromJSON(input_path)
            
            # Process data
            results <- data %>%
              mutate(value_squared = value^2) %>%
              mutate(timestamp = Sys.time())
            
            # Calculate statistics
            stats <- list(
              mean = mean(data$value),
              median = median(data$value),
              std_dev = sd(data$value),
              count = length(data$value)
            )
            
            # Prepare output
            output <- list(
              stats = stats,
              processed_data = results
            )
            
            # Write output
            write_json(output, output_path)
            ''')
        
        # Execute R script
        subprocess.run(['Rscript', r_script_path, input_file_path, output_file_path], check=True)
        
        # Read results
        with open(output_file_path, 'r') as output_file:
            results = json.load(output_file)
        
        # Clean up temporary files
        os.unlink(input_file_path)
        os.unlink(output_file_path)
        os.unlink(r_script_path)
        
        return func.HttpResponse(
            json.dumps(results),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error executing R code: {str(e)}")
        return func.HttpResponse(
            f"Error executing R code: {str(e)}",
            status_code=500
        )
```

### Custom Docker Container for R Support

For more complex R integration, create a custom Docker container:

1. **Create a Dockerfile**:
   ```dockerfile
   FROM mcr.microsoft.com/azure-functions/python:4-python3.9
   
   # Install R
   RUN apt-get update && \
       apt-get install -y r-base r-base-dev && \
       apt-get clean
   
   # Install R packages
   RUN R -e "install.packages(c('jsonlite', 'dplyr', 'tidyr'), repos='https://cloud.r-project.org/')"
   
   # Copy function app files
   COPY . /home/site/wwwroot
   
   # Install Python dependencies
   RUN cd /home/site/wwwroot && \
       pip install -r requirements.txt
   ```

2. **Build and Push the Container**:
   ```bash
   docker build -t myregistry.azurecr.io/myrfunctionapp:v1 .
   docker push myregistry.azurecr.io/myrfunctionapp:v1
   ```

3. **Deploy the Container to Azure Functions**:
   ```bash
   az functionapp create --resource-group myResourceGroup --plan myAppServicePlan --name myRFunctionApp --storage-account mystorageacct --deployment-container-image-name myregistry.azurecr.io/myrfunctionapp:v1
   ```

## Best Practices

1. **Keep Functions Focused**: Each function should do one thing well
2. **Optimize Cold Start**: Minimize dependencies and initialization code
3. **Use Durable Functions** for stateful workflows
4. **Implement Error Handling**: Catch and log exceptions properly
5. **Monitor Performance**: Use Application Insights
6. **Secure Secrets**: Use Key Vault for sensitive information

## Common Triggers and Bindings

| Trigger Type | Use Case |
|--------------|----------|
| HTTP | APIs and webhooks |
| Timer | Scheduled tasks |
| Blob Storage | Process files when uploaded |
| Queue Storage | Process messages |
| Event Hub | Process event streams |
| Cosmos DB | React to document changes |

## Next Steps

- [Azure Data Factory/Synapse for Orchestration](azure-data-orchestration.md)
- [Azure Databricks for Spark Processing](azure-databricks-wiki.md)
