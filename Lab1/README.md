# Lab 1: Infrastructure as Code for MLOps Environment Setup

This lab provides step-by-step instructions for setting up a complete MLOps development environment using infrastructure as code (IaC) principles, from local tools to cloud resources.

## Contents

1. [VS Code Installation](01-vscode-installation.md) - Installing VS Code on Windows using automation
2. [WSL Setup](02-wsl-setup.md) - Setting up Windows Subsystem for Linux with Ubuntu using scripts
3. [VS Code WSL Integration](03-vscode-wsl-integration.md) - Configuring VS Code to use WSL as the default terminal
4. [Python Environment Setup](04-python-environment-setup.md) - Installing Python and setting up virtual environments (venv and Conda)
5. [Password Management](05-password-management.md) - Setting up pass for password management and API key storage
6. [DevOps Board Setup](06-devops-board-setup.md) - Creating and configuring an Azure DevOps board using Azure CLI
7. [Azure Account Setup](07-azure-account-setup.md) - Setting up an Azure account with automation
8. [DevOps-Azure Integration](08-devops-azure-integration.md) - Linking DevOps board to Azure account using scripts
9. [Azure Resource Setup](09-azure-resource-setup.md) - Setting up resource groups and storage using IaC templates
10. [Teardown Guide](10-teardown-guide.md) - How to tear down all resources and clean up the environment

## Infrastructure as Code Approach

This lab follows infrastructure as code principles:
- All environment configurations are defined in code
- Setup is automated and reproducible
- Resources can be consistently deployed and torn down
- Version control can be applied to infrastructure
- Changes can be reviewed and tested before deployment

## Prerequisites

- Windows 10 or 11 computer with administrator access
- Internet connection
- Microsoft account (for Azure services)

## Expected Outcome

After completing this lab, you will have:
- A fully configured local development environment with VS Code and WSL
- Secure password management for API keys and credentials
- An Azure DevOps board for project management
- An Azure account with properly configured resources for ML development
- Integration between your local environment and cloud resources
- The ability to tear down all resources when they're no longer needed
