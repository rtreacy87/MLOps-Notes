# 2. Azure ML Development Environment Setup

This guide covers how to set up your development environment for Azure Machine Learning, focusing on command-line tools and integrations.

## Azure ML SDK and CLI Setup

### Installing the Azure CLI

The Azure Command-Line Interface (CLI) is the foundation for interacting with Azure services.

```bash
# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS
brew update && brew install azure-cli

# Verify installation
az --version
```

### Installing the Azure ML CLI Extension

```bash
# Install the ML extension
az extension add -n ml

# Update the extension if already installed
az extension update -n ml

# Verify installation
az ml -h
```

### Setting Up the Python SDK

```bash
# Create a virtual environment
python -m venv azureml-env

# Activate the environment
source azureml-env/bin/activate  # Linux/macOS
# or
# .\azureml-env\Scripts\activate  # Windows

# Install the Azure ML SDK
pip install azure-ai-ml azure-identity

# Install additional packages as needed
pip install pandas numpy scikit-learn matplotlib
```

### Authenticating with Azure

```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription <subscription-id>

# Verify current subscription
az account show
```

### Creating a Configuration File

```bash
# Create a directory for configuration
mkdir -p ~/.azureml

# Create a config file
cat > ~/.azureml/config.json << EOF
{
    "subscription_id": "<subscription-id>",
    "resource_group": "<resource-group>",
    "workspace_name": "<workspace-name>"
}
EOF
```

## VS Code Integration with Azure ML

While we focus on command-line tools, VS Code provides excellent integration with Azure ML and can enhance your productivity.

### Installing VS Code

```bash
# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt-get update
sudo apt-get install -y code

# macOS
brew install --cask visual-studio-code
```

### Installing Azure ML Extensions for VS Code

```bash
# Install extensions from the command line
code --install-extension ms-toolsai.vscode-ai
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-azureresourcegroups
```

### Configuring VS Code for Azure ML

Create a `.vscode/settings.json` file in your project:

```bash
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "python.defaultInterpreterPath": "./azureml-env/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true,
    "azureML.defaultWorkspaceId": "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.MachineLearningServices/workspaces/<workspace-name>"
}
EOF
```

## Jupyter Notebooks in Azure ML

### Setting Up Jupyter Locally

```bash
# Install Jupyter in your virtual environment
pip install jupyter ipykernel

# Register your virtual environment as a kernel
python -m ipykernel install --user --name azureml --display-name "Azure ML"

# Start Jupyter
jupyter notebook
```

### Using Azure ML Compute Instances for Jupyter

```bash
# Create a compute instance
az ml compute create --name <compute-instance-name> --type computeinstance \
                     --size Standard_DS3_v2 \
                     --workspace-name <workspace-name> --resource-group <resource-group>

# List compute instances
az ml compute list --type ComputeInstance \
                   --workspace-name <workspace-name> --resource-group <resource-group>

# Start a compute instance
az ml compute start --name <compute-instance-name> \
                    --workspace-name <workspace-name> --resource-group <resource-group>

# Get the Jupyter URL
az ml compute show --name <compute-instance-name> \
                   --workspace-name <workspace-name> --resource-group <resource-group> \
                   --query "properties.jupyterLabEndpoint"
```

### Working with Notebooks from the Command Line

```bash
# Convert a Jupyter notebook to a Python script
jupyter nbconvert --to python notebook.ipynb

# Run a notebook non-interactively
jupyter nbconvert --to notebook --execute notebook.ipynb --output executed_notebook.ipynb
```

## GitHub/Azure DevOps Integration

### Setting Up Git

```bash
# Install Git
sudo apt-get install -y git  # Ubuntu/Debian
# or
brew install git  # macOS

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Generate SSH key
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"

# Display the public key to add to GitHub/Azure DevOps
cat ~/.ssh/id_rsa.pub
```

### Cloning a Repository

```bash
# Clone a repository
git clone <repository-url>
cd <repository-directory>
```

### Setting Up Azure DevOps CLI

```bash
# Install the Azure DevOps extension
az extension add --name azure-devops

# Configure default organization and project
az devops configure --defaults organization=https://dev.azure.com/YourOrganization project=YourProject

# Login to Azure DevOps
az devops login
```

### Creating an ML Project in Azure DevOps

```bash
# Create a new Azure DevOps project
az devops project create --name MLOpsProject --description "Machine Learning Operations Project"

# Create a Git repository
az repos create --name MLOpsRepo

# Clone the repository
git clone https://dev.azure.com/YourOrganization/MLOpsProject/_git/MLOpsRepo
cd MLOpsRepo
```

