# Azure ML CLI Commands Cheat Sheet

This cheat sheet provides a quick reference for common Azure ML CLI commands that MLOps engineers use in their daily workflows. The Azure ML CLI is a powerful tool that allows you to manage all aspects of your Azure Machine Learning resources from the command line, enabling automation, scripting, and integration with CI/CD pipelines.

## Why Use the Azure ML CLI?

The Azure ML CLI offers several advantages over the web portal:

- **Automation**: Incorporate ML workflows into scripts and pipelines
- **Version control**: Store configuration as code in your repository
- **Reproducibility**: Ensure consistent environment setup and job execution
- **Efficiency**: Perform batch operations and complex workflows quickly
- **Integration**: Work seamlessly with other DevOps tools and processes

Mastering these commands will significantly improve your productivity as an MLOps engineer and enable more robust, repeatable ML workflows.

## Installation and Setup

Before you can use the Azure ML CLI, you need to install and configure it properly. These commands will help you get started:

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Ubuntu/Debian
brew install azure-cli  # macOS

# Install Azure ML extension
az extension add -n ml

# Login to Azure
az login

# Set default subscription
az account set --subscription <subscription-id>
```

After running these commands, verify your installation with `az ml -h` to ensure the ML extension is properly installed. It's also a good practice to keep your CLI and extensions updated with `az upgrade` and `az extension update -n ml`.

## Workspace Management

The Azure ML workspace is the foundational resource that contains all other Azure ML assets. It serves as a central place to work with all the artifacts you create and provides a collaboration space for data scientists and MLOps engineers. Proper workspace management is essential for organizing your ML projects and controlling access to resources.

```bash
# Create a new workspace
# This is typically one of the first commands you'll run when setting up a new ML project
az ml workspace create --name <workspace-name> --resource-group <resource-group>

# List all workspaces in a resource group
# Useful when you need to find available workspaces or verify workspace creation
az ml workspace list --resource-group <resource-group>

# Show detailed information about a specific workspace
# Use this to check workspace properties, endpoints, and linked services
az ml workspace show --name <workspace-name> --resource-group <resource-group>

# Delete a workspace when it's no longer needed
# CAUTION: This will delete ALL resources in the workspace including compute, models, and datasets
az ml workspace delete --name <workspace-name> --resource-group <resource-group>
```

Best practices for workspace management include:
- Create separate workspaces for different projects or teams
- Use consistent naming conventions for workspaces
- Apply appropriate RBAC (Role-Based Access Control) to workspaces
- Consider workspace-level quotas and limits when planning your ML infrastructure

## Compute Management

Compute resources are essential for training models and deploying endpoints in Azure ML. There are two main types of compute resources:

1. **Compute Clusters**: Scalable clusters for training and batch inference that can automatically scale up and down based on workload
2. **Compute Instances**: Development VMs for interactive notebook experiences and experimentation

Efficient compute management is critical for controlling costs and ensuring resources are available when needed. The following commands help you manage your compute resources effectively:

```bash
# Create a compute cluster for training jobs
# The min-nodes and max-nodes parameters enable autoscaling to control costs
az ml compute create --name <compute-name> --type amlcompute --min-nodes 0 --max-nodes 4 \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# Create a compute instance for development work
# Choose an appropriate VM size based on your workload requirements
az ml compute create --name <instance-name> --type computeinstance --size Standard_DS3_v2 \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# List all compute resources in a workspace
# Use this to check what resources are available and their current state
az ml compute list --workspace-name <workspace-name> --resource-group <resource-group>

# Start a compute instance when you need to use it
# Compute instances should be stopped when not in use to avoid unnecessary charges
az ml compute start --name <instance-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Stop a compute instance when you're done using it
# This is important for cost management as compute instances incur charges when running
az ml compute stop --name <instance-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Delete a compute resource when it's no longer needed
# Use with caution as this permanently removes the compute resource
az ml compute delete --name <compute-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

Best practices for compute management:
- Set min-nodes to 0 for training clusters to avoid charges when not in use
- Use appropriate VM sizes for your workloads (GPU for deep learning, CPU for traditional ML)
- Implement automated shutdown of compute instances during non-working hours
- Monitor compute usage and costs regularly to optimize resource allocation

