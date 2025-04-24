# Configuring Azure DevOps Authentication in WSL

This guide will help you set up proper authentication for Azure DevOps in Windows Subsystem for Linux (WSL) to successfully clone, push, and interact with Azure DevOps repositories.

## Understanding Azure DevOps Authentication Options

Azure DevOps supports several authentication methods:
- Personal Access Tokens (PAT)
- SSH Keys
- Azure Active Directory (AAD)
- Git Credential Manager

## Method 1: Using Personal Access Token (PAT)

### Step 1: Generate an Azure DevOps Personal Access Token

1. Go to Azure DevOps and sign in
2. Click your profile picture in the top right → Personal access tokens
3. Click "New Token"
4. Give your token a descriptive name (e.g., "WSL DevOps Access")
5. Set expiration (recommended: 90 days)
6. Select scopes:
   - For full repository access: "Code (Read & Write)"
   - For build pipelines: "Build (Read & Execute)"
   - For releases: "Release (Read, Write, Execute & Manage)"
7. Click "Create"
8. Copy the token immediately (you won't see it again!)

### Step 2: Configure Git Credential Storage

```bash
# Configure credential helper to cache your credentials
git config --global credential.helper store

# Or use credential manager with a timeout (in seconds)
git config --global credential.helper 'cache --timeout=3600'

# Or use Windows credential manager
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
```

### Step 3: Use the Token

Next time you clone or push to an Azure DevOps repository, use:
- Username: Your Azure DevOps email address
- Password: Your Personal Access Token (not your Azure DevOps password)

Example of cloning with PAT:

```bash
git clone https://dev.azure.com/organization/project/_git/repository
# When prompted, use your PAT as the password
```

## Method 2: Using SSH Keys (Recommended)

### Step 1: Generate or Reuse SSH Keys

**Important Note**: Azure DevOps only accepts RSA keys for SSH authentication. Ed25519 keys are not supported.

```bash
# Generate a new RSA SSH key (4096 bits recommended for security)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Press Enter to accept default file location (typically ~/.ssh/id_rsa)
# Enter a passphrase (optional but recommended)
```

### Step 2: Add SSH Key to SSH Agent

```bash
# Start the ssh-agent
eval "$(ssh-agent -s)"

# Add your SSH private key
ssh-add ~/.ssh/id_rsa
```

For persistent SSH agent configuration, refer to the [SSH Agent Configuration Wiki](ssh-agent-configuration.md).

### Step 3: Add SSH Key to Azure DevOps

1. Copy your public key:
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```

2. Go to Azure DevOps → User settings → SSH public keys
3. Click "New Key"
4. Paste the entire key (including `ssh-rsa` and your email)
5. Give it a descriptive name and save

### Step 4: Update or Clone with SSH URL

For existing repositories, update the remote URL:

```bash
# Change from HTTPS to SSH
git remote set-url origin git@ssh.dev.azure.com:v3/organization/project/repository

# Verify the change
git remote -v
```

For new repositories, clone using SSH:

```bash
git clone git@ssh.dev.azure.com:v3/organization/project/repository
```

## Method 3: Using Azure CLI Authentication

### Step 1: Install and Configure Azure CLI

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Set up DevOps extension
az extension add --name azure-devops

# Configure defaults
az devops configure --defaults organization=https://dev.azure.com/organization project=project
```

### Step 2: Generate Git Credentials

```bash
# Generate Git credentials
az repos credential create --output json
```

This will output a username and password you can use for Git operations.

## Method 4: Using Git Credential Manager

If you're using WSL, you can leverage the Windows Git Credential Manager:

```bash
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
```

This allows your WSL Git to use the same credentials as your Windows Git installation.

## Troubleshooting

### Clear Cached Credentials

```bash
# Clear any cached credentials
git credential-cache exit
git credential reject https://dev.azure.com
```

### Test Connection

```bash
# For SSH
ssh -T git@ssh.dev.azure.com

# For HTTPS
git ls-remote https://organization@dev.azure.com/organization/project/_git/repository
```

### Permission Issues

If you encounter permission issues:

1. Verify your PAT has the correct scopes
2. Check if your PAT has expired
3. Ensure your SSH key is properly added to Azure DevOps
4. Verify you're using the correct organization and project names

## Setting Up Continuous Integration with Azure DevOps

### Configuring Service Connections

To allow Azure DevOps pipelines to access external resources:

1. Go to Project Settings → Service connections → New service connection
2. Select the connection type (e.g., Azure Resource Manager)
3. Fill in the required details
4. Use a descriptive name for the connection
5. Save the connection

### Creating a Service Principal for Automation

For automated scripts that interact with Azure DevOps:

```bash
# Create a service principal
az ad sp create-for-rbac --name "DevOps-Automation" --role contributor --scopes /subscriptions/<subscription-id>

# Store the output securely - it contains credentials!
```

Use the service principal credentials in your automation scripts:

```bash
# Login with service principal
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>

# Now you can run Azure DevOps commands
az devops project list
```

## Best Practices

1. **Use RSA SSH keys when possible**: They provide better security and convenience (remember Azure DevOps only supports RSA keys, not Ed25519)
2. **Set token expiration**: Always set reasonable expiration dates for PATs
3. **Use minimal permissions**: Only grant necessary scopes to tokens
4. **Regularly rotate credentials**: Update tokens and keys periodically
5. **Store credentials securely**: Use a password manager for PATs and service principal credentials
6. **Use service connections**: For CI/CD pipelines, use service connections instead of personal credentials

## Automating Authentication for CI/CD

### Important Note About SSH Keys for Azure DevOps

Remember that Azure DevOps only supports RSA SSH keys, not Ed25519 keys. When setting up automation or CI/CD processes that use SSH authentication, ensure you're generating and using RSA keys.

For CI/CD pipelines that need to authenticate with Azure DevOps:

```yaml
# Example Azure Pipeline that authenticates to another repository
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- checkout: self
  persistCredentials: true

- script: |
    git config --global user.email "pipeline@example.com"
    git config --global user.name "Azure Pipeline"
    echo "Cloning another repository..."
    git clone https://$(System.AccessToken)@dev.azure.com/organization/project/_git/other-repo
  displayName: 'Clone with pipeline token'
```

The `$(System.AccessToken)` is a predefined variable that contains an automatically generated token with appropriate permissions.

## Summary

For the best experience with Azure DevOps in WSL:

1. Use RSA SSH keys for daily development work (Azure DevOps does not support Ed25519 keys)
2. Use PATs for scripts and automation
3. Configure Git with your name and email
4. Set up credential caching if using HTTPS
5. Consider using service principals for production automation

With these configurations, you should be able to seamlessly work with Azure DevOps repositories from WSL.
