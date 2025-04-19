# Daily MLOps Workflows on Azure

This guide covers common day-to-day tasks for MLOps engineers working with Azure Machine Learning. All workflows are presented with command-line instructions to help you automate and script your daily activities.

## Morning Routine: Environment and Resource Check

Start your day by checking the status of your ML resources:

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription <subscription-id>

# Check compute resources status
az ml compute list --workspace-name <workspace-name> --resource-group <resource-group> --query "[].{Name:name, State:provisioningState}" -o table

# Check running jobs
az ml job list --workspace-name <workspace-name> --resource-group <resource-group> --query "[?status=='Running']" -o table

# Check endpoint health
az ml online-endpoint list --workspace-name <workspace-name> --resource-group <resource-group> --query "[].{Name:name, ProvisioningState:provisioningState}" -o table
```

## Data Management Workflows

### Syncing New Data to Azure Storage

```bash
# Upload new data files to blob storage
az storage blob upload-batch --account-name <storage-account> --auth-mode key \
                             --account-key <storage-key> --destination <container-name> \
                             --source <local-folder-path> --pattern "*.csv"

# Register or update a data asset
az ml data create --name <dataset-name> --version <version> \
                  --path azureml://datastores/<datastore-name>/paths/<container-path>/ \
                  --type uri_folder --workspace-name <workspace-name> --resource-group <resource-group>
```

### Checking for Data Drift

```bash
# Run a data drift detection job
az ml job create --file data-drift-job.yml --workspace-name <workspace-name> --resource-group <resource-group>

# Check the results
az ml job show --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

## Model Training Workflows

### Starting a Training Run

```bash
# Create a training job YAML file
cat > train-job.yml << EOF
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
command: python train.py --data \${{inputs.training_data}} --learning_rate 0.01
inputs:
  training_data:
    path: azureml://datastores/<datastore-name>/paths/<data-path>/
    mode: ro_mount
environment: azureml:<environment-name>:<version>
compute: azureml:<compute-name>
experiment_name: daily-training
display_name: model-training-run
EOF

# Submit the training job
az ml job create --file train-job.yml --workspace-name <workspace-name> --resource-group <resource-group>
```

### Monitoring Training Progress

```bash
# Stream logs from a running job
az ml job stream --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Check metrics from a completed job
az ml job show --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group> --query "metrics"
```

### Registering a Trained Model

```bash
# Register the model from a completed job
az ml model create --name <model-name> --version <version> \
                   --path azureml://jobs/<job-name>/outputs/model/ \
                   --workspace-name <workspace-name> --resource-group <resource-group>
```

## Model Deployment Workflows

### Deploying a Model to an Endpoint

```bash
# Create or update a deployment YAML file
cat > deployment.yml << EOF
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
name: <deployment-name>
endpoint_name: <endpoint-name>
model: azureml:<model-name>:<version>
environment: azureml:<environment-name>:<version>
instance_type: Standard_DS3_v2
instance_count: 1
EOF

# Create the deployment
az ml online-deployment create --file deployment.yml \
                               --workspace-name <workspace-name> --resource-group <resource-group>

# Allocate traffic to the deployment
az ml online-endpoint update --name <endpoint-name> \
                             --traffic "<deployment-name>=100" \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

### Testing a Deployed Endpoint

```bash
# Create a sample request file
echo '{"data": [[1,2,3,4,5]]}' > sample-request.json

# Test the endpoint
az ml online-endpoint invoke --name <endpoint-name> --request-file sample-request.json \
                             --workspace-name <workspace-name> --resource-group <resource-group>
```

## Pipeline Automation Workflows

### Running a Scheduled Pipeline

```bash
# Create a pipeline job
az ml pipeline job create --name <pipeline-job-name> --pipeline-name <pipeline-name> \
                          --workspace-name <workspace-name> --resource-group <resource-group>
```

### Checking Pipeline Status

```bash
# List recent pipeline runs
az ml pipeline job list --workspace-name <workspace-name> --resource-group <resource-group> --max-results 5

# Get details of a specific pipeline run
az ml pipeline job show --name <pipeline-job-name> \
                        --workspace-name <workspace-name> --resource-group <resource-group>
```

## Monitoring and Maintenance Workflows

### Checking Model Performance

```bash
# Run a model evaluation job
az ml job create --file model-eval-job.yml --workspace-name <workspace-name> --resource-group <resource-group>

# Check the results
az ml job show --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

### Resource Cleanup

```bash
# List old jobs (completed more than 30 days ago)
az ml job list --workspace-name <workspace-name> --resource-group <resource-group> \
               --created-before "$(date -d '30 days ago' +'%Y-%m-%d')" --query "[].name" -o tsv

# Delete old jobs
for job in $(az ml job list --workspace-name <workspace-name> --resource-group <resource-group> \
                            --created-before "$(date -d '30 days ago' +'%Y-%m-%d')" --query "[].name" -o tsv); do
    az ml job delete --name $job --workspace-name <workspace-name> --resource-group <resource-group> --yes
done

# Stop unused compute instances
az ml compute stop --name <compute-instance-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

## Troubleshooting Common Issues

### Diagnosing Failed Jobs

```bash
# Get detailed error information for a failed job
az ml job show --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group> --query "status_details"

# Download job logs for detailed analysis
az ml job download --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group> --outputs --logs
```

### Fixing Endpoint Issues

```bash
# Check deployment logs
az ml online-deployment get-logs --name <deployment-name> --endpoint-name <endpoint-name> \
                                 --workspace-name <workspace-name> --resource-group <resource-group>

# Update a failing deployment
az ml online-deployment update --name <deployment-name> --endpoint-name <endpoint-name> \
                               --environment azureml:<environment-name>:<version> \
                               --workspace-name <workspace-name> --resource-group <resource-group>
```

## End of Day Routine

```bash
# Check for any failed jobs during the day
az ml job list --workspace-name <workspace-name> --resource-group <resource-group> \
               --created-after "$(date +'%Y-%m-%d')" --query "[?status=='Failed']" -o table

# Ensure compute resources are scaled down or stopped
az ml compute list --workspace-name <workspace-name> --resource-group <resource-group> \
                   --query "[?type=='AmlCompute'].{Name:name, CurrentNodeCount:properties.currentNodeCount}" -o table

# Stop development compute instances if not needed overnight
az ml compute stop --name <compute-instance-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

## Scripting These Workflows

For efficiency, consider creating shell scripts for these common workflows:

```bash
# Example: Create a script for morning routine
cat > morning-check.sh << 'EOF'
#!/bin/bash
WORKSPACE="<workspace-name>"
RESOURCE_GROUP="<resource-group>"

echo "Checking compute resources..."
az ml compute list --workspace-name $WORKSPACE --resource-group $RESOURCE_GROUP \
                   --query "[].{Name:name, State:provisioningState}" -o table

echo "Checking running jobs..."
az ml job list --workspace-name $WORKSPACE --resource-group $RESOURCE_GROUP \
               --query "[?status=='Running']" -o table

echo "Checking endpoint health..."
az ml online-endpoint list --workspace-name $WORKSPACE --resource-group $RESOURCE_GROUP \
                           --query "[].{Name:name, ProvisioningState:provisioningState}" -o table
EOF

chmod +x morning-check.sh
```

By automating these workflows with scripts, you can significantly improve your productivity as an MLOps engineer.
