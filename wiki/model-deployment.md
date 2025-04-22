# Model Deployment and Serving on Azure ML

This guide covers the command-line approaches for deploying machine learning models on Azure ML and implementing various serving patterns.

## Deployment Options Overview

Azure ML offers several deployment targets for your models:

1. **Azure Container Instances (ACI)** - Good for development, testing, or low-scale deployments
2. **Azure Kubernetes Service (AKS)** - Ideal for production deployments requiring scalability and high availability
3. **Azure Functions** - Suitable for event-driven, serverless inference
4. **Azure IoT Edge** - For deploying models to edge devices

## Prerequisites

Before deploying a model, ensure you have:

- A registered model in your Azure ML workspace
- A scoring script (usually named `score.py`)
- An environment definition with required dependencies

## Preparing for Deployment

### 1. Create a Scoring Script

The scoring script defines how your model loads and makes predictions. Create a file named `score.py`:

```bash
cat > score.py << 'EOF'
import os
import json
import numpy as np
import joblib
from azureml.core.model import Model

def init():
    global model
    model_path = os.path.join(os.getenv('AZUREML_MODEL_DIR'), 'model.pkl')
    model = joblib.load(model_path)

def run(raw_data):
    try:
        data = json.loads(raw_data)['data']
        data = np.array(data)
        result = model.predict(data)
        return json.dumps({"result": result.tolist()})
    except Exception as e:
        return json.dumps({"error": str(e)})
EOF
```

### 2. Define an Environment

Create an environment YAML file:

```bash
cat > environment.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/environment.schema.json
name: model-deploy-env
version: 1
conda_file:
  channels:
    - conda-forge
  dependencies:
    - python=3.8
    - pip=21.3.1
    - pip:
      - azureml-defaults>=1.48.0
      - scikit-learn==1.0.2
      - joblib==1.1.0
      - numpy==1.22.3
      - inference-schema[numpy-support]
EOF
```

Register the environment:

```bash
az ml environment create --file environment.yml \
                         --workspace-name <workspace-name> --resource-group <resource-group>
```

## Deploying to Azure Container Instances (ACI)

### 1. Create an Online Endpoint

```bash
cat > endpoint.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
name: my-endpoint
auth_mode: key
EOF

az ml online-endpoint create --file endpoint.yml \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

### 2. Create an ACI Deployment

```bash
cat > aci-deployment.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: aci-deployment
endpoint_name: my-endpoint
model:
  name: <model-name>
  version: <model-version>
environment: 
  name: model-deploy-env
  version: 1
code_configuration:
  code: ./
  scoring_script: score.py
instance_type: Standard_DS2_v2
instance_count: 1
EOF

az ml online-deployment create --file aci-deployment.yml \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

### 3. Allocate Traffic to the Deployment

```bash
az ml online-endpoint update --name my-endpoint --traffic "aci-deployment=100" \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

### 4. Test the Endpoint

```bash
# Create a sample request file
echo '{"data": [[1,2,3,4,5]]}' > sample-request.json

# Test the endpoint
az ml online-endpoint invoke --name my-endpoint --request-file sample-request.json \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

## Deploying to Azure Kubernetes Service (AKS)

### 1. Create an AKS Compute Target (if not already available)

```bash
az ml compute create --name aks-cluster --type amlcompute --size Standard_DS3_v2 \
                     --min-instances 1 --max-instances 3 \
                     --workspace-name <workspace-name> --resource-group <resource-group>
```

### 2. Create an Online Endpoint (if not already created)

```bash
az ml online-endpoint create --name my-endpoint \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

### 3. Create an AKS Deployment

```bash
cat > aks-deployment.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: aks-deployment
endpoint_name: my-endpoint
model:
  name: <model-name>
  version: <model-version>
environment: 
  name: model-deploy-env
  version: 1
code_configuration:
  code: ./
  scoring_script: score.py
instance_type: Standard_DS3_v2
instance_count: 1
request_settings:
  request_timeout_ms: 3000
  max_concurrent_requests_per_instance: 1
  max_queue_wait_ms: 3000
scale_settings:
  scale_type: Default
  min_instances: 1
  max_instances: 5
  scale_rule:
    metric_name: ConcurrentRequests
    metric_threshold: 10
EOF

az ml online-deployment create --file aks-deployment.yml \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

### 4. Update Traffic Allocation

```bash
az ml online-endpoint update --name my-endpoint --traffic "aks-deployment=100" \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

## Real-time vs. Batch Inference Patterns

### Real-time Inference (already covered above)

Real-time inference is used when you need immediate predictions for individual requests.

### Batch Inference

Batch inference is used when you need to process a large number of predictions at once.

#### 1. Create a Batch Endpoint

```bash
cat > batch-endpoint.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/batchEndpoint.schema.json
name: batch-endpoint
description: Endpoint for batch predictions
EOF

az ml batch-endpoint create --file batch-endpoint.yml \
                            --workspace-name <workspace-name> --resource-group <resource-group>
```

#### 2. Create a Batch Deployment

```bash
cat > batch-deployment.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/batchDeployment.schema.json
name: batch-deployment
endpoint_name: batch-endpoint
model:
  name: <model-name>
  version: <model-version>
environment: 
  name: model-deploy-env
  version: 1
code_configuration:
  code: ./
  scoring_script: batch_score.py
