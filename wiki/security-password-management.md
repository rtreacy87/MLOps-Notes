# Password Management and Security Practices for MLOps

Effective password and secret management is critical for MLOps engineers working with cloud services like Azure ML. This guide covers best practices for managing credentials securely, with a focus on command-line tools and workflows.

## Table of Contents
- [Introduction to Secret Management](#introduction-to-secret-management)
- [Password Managers](#password-managers)
  - [Pass: The Standard Unix Password Manager](#pass-the-standard-unix-password-manager)
  - [Other Password Management Options](#other-password-management-options)
- [Environment Variables and Configuration Files](#environment-variables-and-configuration-files)
- [Azure Key Vault Integration](#azure-key-vault-integration)
- [Service Principals and Managed Identities](#service-principals-and-managed-identities)
- [Security Best Practices](#security-best-practices)

## Introduction to Secret Management

MLOps workflows involve numerous credentials and secrets:
- Azure subscription keys
- Storage account access keys
- Database connection strings
- API keys and tokens
- SSH keys and certificates

Improper handling of these secrets can lead to:
- Unauthorized access to resources
- Data breaches
- Compliance violations
- Financial losses

This guide focuses on tools and practices to manage these secrets securely, with an emphasis on command-line workflows suitable for MLOps engineers.

## Password Managers

Password managers provide a secure way to store, organize, and access credentials. They offer several advantages:
- Strong encryption for stored credentials
- Generation of complex, unique passwords
- Secure sharing mechanisms
- Audit trails and access controls

### Pass: The Standard Unix Password Manager

`pass` is a lightweight, command-line password manager that follows the Unix philosophy. It uses GPG for encryption and Git for version control, making it ideal for developers and MLOps engineers.

#### Setting Up Pass

```bash
# Install pass
# Ubuntu/Debian
sudo apt-get install pass

# macOS
brew install pass

# Generate a GPG key if you don't have one
gpg --full-generate-key
# Follow the prompts to create a key
# Recommended: 4096-bit RSA key

# Initialize pass with your GPG key ID
pass init "your-gpg-key-id"

# Optional: Set up Git integration
pass git init
```

#### Basic Pass Usage

```bash
# Store a new password
pass insert azure/subscription-key
# You'll be prompted to enter the password

# Generate and store a random password
pass generate azure/storage-account-key 20
# Creates a random 20-character password

# Retrieve a password (copies to clipboard and clears after 45 seconds)
pass -c azure/subscription-key

# Show a password (AVOID THIS IN SHARED TERMINALS)
pass azure/subscription-key

# List all stored passwords
pass
```

#### Advanced Pass Usage

```bash
# Store multiline content (like JSON configuration)
pass insert -m azure/service-principal
# Enter multiple lines and end with Ctrl+D

# Edit an existing entry
pass edit azure/subscription-key

# Set up Git for synchronization
pass git remote add origin git@github.com:username/password-store.git
pass git push -u origin master

# Search for passwords
pass find azure
```

#### Using Pass in Scripts Securely

To use `pass` in scripts without exposing secrets:

```bash
#!/bin/bash
# Example of using pass in a script without exposing secrets

# BAD PRACTICE - Don't do this:
# AZURE_KEY=$(pass azure/subscription-key)
# echo "Using key: $AZURE_KEY"  # Exposes the key in logs or terminal

# GOOD PRACTICE:
# Use the secret directly in commands without storing in variables
az login --service-principal -u "$(pass azure/sp-id)" -p "$(pass azure/sp-secret)" --tenant "$(pass azure/tenant-id)"

# Or use environment variables without printing them
export AZURE_SUBSCRIPTION_ID="$(pass azure/subscription-id)"
# Don't echo the variable

# For APIs that require a file with credentials
pass azure/service-principal > temp_creds.json
chmod 600 temp_creds.json  # Restrict permissions
# Use the file
rm temp_creds.json  # Delete immediately after use
```

### Other Password Management Options

#### 1. Bitwarden CLI

Bitwarden is an open-source password manager with a CLI tool:

```bash
# Install Bitwarden CLI
npm install -g @bitwarden/cli

# Log in
bw login

# Unlock your vault and set the session key
export BW_SESSION=$(bw unlock --raw)

# Get an item
bw get item "Azure ML Key" --session $BW_SESSION

# Create a new item
bw create item --session $BW_SESSION
```

#### 2. 1Password CLI

1Password offers a command-line tool for its commercial password manager:

```bash
# Install 1Password CLI
# macOS
brew install 1password-cli

# Sign in
op signin

# Get a password
op item get "Azure ML Key" --fields password

# Create a new item
op item create --category login --title "Azure Storage" --url "https://portal.azure.com" --username "admin" --password "$(openssl rand -base64 24)"
```

#### 3. KeePassXC

KeePassXC is an open-source password manager with a CLI companion:

```bash
# Install KeePassXC CLI
# Ubuntu/Debian
sudo apt-get install keepassxc-cli

# List entries
keepassxc-cli ls database.kdbx

# Get a password
keepassxc-cli show database.kdbx "Azure/ML Key"

# Add a new entry
keepassxc-cli add database.kdbx "Azure/New Key"
```

## Environment Variables and Configuration Files

### Secure Use of Environment Variables

Environment variables are commonly used for storing credentials, but require careful handling:

```bash
# Set environment variables
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"

# NEVER do this (exposes secrets in process list and command history):
export AZURE_CLIENT_SECRET=`pass azure/client-secret`  # WRONG!

# Instead, do this:
export AZURE_CLIENT_SECRET="$(pass azure/client-secret)"

# Clear sensitive environment variables when done
unset AZURE_CLIENT_SECRET
```

### Using .env Files Securely

```bash
# Create a .env file
cat > .env << EOF
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
EOF

# Set proper permissions
chmod 600 .env

# Load environment variables
set -a
source .env
set +a

# Add .env to .gitignore
echo ".env" >> .gitignore
```

### Using Configuration Files

```bash
# Create a secure config directory
mkdir -p ~/.azure
chmod 700 ~/.azure

# Create a config file
cat > ~/.azure/credentials.json << EOF
{
  "subscription_id": "your-subscription-id",
  "tenant_id": "your-tenant-id",
  "client_id": "your-client-id",
  "client_secret": "your-client-secret"
}
EOF

# Set proper permissions
chmod 600 ~/.azure/credentials.json
```

## Azure Key Vault Integration

Azure Key Vault provides a secure way to store and access secrets in Azure:

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Log in to Azure
az login

# Create a Key Vault
az keyvault create --name "ml-key-vault" --resource-group "myResourceGroup" --location "eastus"

# Store a secret
az keyvault secret set --vault-name "ml-key-vault" --name "StorageKey" --value "your-secret-value"

# Retrieve a secret
SECRET=$(az keyvault secret show --vault-name "ml-key-vault" --name "StorageKey" --query "value" -o tsv)

# Use the secret without printing it
az storage account keys list --account-name "mystorageaccount" --subscription "$SECRET"
```

### Using Azure Key Vault in Python Scripts

```python
# Install the Azure Key Vault library
# pip install azure-keyvault-secrets azure-identity

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Set up the Key Vault client
credential = DefaultAzureCredential()
vault_url = "https://ml-key-vault.vault.azure.net/"
client = SecretClient(vault_url=vault_url, credential=credential)

# Get a secret
secret = client.get_secret("StorageKey")

# Use the secret value without printing it
storage_key = secret.value
# Don't print storage_key!
```

## Service Principals and Managed Identities

### Creating and Using Service Principals

```bash
# Create a service principal
az ad sp create-for-rbac --name "ml-service-principal" --role contributor --scopes /subscriptions/<subscription-id>

# Store the credentials securely
pass insert -m azure/ml-service-principal
# Enter the JSON output from the previous command

# Use the service principal to log in
az login --service-principal \
  --username "$(pass azure/ml-service-principal | jq -r .appId)" \
  --password "$(pass azure/ml-service-principal | jq -r .password)" \
  --tenant "$(pass azure/ml-service-principal | jq -r .tenant)"
```

### Using Managed Identities

Managed identities eliminate the need to store credentials:

```bash
# Assign a system-assigned managed identity to a VM
az vm identity assign --resource-group "myResourceGroup" --name "myVM"

# Grant the managed identity access to Key Vault
az keyvault set-policy --name "ml-key-vault" \
  --object-id "$(az vm identity show --resource-group "myResourceGroup" --name "myVM" --query principalId -o tsv)" \
  --secret-permissions get list
```

## Security Best Practices

### Command Line Security

1. **Clear command history of sensitive commands**:
   ```bash
   # Remove specific lines from history
   history -d <line_number>
   
   # Or use HISTCONTROL to prevent commands from being saved
   HISTCONTROL=ignorespace
    az login --service-principal -u "id" -p "secret"  # Note the space before the command
   ```

2. **Use process substitution instead of temporary files**:
   ```bash
   # Instead of:
   pass azure/credentials > creds.json
   az login --file creds.json
   rm creds.json
   
   # Use:
   az login --file <(pass azure/credentials)
   ```

3. **Set up automatic session timeouts**:
   ```bash
   # Add to your .bashrc or .zshrc
   TMOUT=1800  # Auto logout after 30 minutes of inactivity
   ```

### File System Security

1. **Use encrypted file systems for sensitive data**:
   ```bash
   # Create an encrypted directory using eCryptfs
   sudo apt-get install ecryptfs-utils
   mkdir ~/.secret
   sudo mount -t ecryptfs ~/.secret ~/.secret
   ```

2. **Secure permissions for credential files**:
   ```bash
   # Set restrictive permissions
   chmod 600 ~/.azure/credentials.json
   chmod 700 ~/.azure
   ```

3. **Use secure deletion tools**:
   ```bash
   # Install secure deletion tools
   sudo apt-get install secure-delete
   
   # Securely delete a file
   srm ~/.azure/old-credentials.json
   ```

### Network Security

1. **Use SSH keys with passphrases**:
   ```bash
   # Generate an SSH key with a passphrase
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # Use ssh-agent to avoid typing the passphrase repeatedly
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

2. **Use VPNs or private endpoints for Azure resources**:
   ```bash
   # Connect to a VPN before accessing sensitive resources
   sudo openvpn --config ~/.vpn/config.ovpn
   ```

### Git Security

1. **Use .gitignore to prevent committing secrets**:
   ```bash
   # Add common secret files to .gitignore
   cat >> .gitignore << EOF
   # Secrets and credentials
   .env
   .env.*
   *.pem
   *.key
   credentials.json
   *_rsa
   *_dsa
   *_ed25519
   *_ecdsa
   EOF
   ```

2. **Use git-secrets to prevent committing secrets**:
   ```bash
   # Install git-secrets
   git clone https://github.com/awslabs/git-secrets.git
   cd git-secrets
   sudo make install
   
   # Set up git-secrets in your repository
   cd your-repository
   git secrets --install
   git secrets --register-aws
   
   # Add custom patterns
   git secrets --add 'private_key'
   git secrets --add 'api[_-]key'
   git secrets --add 'secret[_-]key'
   ```

3. **Use pre-commit hooks**:
   ```bash
   # Install pre-commit
   pip install pre-commit
   
   # Create a pre-commit configuration
   cat > .pre-commit-config.yaml << EOF
   repos:
   - repo: https://github.com/pre-commit/pre-commit-hooks
     rev: v4.4.0
     hooks:
     - id: detect-private-key
     - id: detect-aws-credentials
   EOF
   
   # Install the hooks
   pre-commit install
   ```

### Regular Security Audits

1. **Audit stored credentials**:
   ```bash
   # List all stored credentials
   pass
   
   # Check for expired credentials
   for cred in $(pass find azure | grep -v "Search"); do
     echo "Checking $cred"
     pass "$cred" | grep -i "expires"
   done
   ```

2. **Audit access logs**:
   ```bash
   # Check Azure activity logs
   az monitor activity-log list --start-time 2023-01-01T00:00:00Z
   
   # Check Key Vault access
   az monitor diagnostic-settings list --resource $(az keyvault show --name "ml-key-vault" --query id -o tsv)
   ```

3. **Rotate credentials regularly**:
   ```bash
   # Rotate service principal credentials
   az ad sp credential reset --name "ml-service-principal"
   
   # Update stored credentials
   pass edit azure/ml-service-principal
   ```

## Next Steps

- Set up a password manager for your team
- Integrate Azure Key Vault into your MLOps workflows
- Implement pre-commit hooks to prevent committing secrets
- Create a credential rotation schedule
- Review the [Azure Security Best Practices](security-practices.md) wiki for more security guidance
