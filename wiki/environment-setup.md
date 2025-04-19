# Azure ML Development Environment Setup

This guide provides step-by-step instructions for setting up your development environment for Azure Machine Learning operations, focusing on command-line tools.

## Prerequisites

Before starting, ensure you have:
- An Azure account with an active subscription
- Sufficient permissions to create resources in Azure
- A local machine with a terminal/command prompt

## 1. Install Azure CLI

The Azure Command-Line Interface (CLI) is the primary tool for managing Azure resources from the command line.

### Linux (Ubuntu/Debian)

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Download and install the Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Add the Azure CLI software repository
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

# Update package index and install
sudo apt-get update
sudo apt-get install -y azure-cli
```

### macOS

```bash
# Using Homebrew
brew update
brew install azure-cli
```

### Windows

```bash
# Using PowerShell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

### Verify Installation

```bash
az --version
```

## 2. Install Azure ML CLI Extension

The Azure ML CLI extension adds machine learning capabilities to the Azure CLI.

```bash
# Install the Azure ML extension
az extension add -n ml

# Verify installation
az ml -h
```

## 3. Set Up Python Environment

Azure ML SDK requires Python. We'll set up a virtual environment for our ML work.

```bash
# Install Python (if not already installed)
# Ubuntu/Debian
sudo apt-get install -y python3 python3-pip python3-venv

# Create a virtual environment
python3 -m venv ~/azureml-env

# Activate the environment
source ~/azureml-env/bin/activate  # Linux/macOS
# or
# .\azureml-env\Scripts\activate  # Windows

# Install Azure ML SDK
pip install azure-ai-ml azure-identity
```

## 4. Configure Azure Authentication

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set default subscription
az account set --subscription <subscription-id>
```

## 5. Create a Resource Group and Workspace

```bash
# Create a resource group
az group create --name myResourceGroup --location eastus

# Create an Azure ML workspace
az ml workspace create --name myworkspace --resource-group myResourceGroup
```

## 6. Set Up Git and GitHub/Azure DevOps Integration

### Install Git

```bash
# Ubuntu/Debian
sudo apt-get install -y git

# macOS
brew install git

# Verify installation
git --version
```

### Configure Git

```bash
# Set your username and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Generate SSH key (if needed)
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"

# Display the public key to add to GitHub/Azure DevOps
cat ~/.ssh/id_rsa.pub
```

### Clone a Repository

```bash
# Clone an existing repository
git clone <repository-url>

# Navigate to the repository directory
cd <repository-directory>
```

## 7. Configure Azure ML CLI for Your Workspace

Create a configuration file to simplify CLI commands:

```bash
# Create a .azureml directory
mkdir -p ~/.azureml

# Create a config file
cat > ~/.azureml/config.json << EOF
{
    "subscription_id": "<subscription-id>",
    "resource_group": "myResourceGroup",
    "workspace_name": "myworkspace"
}
EOF
```

## 8. Set Up VS Code (Optional but Recommended)

While we focus on command-line tools, VS Code provides excellent integration with Azure ML.

```bash
# Install VS Code (Ubuntu/Debian)
sudo apt-get install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt-get update
sudo apt-get install -y code

# Install Azure ML extension in VS Code
code --install-extension ms-toolsai.vscode-ai
```

## 9. Create Aliases for Common Commands (Optional)

Create shortcuts for frequently used commands:

```bash
# Add these to your .bashrc or .zshrc
echo 'alias azml="az ml"' >> ~/.bashrc
echo 'alias azjob="az ml job"' >> ~/.bashrc
echo 'alias azcomp="az ml compute"' >> ~/.bashrc
echo 'alias azmodel="az ml model"' >> ~/.bashrc
echo 'alias azep="az ml online-endpoint"' >> ~/.bashrc

# Reload shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

## 10. Set Up a Project Structure

Create a standard project structure for your ML projects:

```bash
# Create a new project directory
mkdir -p ~/ml-projects/my-project

# Create standard subdirectories
cd ~/ml-projects/my-project
mkdir -p data src/models src/pipelines config notebooks tests

# Initialize git repository
git init

# Create a .gitignore file
cat > .gitignore << EOF
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

# Azure ML
outputs/
.azureml/

# Jupyter Notebook
.ipynb_checkpoints

# VS Code
.vscode/

# Data
*.csv
*.parquet
*.h5
EOF

# Create a basic README
cat > README.md << EOF
# My Azure ML Project

This project uses Azure Machine Learning for [brief description].

## Setup

Follow the instructions in the [environment setup guide](../../wiki/environment-setup.md).

## Project Structure

- \`data/\`: Data files (not tracked in git)
- \`src/models/\`: Model training code
- \`src/pipelines/\`: ML pipeline definitions
- \`config/\`: Configuration files
- \`notebooks/\`: Jupyter notebooks
- \`tests/\`: Unit and integration tests
EOF
```

## 11. Verify Your Setup

Test your setup by running a simple Azure ML command:

```bash
# List compute resources in your workspace
az ml compute list

# If you get a proper response (even if empty), your setup is working correctly
```

## Troubleshooting Common Setup Issues

### Authentication Issues

```bash
# If you encounter authentication errors, try logging in again
az login

# Check if you're using the correct subscription
az account show
```

### Azure ML Extension Issues

```bash
# If the ML extension isn't working correctly, try removing and reinstalling
az extension remove -n ml
az extension add -n ml
```

### Python Environment Issues

```bash
# If you encounter Python package conflicts, create a fresh environment
python3 -m venv ~/azureml-env-new
source ~/azureml-env-new/bin/activate
pip install azure-ai-ml azure-identity
```

## Next Steps

Now that your environment is set up, you can:

1. Explore [Azure ML Fundamentals](azure-ml-fundamentals.md)
2. Learn about [Data Management in Azure](data-management.md)
3. Start [Model Development on Azure](model-development.md)

For quick reference to common commands, check out our [Azure ML CLI Commands Cheat Sheet](cheatsheets/aml-cli-commands.md).
