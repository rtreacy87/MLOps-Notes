# MLOps Environment Setup Scripts

This directory contains all the scripts referenced in the Lab1 wiki pages. These scripts automate the setup and teardown of a complete MLOps environment, from local development tools to cloud resources.

## Windows/PowerShell Scripts

### VS Code Setup
- `install-vscode.ps1` - Installs VS Code on Windows
- `install-vscode-extensions.ps1` - Installs common VS Code extensions for ML development
- `configure-vscode-wsl.ps1` - Configures VS Code to use WSL as the default terminal

### WSL Setup
- `setup-wsl-part1.ps1` - Enables WSL features (run before restarting)
- `setup-wsl-part2.ps1` - Installs WSL and Ubuntu (run after restarting)

## Bash/Shell Scripts

### WSL Environment Setup
- `setup-ubuntu-env.sh` - Sets up the Ubuntu WSL environment with development tools
- `create-ml-project.sh` - Creates a new ML project with VS Code integration

### Python Environment Setup
- `setup-python.sh` - Installs and configures Python in WSL
- `create-ml-venv.sh` - Creates a Python virtual environment for ML projects
- `install-conda.sh` - Installs Miniconda for environment management
- `create-ml-conda.sh` - Creates a Conda environment for ML projects
- `setup-vscode-python.sh` - Configures VS Code for Python development

### Password Management
- `setup-pass.sh` - Sets up the pass password manager
- `ml-api-keys.sh` - Manages API keys for ML projects

### Azure Setup
- `configure-azure-cli.sh` - Configures Azure CLI with service principal
- `verify-azure-permissions.sh` - Verifies Azure permissions
- `setup-azure-environment.sh` - Sets up a complete Azure environment for MLOps
- `setup-local-azure-access.sh` - Sets up local environment for Azure access

### DevOps Integration
- `setup-service-connection.sh` - Sets up a service connection between Azure DevOps and Azure
- `link-workitem-to-resource.sh` - Links a work item to an Azure resource
- `setup-azure-pipeline.sh` - Sets up a CI/CD pipeline in Azure DevOps
- `setup-azure-dashboard.sh` - Sets up a dashboard with Azure resource widgets

### Teardown Scripts
- `teardown-mlops-environment.sh` - Tears down the MLOps environment
- `complete-teardown.sh` - Comprehensive script to tear down all components

## Usage

1. Make sure the scripts are executable:
   ```bash
   chmod +x *.sh
   ```

2. Run the scripts in the order they appear in the Lab1 wiki pages.

3. For PowerShell scripts, run them from a PowerShell terminal with administrator privileges.

4. For Bash scripts, run them from your WSL terminal.

## Notes

- Some scripts require parameters. Run them with the `-h` or `--help` flag or without parameters to see usage instructions.
- Always review scripts before running them, especially those that create or delete cloud resources.
- The teardown scripts will delete resources, which cannot be undone. Use with caution.
