# Model Development with Azure ML CLI

This guide covers command-line techniques for training models, tracking experiments, and optimizing hyperparameters using Azure ML CLI.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Training Models with the CLI](#training-models-with-the-cli)
- [Experiment Tracking](#experiment-tracking)
- [Hyperparameter Optimization](#hyperparameter-optimization)
- [Model Registration](#model-registration)
- [Common Troubleshooting](#common-troubleshooting)

## Prerequisites

Before you begin, ensure you have:
- Azure ML workspace configured
- Azure ML CLI extension installed
- Training scripts and data prepared

## Training Models with the CLI

### Basic Training Job Submission

```bash
# Submit a training job using a YAML configuration file
az ml job create --file train-job.yml --workspace-name myworkspace --resource-group myresourcegroup

# Monitor job progress
az ml job show -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup
```

### Example YAML Configuration

```yaml
# train-job.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: >
  python train.py 
  --data-path ${{inputs.training_data}}
  --learning-rate 0.01
  --epochs 50
inputs:
  training_data:
    path: azureml:training-data:1
    mode: ro_mount
environment: azureml:training-env:1
compute: azureml:gpu-cluster
experiment_name: model-training-experiment
description: Training job for classification model
```

## Experiment Tracking

### Listing Experiments

```bash
# List all experiments in a workspace
az ml experiment list --workspace-name myworkspace --resource-group myresourcegroup

# Get details of a specific experiment
az ml experiment show --name myexperiment --workspace-name myworkspace --resource-group myresourcegroup
```

### Tracking Metrics

In your training script, use the MLflow tracking API to log metrics:

```python
import mlflow

# Log metrics
mlflow.log_metric("accuracy", 0.85)
mlflow.log_metric("loss", 0.35)

# Log parameters
mlflow.log_param("learning_rate", 0.01)
mlflow.log_param("batch_size", 32)

# Log model
mlflow.sklearn.log_model(model, "model")
```

### Viewing Experiment Results

```bash
# Get the metrics from a run
az ml job show -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup --query metrics

# Download job outputs
az ml job download -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup --output-path ./outputs
```

## Hyperparameter Optimization

### Creating a Sweep Job

```bash
# Submit a hyperparameter tuning job
az ml job create --file sweep-job.yml --workspace-name myworkspace --resource-group myresourcegroup
```

### Example Sweep Job YAML

```yaml
# sweep-job.yml
$schema: https://azuremlschemas.azureedge.net/latest/sweepJob.schema.json
type: sweep
trial:
  command: >
    python train.py 
    --learning-rate ${{search_space.learning_rate}} 
    --batch-size ${{search_space.batch_size}}
  environment: azureml:training-env:1
  compute: azureml:gpu-cluster
search_space:
  learning_rate:
    type: uniform
    min_value: 0.001
    max_value: 0.1
  batch_size:
    type: choice
    values: [16, 32, 64, 128]
objective:
  primary_metric: accuracy
  goal: maximize
limits:
  max_total_trials: 20
  max_concurrent_trials: 4
  timeout: 7200
```

## Model Registration

### Registering a Model

```bash
# Register a model from a job output
az ml model create --name mymodel --version 1 --path azureml://jobs/<job-name>/outputs/model --workspace-name myworkspace --resource-group myresourcegroup

# Register a model from a local path
az ml model create --name mymodel --version 1 --path ./model --workspace-name myworkspace --resource-group myresourcegroup
```

### Listing and Managing Models

```bash
# List all models
az ml model list --workspace-name myworkspace --resource-group myresourcegroup

# Show model details
az ml model show --name mymodel --version 1 --workspace-name myworkspace --resource-group myresourcegroup

# Archive a model version
az ml model archive --name mymodel --version 1 --workspace-name myworkspace --resource-group myresourcegroup
```

## Common Troubleshooting

### Debugging Failed Jobs

```bash
# Get job logs
az ml job stream -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup

# Download all logs
az ml job download -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup --logs
```

### Common Issues and Solutions

1. **Environment Issues**: Ensure your environment YAML includes all required dependencies
2. **Data Access Problems**: Verify data store permissions and mount configurations
3. **Compute Quota Exceeded**: Check your subscription quota and request increases if needed
4. **Out of Memory Errors**: Reduce batch size or select a VM with more memory

## Next Steps

- Learn how to [build MLOps pipelines](mlops-pipelines.md) to automate your model training workflows
- Explore [model deployment options](6.model-deployment.md) to serve your trained models
- Set up [monitoring and management](monitoring-management.md) for your models in production