### Setting Up CI/CD for ML Projects

```bash
# Create a pipeline YAML file
mkdir -p .azure-pipelines
cat > .azure-pipelines/train-deploy-pipeline.yml << 'EOF'
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - models/*
    - pipelines/*

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.8'
    addToPath: true

- script: |
    python -m pip install --upgrade pip
    pip install azure-ai-ml azure-identity
  displayName: 'Install dependencies'

- script: |
    az login --service-principal -u $(SP_ID) -p $(SP_PASSWORD) --tenant $(TENANT_ID)
    az account set --subscription $(SUBSCRIPTION_ID)
  displayName: 'Login to Azure'

- script: |
    python pipelines/run_training_pipeline.py
  displayName: 'Run training pipeline'

- script: |
    python pipelines/deploy_model.py
  displayName: 'Deploy model'
EOF

# Add the pipeline file to Git
git add .azure-pipelines/train-deploy-pipeline.yml
git commit -m "Add CI/CD pipeline for ML workflow"
git push
```

## Project Structure for ML Development

Create a standardized project structure for your ML projects:

```bash
# Create project directories
mkdir -p src/{data,models,pipelines,utils} config notebooks tests

# Create a README
cat > README.md << 'EOF'
# Azure ML Project

This project uses Azure Machine Learning for [brief description].

## Setup

1. Clone this repository
2. Install dependencies: `pip install -r requirements.txt`
3. Configure Azure ML: Update `config/azure_config.json` with your workspace details

## Project Structure

- `src/data/`: Data processing scripts
- `src/models/`: Model training and evaluation code
- `src/pipelines/`: ML pipeline definitions
- `src/utils/`: Utility functions
- `config/`: Configuration files
- `notebooks/`: Jupyter notebooks for exploration
- `tests/`: Unit and integration tests
EOF

# Create a requirements file
cat > requirements.txt << 'EOF'
azure-ai-ml>=1.0.0
azure-identity>=1.10.0
pandas>=1.4.0
numpy>=1.22.0
scikit-learn>=1.0.0
matplotlib>=3.5.0
pytest>=7.0.0
black>=22.0.0
pylint>=2.12.0
EOF

# Create a configuration file
mkdir -p config
cat > config/azure_config.json << 'EOF'
{
    "subscription_id": "<subscription-id>",
    "resource_group": "<resource-group>",
    "workspace_name": "<workspace-name>"
}
EOF

# Create a .gitignore file
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
venv/
ENV/
azureml-env/

# Jupyter Notebook
.ipynb_checkpoints

# Azure ML
outputs/
.azureml/

# VS Code
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# Data
data/
*.csv
*.parquet
*.h5

# Logs
logs/
*.log
EOF

# Initialize Git repository
git init
git add .
git commit -m "Initial project structure"
```

## Command-Line Workflow Examples

### Training a Model

```bash
# Create a training script
mkdir -p src/models
cat > src/models/train.py << 'EOF'
import argparse
import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import joblib
import mlflow
import mlflow.sklearn

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-path", type=str, help="Path to the training data")
    parser.add_argument("--model-output", type=str, help="Path to output the model")
    parser.add_argument("--n-estimators", type=int, default=100, help="Number of estimators")
    parser.add_argument("--max-depth", type=int, default=10, help="Max depth")
    args = parser.parse_args()
    
    # Start MLflow run
    mlflow.start_run()
    
    # Log parameters
    mlflow.log_param("n_estimators", args.n_estimators)
    mlflow.log_param("max_depth", args.max_depth)
    
    # Read data
    data = pd.read_csv(args.data_path)
    X = data.drop("target", axis=1)
    y = data["target"]
    
    # Train model
    model = RandomForestClassifier(
        n_estimators=args.n_estimators,
        max_depth=args.max_depth,
        random_state=42
    )
    model.fit(X, y)
    
    # Evaluate model
    y_pred = model.predict(X)
    accuracy = accuracy_score(y, y_pred)
    mlflow.log_metric("accuracy", accuracy)
    
    # Save model
    os.makedirs(args.model_output, exist_ok=True)
    joblib.dump(model, os.path.join(args.model_output, "model.pkl"))
    
    # End MLflow run
    mlflow.end_run()

if __name__ == "__main__":
    main()
EOF

# Create a job submission script
cat > run_training.py << 'EOF'
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient, command
from azure.ai.ml.entities import Environment
from azure.ai.ml import Input, Output
import json

# Load configuration
with open("config/azure_config.json") as f:
    config = json.load(f)

# Connect to workspace
credential = DefaultAzureCredential()
ml_client = MLClient(
    credential=credential,
    subscription_id=config["subscription_id"],
    resource_group_name=config["resource_group"],
    workspace_name=config["workspace_name"]
)

# Define job
job = command(
    code="./src",
    command="python models/train.py --data-path ${{inputs.training_data}} --model-output ${{outputs.model_output}} --n-estimators 100 --max-depth 8",
    inputs={
        "training_data": Input(
            type="uri_file",
            path="azureml://datastores/workspaceblobstore/paths/data/train.csv"
        )
    },
    outputs={
        "model_output": Output(
            type="uri_folder",
            path="azureml://datastores/workspaceblobstore/paths/models/sklearn"
        )
    },
    environment="AzureML-sklearn-1.0-ubuntu20.04-py38-cpu:1",
    compute="cpu-cluster",
    display_name="train-random-forest",
    experiment_name="model-training"
)

# Submit job
returned_job = ml_client.jobs.create_or_update(job)
print(f"Job name: {returned_job.name}")
print(f"Job status: {returned_job.status}")
EOF

# Run the training job
python run_training.py
```

