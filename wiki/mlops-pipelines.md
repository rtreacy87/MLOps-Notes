# MLOps Pipeline Implementation

This guide covers how to build automated ML pipelines and implement CI/CD for your ML workflows using Azure ML.

## Table of Contents
- [Introduction to ML Pipelines](#introduction-to-ml-pipelines)
- [Creating Pipelines with Azure ML CLI](#creating-pipelines-with-azure-ml-cli)
- [CI/CD for ML Workflows](#cicd-for-ml-workflows)
- [Pipeline Versioning and Management](#pipeline-versioning-and-management)
- [Scheduling and Triggers](#scheduling-and-triggers)
- [Best Practices](#best-practices)

## Introduction to ML Pipelines

ML pipelines automate the end-to-end machine learning lifecycle, including:
- Data preparation and validation
- Model training and validation
- Model evaluation
- Model registration and deployment
- Monitoring and retraining

Benefits of using ML pipelines:
- Reproducibility of ML workflows
- Automation of repetitive tasks
- Collaboration between data scientists and engineers
- Easier operationalization of ML models

## Creating Pipelines with Azure ML CLI

### Pipeline Components

Pipeline components are the building blocks of ML pipelines. Each component performs a specific task in the ML workflow.

```bash
# Create a pipeline component from a YAML file
az ml component create --file data-prep-component.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example component YAML:

```yaml
# data-prep-component.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandComponent.schema.json
name: data_preparation
version: 1
display_name: Data Preparation
type: command
inputs:
  raw_data:
    type: uri_folder
outputs:
  prepared_data:
    type: uri_folder
command: >
  python data_prep.py 
  --input-folder ${{inputs.raw_data}} 
  --output-folder ${{outputs.prepared_data}}
environment: azureml:data-prep-env:1
```

### Creating a Pipeline

```bash
# Create a pipeline from a YAML file
az ml pipeline create --file training-pipeline.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example pipeline YAML:

```yaml
# training-pipeline.yml
$schema: https://azuremlschemas.azureedge.net/latest/pipelineJob.schema.json
type: pipeline
display_name: Training Pipeline
jobs:
  data_prep_job:
    component: azureml:data_preparation:1
    inputs:
      raw_data: 
        path: azureml:raw-data:1
        mode: ro_mount
    outputs:
      prepared_data: 
        mode: rw_mount
  
  train_job:
    component: azureml:model_training:1
    inputs:
      training_data: ${{jobs.data_prep_job.outputs.prepared_data}}
    outputs:
      model_output:
        mode: rw_mount
  
  evaluate_job:
    component: azureml:model_evaluation:1
    inputs:
      model: ${{jobs.train_job.outputs.model_output}}
      test_data: 
        path: azureml:test-data:1
        mode: ro_mount
    outputs:
      evaluation_results:
        mode: rw_mount
```

### Running a Pipeline

```bash
# Run a pipeline
az ml job create --file pipeline-run.yml --workspace-name myworkspace --resource-group myresourcegroup

# Monitor pipeline progress
az ml job show -n <job-name> --workspace-name myworkspace --resource-group myresourcegroup
```

## CI/CD for ML Workflows

### Setting Up CI/CD with Azure DevOps

1. Create a YAML pipeline in Azure DevOps:

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - pipelines/**
    - components/**

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
    azureSubscription: 'myAzureServiceConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az ml component create --file components/data-prep-component.yml --workspace-name myworkspace --resource-group myresourcegroup
      az ml component create --file components/train-component.yml --workspace-name myworkspace --resource-group myresourcegroup
      az ml component create --file components/evaluate-component.yml --workspace-name myworkspace --resource-group myresourcegroup
      az ml pipeline create --file pipelines/training-pipeline.yml --workspace-name myworkspace --resource-group myresourcegroup
  displayName: 'Deploy ML Pipeline Components'
```

### Implementing Continuous Training

Set up a pipeline that automatically retrains models when:
- New data is available
- Data drift is detected
- Code changes are pushed to the repository

```bash
# Create a pipeline schedule
az ml schedule create --file pipeline-schedule.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example schedule YAML:

```yaml
# pipeline-schedule.yml
$schema: https://azuremlschemas.azureedge.net/latest/schedule.schema.json
name: weekly_training
display_name: Weekly Model Training
description: Schedule for weekly model retraining
trigger:
  type: recurrence
  frequency: week
  interval: 1
  schedule:
    hours: 2
    minutes: 0
    time_zone: UTC
job: 
  path: training-pipeline.yml
  type: pipeline
```

## Pipeline Versioning and Management

### Versioning Pipeline Components

```bash
# Create a new version of a component
az ml component create --file updated-data-prep-component.yml --workspace-name myworkspace --resource-group myresourcegroup
```

### Managing Pipeline Versions

```bash
# List all versions of a pipeline
az ml pipeline list --name training-pipeline --workspace-name myworkspace --resource-group myresourcegroup

# Show details of a specific pipeline version
az ml pipeline show --name training-pipeline --version 2 --workspace-name myworkspace --resource-group myresourcegroup
```

## Scheduling and Triggers

### Data-Driven Triggers

Set up pipelines to run when new data arrives:

```yaml
# data-driven-schedule.yml
$schema: https://azuremlschemas.azureedge.net/latest/schedule.schema.json
name: data_driven_training
display_name: Data-Driven Training
description: Schedule triggered by new data
trigger:
  type: data
  data_inputs:
    input_dataset:
      data_input_type: datastore_path
      path_on_datastore: raw-data/
      datastore: workspaceblobstore
job: 
  path: training-pipeline.yml
  type: pipeline
```

### Manual Triggers

```bash
# Manually trigger a pipeline run
az ml job create --file pipeline-run.yml --workspace-name myworkspace --resource-group myresourcegroup
```

## Best Practices

1. **Modular Components**: Design reusable components that perform specific tasks
2. **Parameterization**: Make pipelines flexible with parameters
3. **Error Handling**: Implement robust error handling in pipeline components
4. **Logging**: Add comprehensive logging for debugging and monitoring
5. **Testing**: Test pipeline components individually before integrating
6. **Documentation**: Document pipeline components, inputs, outputs, and dependencies
7. **Version Control**: Keep pipeline definitions in version control
8. **Environment Management**: Use consistent environments across pipeline components

## Next Steps

- Learn about [model deployment and serving](6.model-deployment.md)
- Explore [monitoring and management](monitoring-management.md) for your ML systems
- Implement [governance and compliance](governance-compliance.md) for your ML workflows
