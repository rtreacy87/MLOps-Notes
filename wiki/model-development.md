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

Training machine learning models in Azure ML is primarily done through jobs. Jobs are a fundamental concept in Azure ML that allow you to execute code in a controlled, reproducible environment. They provide isolation, dependency management, and the ability to track metrics and artifacts.

### Basic Training Job Submission

To train a model in Azure ML, you'll typically define your training configuration in a YAML file and submit it as a job. This approach offers several advantages:

- **Reproducibility**: The YAML file captures all parameters, data references, and environment settings
- **Version control**: You can track changes to your training configuration over time
- **Automation**: Jobs can be integrated into pipelines and CI/CD workflows

Here's how to submit a training job using the Azure ML CLI:

```bash
# Submit a training job using a YAML configuration file
az ml job create --file train-job.yml --workspace-name myworkspace --resource-group myresourcegroup

# Monitor job progress
az ml job show -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup
```

The first command submits your training job based on the configuration in `train-job.yml`. The second command allows you to check the status of your job and view important details like its state (queued, running, completed) and any outputs or metrics.

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

Experiment tracking is a critical aspect of the ML development process. It helps you organize your work, compare different approaches, and maintain a record of your model development journey. Azure ML provides robust experiment tracking capabilities that allow you to:

- **Track metrics**: Monitor and compare performance metrics across different runs
- **Log parameters**: Record hyperparameters and configuration settings
- **Store artifacts**: Save models, datasets, and other outputs
- **Visualize results**: Create charts and graphs to analyze performance

Effective experiment tracking is essential for reproducibility, collaboration, and model governance. It helps answer questions like "Which model version performed best?" and "What hyperparameters were used for this model?"

### Listing Experiments

Azure ML organizes jobs into experiments, which are logical groupings of related runs. You can use the CLI to list and explore your experiments:

```bash
# List all experiments in a workspace
az ml experiment list --workspace-name myworkspace --resource-group myresourcegroup

# Get details of a specific experiment
az ml experiment show --name myexperiment --workspace-name myworkspace --resource-group myresourcegroup
```

These commands help you navigate your experiment history and find specific runs for further analysis. Regularly reviewing your experiments helps maintain awareness of ongoing work and facilitates knowledge sharing within teams.

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

Hyperparameter optimization (HPO) is the process of finding the best combination of hyperparameters for your machine learning model. Unlike model parameters that are learned during training, hyperparameters are set before training begins and significantly impact model performance.

Azure ML provides powerful hyperparameter tuning capabilities through sweep jobs, which offer several benefits:

- **Automated search**: Efficiently explore the hyperparameter space without manual intervention
- **Parallel execution**: Run multiple training configurations simultaneously
- **Early termination**: Automatically stop underperforming runs to save resources
- **Advanced sampling methods**: Use techniques like Bayesian optimization, random search, or grid search

Effective hyperparameter tuning can dramatically improve model performance and reduce development time. It's particularly valuable when working with complex models that have many hyperparameters.

### Creating a Sweep Job

In Azure ML, hyperparameter optimization is implemented through sweep jobs. A sweep job runs multiple trials with different hyperparameter configurations and tracks their performance to identify the best combination:

```bash
# Submit a hyperparameter tuning job
az ml job create --file sweep-job.yml --workspace-name myworkspace --resource-group myresourcegroup
```

This command submits a sweep job defined in the `sweep-job.yml` file. The YAML file specifies the search space (the hyperparameters to tune and their possible values), the objective metric to optimize, and the sampling strategy to use.

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

Model registration is a crucial step in the ML lifecycle that bridges the gap between experimentation and production. Registering a model in Azure ML's model registry provides several important benefits:

- **Versioning**: Track different versions of your models over time
- **Metadata**: Store important information about the model (metrics, lineage, etc.)
- **Governance**: Implement approval workflows and access controls
- **Deployment tracking**: Monitor which models are deployed to which endpoints
- **Reproducibility**: Maintain a record of how models were created

The model registry serves as a central repository for all your organization's models, making it easier to manage the model lifecycle from development to retirement. It's an essential component of MLOps practices and helps ensure compliance with regulatory requirements.

### Registering a Model

Once you've trained a model that meets your performance criteria, you should register it in the model registry. You can register models from various sources, including job outputs or local files:

```bash
# Register a model from a job output
az ml model create --name mymodel --version 1 --path azureml://jobs/<job-name>/outputs/model --workspace-name myworkspace --resource-group myresourcegroup

# Register a model from a local path
az ml model create --name mymodel --version 1 --path ./model --workspace-name myworkspace --resource-group myresourcegroup
```

When registering a model, consider adding tags and properties to provide additional context. For example, you might include information about the training dataset, the model's performance metrics, or its intended use case. This metadata makes it easier to find and understand models later.

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

Troubleshooting is an inevitable part of ML development. When working with Azure ML jobs, you may encounter various issues related to environments, data access, compute resources, or your training code itself. Effective troubleshooting requires:

- **Access to logs**: Being able to see detailed output from your jobs
- **Systematic approach**: Methodically isolating and addressing issues
- **Understanding of common patterns**: Recognizing typical failure modes

Developing good troubleshooting skills will significantly improve your productivity and reduce frustration when working with ML systems in the cloud.

### Debugging Failed Jobs

When a job fails, the first step is to examine the logs to understand what went wrong. Azure ML provides several ways to access job logs:

```bash
# Stream job logs in real-time (useful for monitoring running jobs)
az ml job stream -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup

# Download all logs for detailed analysis
az ml job download -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup --logs
```

The `job stream` command is particularly useful for real-time monitoring, while the `job download` command allows you to save logs for more thorough analysis. Look for error messages, stack traces, and other indicators of what might have gone wrong.

### Common Issues and Solutions

1. **Environment Issues**:
   - Problem: Missing dependencies or version conflicts in your training environment
   - Solution: Ensure your environment YAML includes all required dependencies with compatible versions
   - Tip: Test your environment locally before running in Azure ML

2. **Data Access Problems**:
   - Problem: Jobs can't access the data they need
   - Solution: Verify data store permissions, mount configurations, and path references
   - Tip: Use the `--debug` flag with data operations to get more detailed error messages

3. **Compute Quota Exceeded**:
   - Problem: You've reached your subscription's limit for certain VM types or cores
   - Solution: Check your subscription quota in the Azure portal and request increases if needed
   - Tip: Consider using different VM types or regions that have available quota

4. **Out of Memory Errors**:
   - Problem: Your job is using more memory than available on the compute
   - Solution: Reduce batch size, optimize memory usage in code, or select a VM with more memory
   - Tip: Monitor memory usage during training to identify memory-intensive operations

## Next Steps

- Learn how to [build MLOps pipelines](mlops-pipelines.md) to automate your model training workflows
- Explore [model deployment options](6.model-deployment.md) to serve your trained models
- Set up [monitoring and management](monitoring-management.md) for your models in production