### Creating and Running a Pipeline

```bash
# Create a pipeline script
mkdir -p src/pipelines
cat > src/pipelines/create_pipeline.py << 'EOF'
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient, Input, Output, dsl, load_component
import json

# Load configuration
with open("config/azure_config.json") as f:
    config = json.load(f)

# Connect to workspace
credential = DefaultAzureCredential()
ml_client = MLClient(
    credential=credential,
    subscription_id=config["subscription_id"],
    resource_group_name=config["resource_group"],
    workspace_name=config["workspace_name"]
)

# Define pipeline
@dsl.pipeline(
    description="Training pipeline",
    compute="cpu-cluster"
)
def training_pipeline(data_path):
    # Load components
    data_prep = load_component(source="azureml://registries/azureml/components/data_prep/versions/1")
    train_model = load_component(source="azureml://registries/azureml/components/train_model/versions/1")
    evaluate_model = load_component(source="azureml://registries/azureml/components/evaluate_model/versions/1")
    
    # Data preparation step
    prep_step = data_prep(
        input_data=data_path
    )
    
    # Training step
    train_step = train_model(
        training_data=prep_step.outputs.output_data,
        n_estimators=100,
        max_depth=8
    )
    
    # Evaluation step
    evaluate_step = evaluate_model(
        model_input=train_step.outputs.model_output,
        test_data=prep_step.outputs.output_data
    )
    
    return {
        "pipeline_output": evaluate_step.outputs.evaluation_results
    }

# Create pipeline
pipeline = training_pipeline(
    data_path=Input(
        type="uri_file",
        path="azureml://datastores/workspaceblobstore/paths/data/train.csv"
    )
)

# Submit pipeline
pipeline_job = ml_client.jobs.create_or_update(
    pipeline,
    experiment_name="training-pipeline"
)

print(f"Pipeline job name: {pipeline_job.name}")
print(f"Pipeline job status: {pipeline_job.status}")
EOF

# Run the pipeline
python src/pipelines/create_pipeline.py
```

## Troubleshooting Development Environment Issues

### Authentication Issues

```bash
# Check if you're logged in
az account show

# If not logged in or token expired, login again
az login

# For service principal authentication issues
az login --service-principal -u <client-id> -p <client-secret> --tenant <tenant-id>
```

### Azure ML SDK Issues

```bash
# Check SDK version
pip show azure-ai-ml

# Update SDK
pip install --upgrade azure-ai-ml

# Clear Azure ML CLI extension cache
az extension remove -n ml
az extension add -n ml
```

### Compute Issues

```bash
# Check compute status
az ml compute list --workspace-name <workspace-name> --resource-group <resource-group>

# Restart a compute instance
az ml compute restart --name <compute-instance-name> \
                      --workspace-name <workspace-name> --resource-group <resource-group>

# Create a new compute cluster if needed
az ml compute create --name cpu-cluster --type amlcompute --min-nodes 0 --max-nodes 4 \
                     --workspace-name <workspace-name> --resource-group <resource-group>
```

## Next Steps

After setting up your development environment:

1. Explore [Azure ML Fundamentals](azure-ml-fundamentals.md) to understand the core concepts
2. Learn about [Data Management in Azure](data-management.md) to work with your datasets
3. Proceed to [Model Development](model-development.md) to start training models
