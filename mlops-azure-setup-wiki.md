# Azure ML Development Environment Setup Wiki

*Written by: Senior MLOps Engineer*

## Introduction

Welcome to the team! This wiki will guide you through setting up VS Code and Jupyter Notebooks for Azure ML development. By the end of this guide, you'll be able to:

1. Set up VS Code with Azure ML extensions
2. Configure Jupyter Notebooks for Azure ML
3. Connect both environments to your Azure ML workspace
4. Perform common day-to-day MLOps tasks

Let's get started!

## Part 1: VS Code Setup for Azure ML

### Prerequisites

- [VS Code](https://code.visualstudio.com/) installed on your machine
- [Python](https://www.python.org/downloads/) installed (version 3.8 or higher recommended)
- Azure subscription with an existing Azure ML workspace

### Step 1: Install Required VS Code Extensions

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for and install the following extensions:
   - **Python** (Microsoft)
   - **Azure Machine Learning** (Microsoft)
   - **Azure Account** (Microsoft)
   - **Jupyter** (Microsoft)

### Step 2: Configure Azure Extension Authentication

1. Open Command Palette (Ctrl+Shift+P)
2. Type "Azure: Sign In" and press Enter
3. Follow the authentication flow in your browser
4. After signing in, VS Code should show your Azure account in the status bar

### Step 3: Connect to Your Azure ML Workspace

1. In VS Code, click on the Azure icon in the activity bar
2. Expand the Azure Machine Learning section
3. Find your subscription and workspace
4. Right-click on your workspace and select "Set as Default Workspace"

### Step 4: Create a Project Structure

Create a folder structure like this for your ML projects:

```
my-ml-project/
├── .azureml/                # Azure ML config folder
│   └── config.json          # Workspace connection config
├── data/                    # Data files
├── notebooks/               # Jupyter notebooks
├── src/                     # Python source code
├── pipelines/               # ML pipeline definitions
├── models/                  # Local model files
├── conda_dependencies.yml   # Environment definition
└── README.md                # Project documentation
```

### Step 5: Generate Workspace Configuration

1. Open Command Palette (Ctrl+Shift+P)
2. Type "Azure ML: Generate Workspace Config" and press Enter
3. Select your subscription, resource group, and workspace
4. Save the config file in the `.azureml` folder

Your `config.json` should look similar to:

```json
{
    "subscription_id": "your-subscription-id",
    "resource_group": "your-resource-group",
    "workspace_name": "your-workspace-name"
}
```

## Part 2: Jupyter Notebooks Setup for Azure ML

### Step 1: Create a Python Environment

Create a dedicated conda environment for Azure ML:

```bash
# In VS Code terminal
conda create -n azureml python=3.8
conda activate azureml

# Install necessary packages
pip install azure-ai-ml azure-identity ipykernel matplotlib pandas scikit-learn
```

### Step 2: Register Your Environment with Jupyter

```bash
python -m ipykernel install --user --name azureml --display-name "Python (AzureML)"
```

### Step 3: Configure Azure ML for Jupyter

Create a simple authentication script in your project:

```python
# auth.py
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient

def get_ml_client():
    try:
        credential = DefaultAzureCredential()
        client = MLClient.from_config(credential=credential)
        return client
    except Exception as ex:
        print(f"Error connecting to Azure ML: {ex}")
        return None
```

## Part 3: Day-to-Day Operations

### Creating and Running a Notebook in VS Code

1. In VS Code, navigate to your project's `notebooks` folder
2. Right-click and select "New File", name it `experiment.ipynb`
3. When prompted, select the "Python (AzureML)" kernel
4. Add the following cells to your notebook:

```python
# Cell 1: Import libraries and authenticate
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient
import pandas as pd
import matplotlib.pyplot as plt

# Connect to workspace
credential = DefaultAzureCredential()
ml_client = MLClient.from_config(credential=credential)
print("Connected to workspace:", ml_client.workspace_name)
```

```python
# Cell 2: List datastores
datastores = ml_client.datastores.list()
for datastore in datastores:
    print(f"- {datastore.name} ({datastore.type})")
```

### Submitting a Training Job to Azure ML

Create a notebook for job submission:

```python
# Import libraries
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient, command
from azure.ai.ml.entities import Environment
from azure.ai.ml import Input, Output

# Connect to workspace
credential = DefaultAzureCredential()
ml_client = MLClient.from_config(credential=credential)

# Define command job
job = command(
    code="./src",
    command="python train.py --input-data ${{inputs.training_data}} --output-dir ${{outputs.model_output}}",
    inputs={
        "training_data": Input(type="uri_folder", path="azureml:training-data:1")
    },
    outputs={
        "model_output": Output(type="uri_folder")
    },
    environment="azureml:training-env:1",
    compute="aml-cluster"
)

# Submit job
returned_job = ml_client.create_or_update(job)
print(f"Submitted job: {returned_job.name}")

# Get a URL to monitor the job in Azure ML studio
studio_url = returned_job.studio_url
print(f"Monitor your job at: {studio_url}")
```

### Using the VS Code Azure ML Extension

The Azure ML extension provides these key features:

1. **Workspace Explorer**: Navigate datasets, models, and experiments
2. **Run History**: View experiment runs and their metrics
3. **Compute Management**: Create, start, stop compute instances
4. **Model Registry**: Browse registered models

To view these features:
1. Click on the Azure icon in the activity bar
2. Expand your Azure ML workspace
3. Browse through the different sections

### Debugging Remote Runs Locally

Set up local debugging for Azure ML jobs:

```python
# In your notebook or script
debug_mode = True

if debug_mode:
    # Run locally
    print("Running in debug mode")
    # Execute your training code directly
else:
    # Submit to Azure ML
    job = command(
        # job definition as before
    )
    ml_client.create_or_update(job)
```

## Part 4: Best Practices

### Workspace Organization

1. **Naming Conventions**:
   - Use descriptive names for experiments: `project-dataset-algorithm`
   - Version your models: `model-name-v1`

2. **Resource Management**:
   - Stop compute instances when not in use
   - Use compute clusters with autoscaling for training jobs

3. **Environment Management**:
   - Define environments in YAML files
   - Version your environments in the workspace

### Collaboration Tips

1. **Version Control**:
   - Store notebook files in Git
   - Commit regularly with meaningful messages
   - Extract reusable code to Python modules

2. **Documentation**:
   - Add markdown cells to notebooks explaining purpose and approach
   - Document parameters and expected outputs

## Troubleshooting

### Common Issues and Solutions

1. **Authentication Errors**:
   ```
   Solution: Run 'az login' in terminal, then restart VS Code
   ```

2. **Kernel Not Found**:
   ```
   Solution: Ensure your conda environment is activated and kernel is installed
   ```

3. **Workspace Connection Failures**:
   ```
   Solution: Verify your config.json has correct subscription/workspace details
   ```

## Conclusion

You now have a complete setup for Azure ML development using VS Code and Jupyter Notebooks. This environment allows you to:

- Develop ML models locally in VS Code or Jupyter
- Submit training jobs to Azure ML
- Track experiments and monitor runs
- Deploy models to production

For more advanced topics, check our team's documentation on:
- MLOps pipelines setup
- Automated model deployment
- Monitoring and drift detection

Happy coding!
