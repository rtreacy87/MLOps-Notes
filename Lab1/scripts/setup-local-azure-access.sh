#!/bin/bash
# Script to set up local environment for accessing Azure resources

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./setup-local-azure-access.sh project_name"
    exit 1
fi

PROJECT_NAME=$1
ENV_FILE="${PROJECT_NAME}-mlops-env.json"

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file '$ENV_FILE' not found. Please run setup-mlops-environment.sh first."
    exit 1
fi

# Extract values from environment file
RESOURCE_GROUP=$(jq -r '.resourceGroup' "$ENV_FILE")
STORAGE_ACCOUNT=$(jq -r '.storageAccount' "$ENV_FILE")
KEYVAULT_NAME=$(jq -r '.keyVault' "$ENV_FILE")

# Install required Python packages
echo "Installing required Python packages..."
pip install azure-storage-blob azure-identity azure-keyvault-secrets

# Create a Python script for accessing Azure resources
echo "Creating Python script for accessing Azure resources..."
cat > "access-azure-resources.py" << EOF
#!/usr/bin/env python3
"""
Script to access Azure resources from local environment.
"""

import os
import sys
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.keyvault.secrets import SecretClient

# Load configuration
sys.path.append('.')
import ${PROJECT_NAME}-config as config

def list_blobs(container_name):
    """List all blobs in a container."""
    try:
        # Create a blob service client
        blob_service_client = BlobServiceClient.from_connection_string(config.STORAGE_CONNECTION_STRING)
        
        # Get a container client
        container_client = blob_service_client.get_container_client(container_name)
        
        # List blobs
        print(f"Blobs in container '{container_name}':")
        for blob in container_client.list_blobs():
            print(f"  {blob.name}")
    except Exception as e:
        print(f"Error listing blobs: {e}")

def upload_blob(container_name, local_file_path, blob_name=None):
    """Upload a file to a container."""
    if blob_name is None:
        blob_name = os.path.basename(local_file_path)
        
    try:
        # Create a blob service client
        blob_service_client = BlobServiceClient.from_connection_string(config.STORAGE_CONNECTION_STRING)
        
        # Get a blob client
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        
        # Upload the file
        with open(local_file_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)
            
        print(f"Uploaded {local_file_path} to {container_name}/{blob_name}")
    except Exception as e:
        print(f"Error uploading blob: {e}")

def download_blob(container_name, blob_name, local_file_path):
    """Download a blob to a local file."""
    try:
        # Create a blob service client
        blob_service_client = BlobServiceClient.from_connection_string(config.STORAGE_CONNECTION_STRING)
        
        # Get a blob client
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
        
        # Download the blob
        with open(local_file_path, "wb") as download_file:
            download_file.write(blob_client.download_blob().readall())
            
        print(f"Downloaded {container_name}/{blob_name} to {local_file_path}")
    except Exception as e:
        print(f"Error downloading blob: {e}")

def get_secret(secret_name):
    """Get a secret from Key Vault."""
    try:
        # Create a credential
        credential = DefaultAzureCredential()
        
        # Create a secret client
        secret_client = SecretClient(vault_url=f"https://{config.KEYVAULT_NAME}.vault.azure.net/", credential=credential)
        
        # Get the secret
        secret = secret_client.get_secret(secret_name)
        
        print(f"Retrieved secret '{secret_name}'")
        return secret.value
    except Exception as e:
        print(f"Error getting secret: {e}")
        return None

if __name__ == "__main__":
    # Example usage
    if len(sys.argv) < 2:
        print("Usage: python access-azure-resources.py [list|upload|download|secret]")
        sys.exit(1)
        
    command = sys.argv[1]
    
    if command == "list":
        if len(sys.argv) < 3:
            print("Usage: python access-azure-resources.py list <container_name>")
            sys.exit(1)
        list_blobs(sys.argv[2])
        
    elif command == "upload":
        if len(sys.argv) < 4:
            print("Usage: python access-azure-resources.py upload <container_name> <local_file_path> [blob_name]")
            sys.exit(1)
        blob_name = sys.argv[4] if len(sys.argv) > 4 else None
        upload_blob(sys.argv[2], sys.argv[3], blob_name)
        
    elif command == "download":
        if len(sys.argv) < 5:
            print("Usage: python access-azure-resources.py download <container_name> <blob_name> <local_file_path>")
            sys.exit(1)
        download_blob(sys.argv[2], sys.argv[3], sys.argv[4])
        
    elif command == "secret":
        if len(sys.argv) < 3:
            print("Usage: python access-azure-resources.py secret <secret_name>")
            sys.exit(1)
        secret_value = get_secret(sys.argv[2])
        if secret_value:
            print(f"Secret value: {secret_value}")
    else:
        print(f"Unknown command: {command}")
        print("Usage: python access-azure-resources.py [list|upload|download|secret]")
EOF

chmod +x "access-azure-resources.py"

echo "Local environment setup complete!"
echo "You can now use access-azure-resources.py to interact with your Azure resources."
echo "Examples:"
echo "  ./access-azure-resources.py list data"
echo "  ./access-azure-resources.py upload data ./mydata.csv"
echo "  ./access-azure-resources.py download models model.pkl ./model.pkl"
echo "  ./access-azure-resources.py secret StorageConnectionString"