compute: azureml:<compute-name>
resources:
  instance_count: 2
max_concurrency_per_instance: 2
mini_batch_size: 10
output_action: append_row
output_file_name: predictions.csv
retry_settings:
  max_retries: 3
  timeout: 300
error_threshold: 10
logging_level: info
EOF

az ml batch-deployment create --file batch-deployment.yml \
                              --workspace-name <workspace-name> --resource-group <resource-group>
```

#### 3. Set the Default Deployment

```bash
az ml batch-endpoint update --name batch-endpoint --set defaults.deployment_name=batch-deployment \
                            --workspace-name <workspace-name> --resource-group <resource-group>
```

#### 4. Invoke the Batch Endpoint

```bash
az ml batch-endpoint invoke --name batch-endpoint \
                            --input azureml:<input-data-asset-name>:<version> \
                            --workspace-name <workspace-name> --resource-group <resource-group>
```

## Scaling Strategies for Model Serving

### Manual Scaling

Adjust the instance count for a deployment:

```bash
az ml online-deployment update --name <deployment-name> --endpoint-name <endpoint-name> \
                               --instance-count 3 \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

### Autoscaling

Configure autoscaling in your deployment YAML:

```bash
cat > autoscale-deployment.yml << 'EOF'
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: autoscale-deployment
endpoint_name: my-endpoint
model:
  name: <model-name>
  version: <model-version>
environment: 
  name: model-deploy-env
  version: 1
code_configuration:
  code: ./
  scoring_script: score.py
instance_type: Standard_DS3_v2
instance_count: 1
scale_settings:
  scale_type: Default
  min_instances: 1
  max_instances: 10
  scale_rule:
    metric_name: ConcurrentRequests
    metric_threshold: 5
EOF

az ml online-deployment create --file autoscale-deployment.yml \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

## Blue/Green and Canary Deployment Strategies

### Blue/Green Deployment

1. Create a new "green" deployment alongside the existing "blue" one:

```bash
az ml online-deployment create --file green-deployment.yml \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

2. Test the "green" deployment:

```bash
az ml online-endpoint invoke --name <endpoint-name> --deployment-name green-deployment \
                             --request-file sample-request.json \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

3. Switch traffic from "blue" to "green":

```bash
az ml online-endpoint update --name <endpoint-name> --traffic "green-deployment=100" \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

### Canary Deployment

1. Create a new deployment:

```bash
az ml online-deployment create --file canary-deployment.yml \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

2. Allocate a small percentage of traffic to the canary:

```bash
az ml online-endpoint update --name <endpoint-name> \
                             --traffic "production-deployment=90 canary-deployment=10" \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

3. Gradually increase traffic to the canary:

```bash
az ml online-endpoint update --name <endpoint-name> \
                             --traffic "production-deployment=50 canary-deployment=50" \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

4. Complete the transition:

```bash
az ml online-endpoint update --name <endpoint-name> \
                             --traffic "canary-deployment=100" \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

## Monitoring Deployed Models

### Get Deployment Logs

```bash
az ml online-deployment get-logs --name <deployment-name> --endpoint-name <endpoint-name> \
                                 --workspace-name <workspace-name> --resource-group <resource-group>
```

### Check Endpoint Health

```bash
az ml online-endpoint show --name <endpoint-name> \
                           --workspace-name <workspace-name> --resource-group <resource-group>
```

### Monitor Metrics

```bash
# Get metrics for a deployment
az monitor metrics list --resource-id "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.MachineLearningServices/workspaces/<workspace-name>/onlineEndpoints/<endpoint-name>/deployments/<deployment-name>" \
                        --metric "RequestsPerSecond" \
                        --interval PT1M
```

## Troubleshooting Deployments

### Common Issues and Solutions

1. **Deployment Fails to Start**:

```bash
# Check deployment logs
az ml online-deployment get-logs --name <deployment-name> --endpoint-name <endpoint-name> \
                                 --workspace-name <workspace-name> --resource-group <resource-group>

# Verify environment dependencies
az ml environment show --name <environment-name> --version <version> \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

2. **Scoring Script Errors**:

```bash
# Test your scoring script locally before deployment
python -c "import score; score.init(); print(score.run('{\"data\": [[1,2,3,4,5]]}'))"
```

3. **Endpoint Not Responding**:

```bash
# Check endpoint status
az ml online-endpoint show --name <endpoint-name> \
                           --workspace-name <workspace-name> --resource-group <resource-group>

# Restart the deployment
az ml online-deployment update --name <deployment-name> --endpoint-name <endpoint-name> \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

## Cleaning Up Resources

```bash
# Delete a deployment
az ml online-deployment delete --name <deployment-name> --endpoint-name <endpoint-name> \
                               --workspace-name <workspace-name> --resource-group <resource-group> --yes

# Delete an endpoint (and all its deployments)
az ml online-endpoint delete --name <endpoint-name> \
                             --workspace-name <workspace-name> --resource-group <resource-group> --yes
```

## Next Steps

After successfully deploying your model, consider:

1. Setting up [Model Monitoring and Management](monitoring-management.md)
2. Implementing [MLOps Pipeline Implementation](mlops-pipelines.md) for automated deployments
3. Exploring [Governance and Compliance](governance-compliance.md) for your ML models
