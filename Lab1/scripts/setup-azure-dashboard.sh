#!/bin/bash
# Script to set up a dashboard with Azure resource widgets

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-azure-dashboard.sh project_name"
    exit 1
fi

PROJECT_NAME=$1

# Check if Azure DevOps CLI is configured
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -z "$DEVOPS_ORG" ]; then
    echo "Azure DevOps CLI not configured. Please run 'az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION'"
    exit 1
fi

# Set default project
az devops configure --defaults project="$PROJECT_NAME"

# Create a dashboard
echo "Creating dashboard..."
DASHBOARD_ID=$(az boards dashboard create --name "Azure Resources" --description "Dashboard for Azure resources" --query id -o tsv)

echo "Dashboard created with ID: $DASHBOARD_ID"
echo "You can now add Azure resource widgets to this dashboard through the Azure DevOps web interface."
