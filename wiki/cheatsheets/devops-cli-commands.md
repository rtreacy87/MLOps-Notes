# Azure DevOps CLI Commands Cheatsheet

This cheatsheet provides a quick reference for Azure DevOps CLI commands commonly used in MLOps workflows.

## Table of Contents
- [Installation and Setup](#installation-and-setup)
- [Organization and Project Management](#organization-and-project-management)
- [Repositories](#repositories)
- [Pipelines](#pipelines)
- [Artifacts](#artifacts)
- [Work Items](#work-items)
- [Service Connections](#service-connections)
- [Variable Groups](#variable-groups)
- [Extensions](#extensions)

## Installation and Setup

```bash
# Install the Azure DevOps extension
az extension add --name azure-devops

# Configure default organization and project
az devops configure --defaults organization=https://dev.azure.com/myorganization project=myproject

# Login to Azure DevOps
az login
az devops login
```

## Organization and Project Management

```bash
# List organizations
az devops organization list

# List projects in an organization
az devops project list --organization https://dev.azure.com/myorganization

# Create a new project
az devops project create --name myproject --organization https://dev.azure.com/myorganization

# Show project details
az devops project show --project myproject

# Delete a project
az devops project delete --id <project-id> --organization https://dev.azure.com/myorganization --yes
```

## Repositories

```bash
# List repositories in a project
az repos list --project myproject

# Create a new repository
az repos create --name myrepo --project myproject

# Clone a repository
az repos clone --repository myrepo --path /path/to/clone

# List branches
az repos ref list --repository myrepo --filter heads/ --project myproject

# Create a branch
az repos ref create --name refs/heads/mybranch --repository myrepo --project myproject

# List commits
az repos commit list --repository myrepo --project myproject

# Show commit details
az repos commit show --commit-id <commit-id> --repository myrepo --project myproject

# Create a pull request
az repos pr create --repository myrepo --source-branch mybranch --target-branch main --title "My PR" --description "PR description"

# List pull requests
az repos pr list --repository myrepo --project myproject

# Complete a pull request
az repos pr update --id <pr-id> --status completed --repository myrepo --project myproject
```

## Pipelines

```bash
# List pipelines
az pipelines list --project myproject

# Create a pipeline
az pipelines create --name mypipeline --repository myrepo --repository-type tfsgit --branch main --yml-path azure-pipelines.yml --project myproject

# Show pipeline details
az pipelines show --name mypipeline --project myproject

# Run a pipeline
az pipelines run --name mypipeline --project myproject

# List pipeline runs
az pipelines runs list --pipeline-name mypipeline --project myproject

# Show pipeline run details
az pipelines runs show --id <run-id> --project myproject

# List pipeline variables
az pipelines variable list --pipeline-name mypipeline --project myproject

# Add a pipeline variable
az pipelines variable create --pipeline-name mypipeline --name myvar --value myvalue --project myproject

# Update a pipeline variable
az pipelines variable update --pipeline-name mypipeline --name myvar --value newvalue --project myproject
```

## Artifacts

```bash
# List artifact feeds
az artifacts feed list --project myproject

# Create an artifact feed
az artifacts feed create --name myfeed --project myproject

# List packages in a feed
az artifacts package list --feed myfeed --project myproject

# Download a package
az artifacts package download --feed myfeed --package-name mypackage --package-version 1.0.0 --path /path/to/download --project myproject

# Publish a package
az artifacts universal publish --feed myfeed --name mypackage --version 1.0.0 --path /path/to/package --project myproject
```

## Work Items

```bash
# List work item types
az boards work-item list-type --project myproject

# Create a work item
az boards work-item create --title "My Task" --type "Task" --project myproject

# Show work item details
az boards work-item show --id <work-item-id> --project myproject

# Update a work item
az boards work-item update --id <work-item-id> --state "In Progress" --project myproject

# Add a comment to a work item
az boards work-item update --id <work-item-id> --discussion "This is a comment" --project myproject

# List work items
az boards work-item query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM workitems WHERE [System.WorkItemType] = 'Task'" --project myproject
```

## Service Connections

```bash
# List service connections
az devops service-endpoint list --project myproject

# Create an Azure Resource Manager service connection
az devops service-endpoint azurerm create --name "AzureConnection" \
  --azure-rm-service-principal-id <service-principal-id> \
  --azure-rm-subscription-id <subscription-id> \
  --azure-rm-subscription-name "My Subscription" \
  --azure-rm-tenant-id <tenant-id> \
  --project myproject

# Create a GitHub service connection
az devops service-endpoint github create --name "GitHubConnection" \
  --github-url https://github.com \
  --github-pat <personal-access-token> \
  --project myproject

# Delete a service connection
az devops service-endpoint delete --id <service-endpoint-id> --project myproject --yes
```

## Variable Groups

```bash
# List variable groups
az pipelines variable-group list --project myproject

# Create a variable group
az pipelines variable-group create --name "MyVariables" --variables key1=value1 key2=value2 --project myproject

# Show variable group details
az pipelines variable-group show --group-id <group-id> --project myproject

# Add a variable to a variable group
az pipelines variable-group variable create --group-id <group-id> --name newvar --value newvalue --project myproject

# Update a variable in a variable group
az pipelines variable-group variable update --group-id <group-id> --name myvar --value newvalue --project myproject

# Delete a variable from a variable group
az pipelines variable-group variable delete --group-id <group-id> --name myvar --project myproject --yes
```

## Extensions

```bash
# List installed extensions
az devops extension list --organization https://dev.azure.com/myorganization

# Search for extensions in the marketplace
az devops extension search --search-query "Azure ML" --organization https://dev.azure.com/myorganization

# Install an extension
az devops extension install --extension-id "azure-machine-learning" --publisher-id "ms-air-aiagility" --organization https://dev.azure.com/myorganization

# Show extension details
az devops extension show --extension-id "azure-machine-learning" --publisher-id "ms-air-aiagility" --organization https://dev.azure.com/myorganization

# Uninstall an extension
az devops extension uninstall --extension-id "azure-machine-learning" --publisher-id "ms-air-aiagility" --organization https://dev.azure.com/myorganization
```

## MLOps-Specific Commands

```bash
# Create a pipeline for ML model training
az pipelines create --name "ML-Training-Pipeline" \
  --repository myrepo \
  --repository-type tfsgit \
  --branch main \
  --yml-path ml-pipelines/training-pipeline.yml \
  --project myproject

# Create a pipeline for ML model deployment
az pipelines create --name "ML-Deployment-Pipeline" \
  --repository myrepo \
  --repository-type tfsgit \
  --branch main \
  --yml-path ml-pipelines/deployment-pipeline.yml \
  --project myproject

# Create a variable group for ML configuration
az pipelines variable-group create --name "ML-Config" \
  --variables \
    AML_WORKSPACE_NAME=myworkspace \
    AML_RESOURCE_GROUP=myresourcegroup \
    AML_SUBSCRIPTION_ID=<subscription-id> \
    MODEL_NAME=mymodel \
  --project myproject

# Create a service connection for Azure ML
az devops service-endpoint azurerm create --name "AzureMLConnection" \
  --azure-rm-service-principal-id <service-principal-id> \
  --azure-rm-subscription-id <subscription-id> \
  --azure-rm-subscription-name "My Subscription" \
  --azure-rm-tenant-id <tenant-id> \
  --project myproject

# Trigger a training pipeline with parameters
az pipelines run --name "ML-Training-Pipeline" \
  --parameters '{"model_name": "new-model", "data_version": "2"}' \
  --project myproject

# Create a work item for model approval
az boards work-item create \
  --title "Approve model deployment to production" \
  --type "Task" \
  --assigned-to user@example.com \
  --description "Review model metrics and approve deployment to production" \
  --project myproject
```
