# Setting Up an Azure DevOps Board

This guide covers how to set up an Azure DevOps board for project management using Azure CLI and automation scripts.

## Prerequisites

- [WSL with Ubuntu installed](02-wsl-setup.md)
- [Python environment setup](04-python-environment-setup.md)
- [Password management set up](05-password-management.md)
- Microsoft account or Azure AD account

## Installing Azure CLI

If you haven't already installed the Azure CLI in your WSL environment, run:

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

## Installing Azure DevOps Extension for Azure CLI

```bash
# Install the Azure DevOps extension
az extension add --name azure-devops

# Verify installation
az devops -h
```

## Setting Up Azure DevOps with CLI

### Step 1: Log in to Azure

```bash
# Log in to Azure
az login
```

This will open a browser window where you can log in with your Microsoft account.

### Step 2: Configure Azure DevOps CLI

```bash
# Set default organization
az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION

# Set default project (if you already have a project)
az devops configure --defaults project=YOUR_PROJECT
```

Replace `YOUR_ORGANIZATION` with your Azure DevOps organization name.

### Step 3: Create a New Project

```bash
# Create a new project
az devops project create --name "MLOps Project" --description "Machine Learning Operations Project" --visibility private
```

### Step 4: Create a Script to Set Up a Complete DevOps Project

Create a bash script to automate the setup of a complete DevOps project with boards, repositories, and pipelines:

```bash
#!/bin/bash
# Save this as setup-devops-project.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-devops-project.sh project_name [organization_name]"
    exit 1
fi

PROJECT_NAME=$1
ORGANIZATION=${2:-$(az devops configure --list | grep organization | awk '{print $3}')}

if [ -z "$ORGANIZATION" ]; then
    echo "No organization specified or configured. Please provide an organization name."
    exit 1
fi

# Remove https:// prefix if present
ORGANIZATION=${ORGANIZATION#https://dev.azure.com/}
ORGANIZATION=${ORGANIZATION#https://}

# Ensure we have the full URL
ORGANIZATION_URL="https://dev.azure.com/$ORGANIZATION"

echo "Setting up DevOps project '$PROJECT_NAME' in organization '$ORGANIZATION_URL'..."

# Configure defaults
az devops configure --defaults organization="$ORGANIZATION_URL"

# Check if project already exists
PROJECT_CHECK=$(az devops project show --project "$PROJECT_NAME" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Project '$PROJECT_NAME' already exists."
else
    # Create the project
    echo "Creating project '$PROJECT_NAME'..."
    az devops project create --name "$PROJECT_NAME" --description "MLOps project created with automation script" --visibility private

    if [ $? -ne 0 ]; then
        echo "Failed to create project. Exiting."
        exit 1
    fi
fi

# Configure project as default
az devops configure --defaults project="$PROJECT_NAME"

# Create repositories
echo "Creating Git repositories..."
REPOS=("data-pipeline" "model-training" "model-deployment" "infrastructure")

for REPO in "${REPOS[@]}"; do
    REPO_CHECK=$(az repos show --repository "$REPO" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "Repository '$REPO' already exists."
    else
        echo "Creating repository '$REPO'..."
        az repos create --name "$REPO"
    fi
done

# Create work items for initial setup
echo "Creating work items..."
WORK_ITEMS=(
    "Set up data pipeline infrastructure"
    "Create model training environment"
    "Implement model deployment pipeline"
    "Set up monitoring and logging"
)

for ITEM in "${WORK_ITEMS[@]}"; do
    echo "Creating work item: $ITEM"
    az boards work-item create --title "$ITEM" --type "User Story" --description "Initial setup task created by automation script"
done

# Create a team
TEAM_NAME="${PROJECT_NAME}-Team"
TEAM_CHECK=$(az devops team show --team "$TEAM_NAME" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Team '$TEAM_NAME' already exists."
else
    echo "Creating team '$TEAM_NAME'..."
    az devops team create --name "$TEAM_NAME" --description "Team for $PROJECT_NAME"
fi

# Create iterations (sprints)
echo "Creating iterations..."
ITERATION_PATH="$PROJECT_NAME\\Sprints"
az boards iteration project create --name "Sprints" --path "$PROJECT_NAME"

for i in {1..3}; do
    SPRINT_NAME="Sprint $i"
    START_DATE=$(date -d "+$((i-1)) weeks" +%Y-%m-%d)
    END_DATE=$(date -d "+$i weeks" +%Y-%m-%d)

    echo "Creating iteration: $SPRINT_NAME ($START_DATE to $END_DATE)"
    az boards iteration project create --name "$SPRINT_NAME" --path "$ITERATION_PATH" --start-date "$START_DATE" --finish-date "$END_DATE"
done

# Create areas
echo "Creating areas..."
AREAS=("Data" "Models" "Infrastructure" "Documentation")

for AREA in "${AREAS[@]}"; do
    echo "Creating area: $AREA"
    az boards area project create --name "$AREA" --path "$PROJECT_NAME"
done

echo "DevOps project setup complete!"
echo "Project URL: $ORGANIZATION_URL/$PROJECT_NAME"
echo "Boards URL: $ORGANIZATION_URL/$PROJECT_NAME/_boards/board/t/$PROJECT_NAME%20Team/Stories"
```

