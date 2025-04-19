# Cost Management for Azure ML

This guide covers how to optimize resource usage and manage budgets for ML workloads using command-line tools.

## Table of Contents
- [Understanding Azure ML Costs](#understanding-azure-ml-costs)
- [Cost Monitoring and Analysis](#cost-monitoring-and-analysis)
- [Cost Optimization Strategies](#cost-optimization-strategies)
- [Budget Management](#budget-management)
- [Resource Governance](#resource-governance)
- [Cost-Efficient MLOps](#cost-efficient-mlops)

## Understanding Azure ML Costs

Azure ML costs come from several sources:
- **Compute resources**: VMs for training, inference, and notebooks
- **Storage**: Datasets, models, and artifacts
- **Services**: API calls, deployments, and managed services
- **Networking**: Data transfer and private endpoints

### Key Cost Components

| Component | Pricing Model | Cost Drivers |
|-----------|---------------|-------------|
| Compute Instances | Per hour | VM size, uptime |
| Compute Clusters | Per hour | VM size, node count, uptime |
| Managed Endpoints | Per hour + transactions | VM size, node count, uptime, request volume |
| Storage | Per GB | Data volume, retention period |
| Workspace | Base charge | Features enabled |

## Cost Monitoring and Analysis

### Viewing Current Costs

```bash
# Get cost analysis for a resource group
az cost analysis query --scope "subscriptions/{subscription-id}/resourceGroups/myresourcegroup" --dataset-filter "properties/resourceGroup eq 'myresourcegroup'" --timeframe MonthToDate

# Export cost data to CSV
az cost analysis query --scope "subscriptions/{subscription-id}/resourceGroups/myresourcegroup" --dataset-filter "properties/resourceGroup eq 'myresourcegroup'" --timeframe MonthToDate --output csv > ml_costs.csv
```

### Monitoring Resource Usage

```bash
# List compute instances and their status
az ml compute list --type ComputeInstance --workspace-name myworkspace --resource-group myresourcegroup

# List compute clusters and their status
az ml compute list --type AmlCompute --workspace-name myworkspace --resource-group myresourcegroup

# Get details of a specific compute
az ml compute show --name mycompute --workspace-name myworkspace --resource-group myresourcegroup
```

## Cost Optimization Strategies

### Compute Resource Optimization

```bash
# Create a compute cluster with autoscaling
az ml compute create --name training-cluster --type AmlCompute --min-instances 0 --max-instances 4 --size Standard_DS3_v2 --idle-time-before-scale-down 1800 --workspace-name myworkspace --resource-group myresourcegroup

# Update an existing compute cluster to enable autoscaling
az ml compute update --name training-cluster --min-instances 0 --max-instances 4 --idle-time-before-scale-down 1800 --workspace-name myworkspace --resource-group myresourcegroup

# Stop a compute instance when not in use
az ml compute stop --name myinstance --workspace-name myworkspace --resource-group myresourcegroup
```

### Scheduled Compute Management

Create a script to automatically stop idle compute resources:

```bash
#!/bin/bash
# stop-idle-compute.sh

# Get all running compute instances
INSTANCES=$(az ml compute list --type ComputeInstance --workspace-name myworkspace --resource-group myresourcegroup --query "[?provisioningState=='Succeeded' && state=='Running'].[name]" -o tsv)

# Stop each instance
for INSTANCE in $INSTANCES; do
  echo "Stopping compute instance: $INSTANCE"
  az ml compute stop --name $INSTANCE --workspace-name myworkspace --resource-group myresourcegroup
done

# Schedule this script to run daily using cron
# 0 20 * * * /path/to/stop-idle-compute.sh
```

### Storage Optimization

```bash
# List datasets to identify large ones
az ml data list --workspace-name myworkspace --resource-group myresourcegroup

# Archive or delete old datasets
az ml data archive --name old-dataset --version 1 --workspace-name myworkspace --resource-group myresourcegroup

# List models to identify large ones
az ml model list --workspace-name myworkspace --resource-group myresourcegroup

# Archive old model versions
az ml model archive --name mymodel --version 1 --workspace-name myworkspace --resource-group myresourcegroup
```

### Deployment Optimization

```bash
# Create an endpoint with minimal resources
az ml online-endpoint create --file endpoint.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example endpoint YAML with cost optimization:

```yaml
# endpoint.yml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineEndpoint.schema.json
name: cost-optimized-endpoint
auth_mode: key

# deployment.yml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: production
endpoint_name: cost-optimized-endpoint
model: azureml:mymodel:1
instance_type: Standard_DS2_v2  # Smaller instance size
instance_count: 1
min_replica_count: 1
max_replica_count: 3  # Autoscaling for cost efficiency
scale_settings:
  scale_type: default
  min_instances: 1
  max_instances: 3
  polling_interval: 1
  target_utilization_percentage: 70
```

## Budget Management

### Setting Up Budgets

```bash
# Create a budget for ML resources
az consumption budget create --budget-name "ML-Monthly-Budget" \
  --category cost \
  --amount 1000 \
  --time-grain monthly \
  --time-period 2023-01-01/2023-12-31 \
  --scope "subscriptions/{subscription-id}/resourceGroups/myresourcegroup" \
  --meter-filter "['Microsoft.MachineLearningServices']"
```

### Setting Up Cost Alerts

```bash
# Create a cost alert when budget reaches 80%
az consumption budget create --budget-name "ML-Monthly-Budget" \
  --category cost \
  --amount 1000 \
  --time-grain monthly \
  --time-period 2023-01-01/2023-12-31 \
  --scope "subscriptions/{subscription-id}/resourceGroups/myresourcegroup" \
  --meter-filter "['Microsoft.MachineLearningServices']" \
  --notification-type actual \
  --contact-emails "admin@example.com,manager@example.com" \
  --contact-roles "Owner,Contributor" \
  --contact-groups "https://management.azure.com/subscriptions/{subscription-id}/resourceGroups/myresourcegroup/providers/microsoft.insights/actionGroups/costAlertGroup" \
  --notification-threshold 80
```

## Resource Governance

### Resource Quotas and Limits

```bash
# View current quota usage
az vm list-usage --location eastus

# Request quota increase (through Azure portal)
echo "To request a quota increase, go to Azure portal > Subscriptions > Usage + quotas > Request increase"
```

### Resource Tagging for Cost Allocation

```bash
# Tag resources for cost tracking
az ml workspace update --name myworkspace --resource-group myresourcegroup --set tags.CostCenter=ML123 tags.Project=ChurnPrediction

# Tag compute resources
az ml compute update --name training-cluster --workspace-name myworkspace --resource-group myresourcegroup --set tags.CostCenter=ML123 tags.Project=ChurnPrediction

# View costs by tag
az cost analysis query --scope "subscriptions/{subscription-id}" --dataset-filter "properties/resourceGroup eq 'myresourcegroup'" --timeframe MonthToDate --pivot Tag --pivot-type TagKey
```

## Cost-Efficient MLOps

### Optimizing Training Jobs

```bash
# Use low-priority VMs for non-critical training
az ml compute create --name low-priority-cluster --type AmlCompute --min-instances 0 --max-instances 4 --size Standard_DS3_v2 --priority lowpriority --workspace-name myworkspace --resource-group myresourcegroup
```

Example job YAML with cost optimization:

```yaml
# cost-efficient-job.yml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: python train.py --data-path ${{inputs.training_data}} --epochs 50
inputs:
  training_data:
    path: azureml:training-data:1
    mode: ro_mount  # Read-only mount for efficiency
environment: azureml:training-env:1
compute: azureml:low-priority-cluster  # Use low-priority VMs
resources:
  instance_count: 1  # Use minimal resources
experiment_name: cost-efficient-training
```

### Efficient Pipeline Design

```bash
# Create a pipeline that reuses intermediate data
az ml pipeline create --file efficient-pipeline.yml --workspace-name myworkspace --resource-group myresourcegroup
```

Example pipeline YAML with cost optimization:

```yaml
# efficient-pipeline.yml
$schema: https://azuremlschemas.azureedge.net/latest/pipelineJob.schema.json
type: pipeline
display_name: Cost-Efficient Pipeline
jobs:
  data_prep_job:
    component: azureml:data_preparation:1
    compute: azureml:low-priority-cluster
    resources:
      instance_count: 1
    inputs:
      raw_data: 
        path: azureml:raw-data:1
        mode: ro_mount
    outputs:
      prepared_data: 
        mode: rw_mount
  
  train_job:
    component: azureml:model_training:1
    compute: azureml:low-priority-cluster
    resources:
      instance_count: 1
    inputs:
      training_data: ${{jobs.data_prep_job.outputs.prepared_data}}
    outputs:
      model_output:
        mode: rw_mount
```

## Next Steps

- Explore [security best practices](security-practices.md) for ML environments
- Implement [infrastructure as code](11.infrastructure-as-code.md) for your ML resources
- Learn about [Azure ecosystem integration](azure-ecosystem.md) for cost-efficient ML workflows
