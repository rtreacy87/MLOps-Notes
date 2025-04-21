#!/bin/bash
# Script to link a work item to an Azure resource

# Check if required parameters are provided
if [ $# -lt 3 ]; then
    echo "Please provide work item ID, resource group, and resource name"
    echo "Usage: ./link-workitem-to-resource.sh work_item_id resource_group resource_name [resource_type]"
    exit 1
fi

WORK_ITEM_ID=$1
RESOURCE_GROUP=$2
RESOURCE_NAME=$3
RESOURCE_TYPE=${4:-"Microsoft.Resources/deployments"}

# Check if logged in to Azure
SUBSCRIPTION_CHECK=$(az account list 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please log in."
    az login
fi

# Check if Azure DevOps CLI is configured
DEVOPS_ORG=$(az devops configure --list | grep organization | awk '{print $3}')
if [ -z "$DEVOPS_ORG" ]; then
    echo "Azure DevOps CLI not configured. Please run 'az devops configure --defaults organization=https://dev.azure.com/YOUR_ORGANIZATION'"
    exit 1
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get resource ID
RESOURCE_ID=$(az resource show --resource-group "$RESOURCE_GROUP" --name "$RESOURCE_NAME" --resource-type "$RESOURCE_TYPE" --query id -o tsv 2>/dev/null)

if [ -z "$RESOURCE_ID" ]; then
    echo "Resource not found. Please check the resource group, name, and type."
    exit 1
fi

# Create a link between the work item and the Azure resource
echo "Linking work item $WORK_ITEM_ID to Azure resource $RESOURCE_NAME..."

# Create a temporary JSON file for the link
cat > temp_link.json << EOF
{
  "op": "add",
  "path": "/relations/-",
  "value": {
    "rel": "Hyperlink",
    "url": "https://portal.azure.com/#resource$RESOURCE_ID",
    "attributes": {
      "comment": "Link to Azure resource: $RESOURCE_NAME"
    }
  }
}
EOF

# Add the link to the work item
az boards work-item update --id "$WORK_ITEM_ID" --path-patch "$(cat temp_link.json)"

# Clean up
rm temp_link.json

echo "Work item $WORK_ITEM_ID linked to Azure resource $RESOURCE_NAME"