Make the script executable and run it:

```bash
chmod +x setup-devops-project.sh
./setup-devops-project.sh "MLOps-Project" "your-organization-name"
```

## Customizing Your Board

### Creating a Custom Process Template

You can create a custom process template based on an existing one:

```bash
# List available process templates
az boards process list

# Create a custom process
az boards process create --name "MLOps Process" --parent-process-name "Agile"

# Create a custom work item type
az boards process work-item-type create --process-name "MLOps Process" --name "ML Experiment" --description "Tracking ML experiments"

# Add a custom field
az boards process work-item-type field create --process-name "MLOps Process" --work-item-type "ML Experiment" --name "Experiment Parameters" --type "text"
```

### Creating a Script to Set Up MLOps-Specific Board

```bash
#!/bin/bash
# Save this as setup-mlops-board.sh

# Check if organization is configured
ORGANIZATION=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -z "$ORGANIZATION" ]; then
    echo "No organization configured. Please run 'az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION'"
    exit 1
fi

# Create MLOps process
echo "Creating MLOps process template..."
PROCESS_CHECK=$(az boards process show --process-name "MLOps Process" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Process 'MLOps Process' already exists."
else
    az boards process create --name "MLOps Process" --parent-process-name "Agile"
fi

# Create custom work item types
WORK_ITEM_TYPES=(
    "ML Experiment:Tracking machine learning experiments"
    "Data Pipeline:Data processing and preparation pipelines"
    "Model Deployment:Model deployment and serving"
)

for WIT in "${WORK_ITEM_TYPES[@]}"; do
    IFS=':' read -r NAME DESCRIPTION <<< "$WIT"
    WIT_CHECK=$(az boards process work-item-type show --process-name "MLOps Process" --wit "$NAME" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "Work item type '$NAME' already exists."
    else
        echo "Creating work item type: $NAME"
        az boards process work-item-type create --process-name "MLOps Process" --name "$NAME" --description "$DESCRIPTION"
    fi
done

# Create custom fields
FIELDS=(
    "ML Experiment:Experiment Parameters:text:Parameters used in the experiment"
    "ML Experiment:Model Metrics:text:Performance metrics of the model"
    "ML Experiment:Dataset Version:text:Version of the dataset used"
    "Data Pipeline:Data Source:text:Source of the data"
    "Data Pipeline:Data Schema:text:Schema of the data"
    "Model Deployment:Deployment Environment:text:Environment where the model is deployed"
    "Model Deployment:Model Version:text:Version of the deployed model"
)

for FIELD in "${FIELDS[@]}"; do
    IFS=':' read -r WIT NAME TYPE DESCRIPTION <<< "$FIELD"
    echo "Creating field: $NAME for $WIT"
    az boards process work-item-type field create --process-name "MLOps Process" --work-item-type "$WIT" --name "$NAME" --type "$TYPE" --description "$DESCRIPTION" 2>/dev/null
done

echo "MLOps board setup complete!"
echo "You can now create a new project using the 'MLOps Process' template."
```

Make the script executable and run it:

```bash
chmod +x setup-mlops-board.sh
./setup-mlops-board.sh
```

## Setting Up a Dashboard

You can create a dashboard using the Azure DevOps CLI:

```bash
# Create a dashboard
az boards dashboard create --name "MLOps Overview" --description "Overview of MLOps activities"
```

## Next Steps

After setting up an Azure DevOps board, proceed to [setting up an Azure account](07-azure-account-setup.md) for cloud resources.