## Data Management

```bash
# Create datastore
az ml datastore create --name <datastore-name> --type azure_blob --account-name <storage-account> \
                       --container-name <container> --workspace-name <workspace-name> \
                       --resource-group <resource-group>

# List datastores
az ml datastore list --workspace-name <workspace-name> --resource-group <resource-group>

# Create data asset
az ml data create --name <data-name> --version 1 --path <path-to-data> \
                  --type uri_file --workspace-name <workspace-name> --resource-group <resource-group>

# List data assets
az ml data list --workspace-name <workspace-name> --resource-group <resource-group>
```

## Model Management

```bash
# Register model
az ml model create --name <model-name> --version 1 --path <path-to-model> \
                   --workspace-name <workspace-name> --resource-group <resource-group>

# List models
az ml model list --workspace-name <workspace-name> --resource-group <resource-group>

# Show model details
az ml model show --name <model-name> --version 1 \
                 --workspace-name <workspace-name> --resource-group <resource-group>

# Download model
az ml model download --name <model-name> --version 1 --download-path <local-path> \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# Delete model
az ml model delete --name <model-name> --version 1 \
                   --workspace-name <workspace-name> --resource-group <resource-group>
```

## Environment Management

```bash
# Create environment from conda file
az ml environment create --name <env-name> --version 1 --conda-file <path-to-conda-file> \
                         --workspace-name <workspace-name> --resource-group <resource-group>

# List environments
az ml environment list --workspace-name <workspace-name> --resource-group <resource-group>

# Show environment details
az ml environment show --name <env-name> --version 1 \
                       --workspace-name <workspace-name> --resource-group <resource-group>
```

## Job Management

```bash
# Submit a command job
az ml job create --file job.yml --workspace-name <workspace-name> --resource-group <resource-group>

# List jobs
az ml job list --workspace-name <workspace-name> --resource-group <resource-group>

# Show job details
az ml job show --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Stream job logs
az ml job stream --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>

# Cancel job
az ml job cancel --name <job-name> --workspace-name <workspace-name> --resource-group <resource-group>
```

## Endpoint Management

```bash
# Create online endpoint
az ml online-endpoint create --name <endpoint-name> \
                             --workspace-name <workspace-name> --resource-group <resource-group>

# Create online deployment
az ml online-deployment create --name <deployment-name> --endpoint-name <endpoint-name> \
                               --model-name <model-name> --model-version 1 \
                               --workspace-name <workspace-name> --resource-group <resource-group>

# List endpoints
az ml online-endpoint list --workspace-name <workspace-name> --resource-group <resource-group>

# Get endpoint details
az ml online-endpoint show --name <endpoint-name> \
                           --workspace-name <workspace-name> --resource-group <resource-group>

# Invoke endpoint
az ml online-endpoint invoke --name <endpoint-name> --request-file <input-data-file> \
                             --workspace-name <workspace-name> --resource-group <resource-group>

# Delete endpoint
az ml online-endpoint delete --name <endpoint-name> \
                             --workspace-name <workspace-name> --resource-group <resource-group> --yes
```

## Pipeline Management

```bash
# Create pipeline
az ml pipeline create --file pipeline.yml \
                      --workspace-name <workspace-name> --resource-group <resource-group>

# List pipelines
az ml pipeline list --workspace-name <workspace-name> --resource-group <resource-group>

# Show pipeline details
az ml pipeline show --name <pipeline-name> \
                    --workspace-name <workspace-name> --resource-group <resource-group>

# Create pipeline job
az ml pipeline job create --name <job-name> --pipeline-name <pipeline-name> \
                          --workspace-name <workspace-name> --resource-group <resource-group>
```

## Asset Export/Import

```bash
# Export model
az ml model export --name <model-name> --version 1 --output-path <local-path> \
                   --workspace-name <workspace-name> --resource-group <resource-group>

# Import model
az ml model import --file <model-metadata-file> \
                   --workspace-name <workspace-name> --resource-group <resource-group>
```
