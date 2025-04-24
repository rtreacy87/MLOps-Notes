# Setting Up Windows Subsystem for Linux (WSL)

This guide covers how to set up Windows Subsystem for Linux (WSL) with Ubuntu using scripts and automation.

## Prerequisites

- Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
- Administrator access

## Option 1: One-Command Installation (Windows 10 version 2004+ or Windows 11)

The simplest way to install WSL with Ubuntu is using a single PowerShell command:

```powershell
# Run this in PowerShell with administrator privileges
wsl --install -d Ubuntu
```

This command:
1. Enables the WSL and Virtual Machine Platform components
2. Downloads and installs the latest Linux kernel
3. Sets WSL 2 as the default
4. Downloads and installs the Ubuntu distribution

After installation completes, restart your computer when prompted. When you launch Ubuntu for the first time, you'll be asked to create a username and password.

## Option 2: Manual Installation with PowerShell Script

If you need more control over the installation process, you can use this PowerShell script:

```powershell
# Run this script in PowerShell with administrator privileges

# Enable WSL feature
Write-Host "Enabling Windows Subsystem for Linux..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "Please restart your computer now, then run the second part of this script." -ForegroundColor Yellow
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
```

After running this script, restart your computer, then run this second script:

```powershell
# Run this script after restarting

# Download the WSL2 Linux kernel update package
Write-Host "Downloading WSL2 Linux kernel update package..." -ForegroundColor Cyan
$wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$wslUpdateInstaller = "$env:TEMP\wsl_update_x64.msi"
Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdateInstaller -UseBasicParsing

# Install the WSL2 Linux kernel update package
Write-Host "Installing WSL2 Linux kernel update package..." -ForegroundColor Cyan
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $wslUpdateInstaller /quiet" -Wait

# Set WSL 2 as the default version
Write-Host "Setting WSL 2 as the default version..." -ForegroundColor Cyan
wsl --set-default-version 2

# Download and install Ubuntu
Write-Host "Installing Ubuntu..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://aka.ms/wslubuntu2004" -OutFile "$env:TEMP\Ubuntu.appx" -UseBasicParsing
Add-AppxPackage "$env:TEMP\Ubuntu.appx"

Write-Host "WSL2 and Ubuntu have been installed successfully!" -ForegroundColor Green
Write-Host "Launch Ubuntu from the Start menu to complete the setup." -ForegroundColor Green
```

## Configuring Your Ubuntu Environment

After installing Ubuntu, you'll need to set up your development environment. Create a script in your Ubuntu environment to automate this process:

```bash
#!/bin/bash
# Save this as setup-ubuntu-env.sh

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install essential development tools
echo "Installing development tools..."
sudo apt install -y build-essential git curl wget unzip

# Install Python and pip
echo "Installing Python and pip..."
sudo apt install -y python3 python3-pip python3-venv

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Docker (optional)
echo "Do you want to install Docker? (y/n)"
read install_docker
if [[ $install_docker == "y" ]]; then
    echo "Installing Docker..."
    sudo apt install -y apt-transport-https ca-certificates gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    echo "Docker installed. You'll need to log out and back in for group changes to take effect."
fi

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
mkdir -p ~/projects/mlops
cd ~/projects/mlops
python3 -m venv venv
echo 'source ~/projects/mlops/venv/bin/activate' >> ~/.bashrc

echo "Environment setup complete!"
```

To use this script:
1. Open Ubuntu from the Start menu
2. Create the script: `nano setup-ubuntu-env.sh`
3. Paste the content above
4. Save and exit (Ctrl+X, then Y, then Enter)
5. Make it executable: `chmod +x setup-ubuntu-env.sh`
6. Run it: `./setup-ubuntu-env.sh`

## Managing WSL from the Command Line

### Verifying WSL Installation

To verify that WSL is installed correctly and see all installed distributions:

```powershell
# Run in PowerShell or Command Prompt
wsl --list --verbose
```

This should show Ubuntu running on WSL version 2.

### Activating Ubuntu WSL

To start and activate Ubuntu WSL from PowerShell or Command Prompt:

```powershell
# Run in PowerShell or Command Prompt
wsl.exe -d Ubuntu
```

This command launches Ubuntu and switches your terminal to the Ubuntu environment. You'll see the prompt change to indicate you're now in Linux.

### Running Commands in WSL Without Switching Environment

To run a single command in WSL without switching your terminal environment:

```powershell
# Run in PowerShell or Command Prompt
wsl [command]

# Example: List files in your Ubuntu home directory
wsl ls -la ~
```

### Shutting Down WSL

#### From Windows (PowerShell or Command Prompt)

To shut down a specific WSL distribution:

```powershell
# Run in PowerShell or Command Prompt
wsl --terminate Ubuntu
```

To shut down all running WSL distributions:

```powershell
# Run in PowerShell or Command Prompt
wsl --shutdown
```

#### From Within WSL

To exit a WSL session and return to Windows command prompt:

```bash
# Simply type exit or press Ctrl+D
exit
```

To logout of the current user session in WSL:

```bash
logout
```

To shutdown the WSL instance from within Ubuntu:

```bash
# This will shut down the entire WSL instance
sudo shutdown now
```

> **Note**: Using `exit` or `logout` only closes your current terminal session but leaves the WSL distribution running in the background. To completely shut down WSL and free up resources, use the PowerShell commands above or the `shutdown` command from within WSL.

#### When to Keep WSL Running vs. When to Shut Down

**Reasons to keep WSL running in the background:**

- **Faster startup**: When you need to frequently switch between Windows and WSL, keeping WSL running allows for instant access without waiting for it to initialize
- **Background services**: If you're running services like web servers, databases, or development environments that need to remain accessible
- **Long-running processes**: For tasks like training ML models, data processing, or simulations that need to continue even when you're not actively using the terminal
- **Development workflow**: During active development sessions where you'll be returning to WSL frequently
- **Resource usage is minimal**: When idle, WSL typically uses very little memory and CPU

**Reasons to shut down WSL completely:**

- **Conserve resources**: On systems with limited RAM or when you need maximum performance for other applications
- **Battery life**: When working on a laptop and trying to maximize battery life
- **System stability**: If you're experiencing any WSL-related issues or conflicts with other virtualization software
- **Security**: When working with sensitive data and want to ensure the environment is completely closed
- **System maintenance**: Before system updates, restarts, or when you won't be using WSL for an extended period
- **Troubleshooting**: When you need to reset the WSL environment to resolve issues

### Setting Default WSL Distribution

If you have multiple WSL distributions installed, you can set Ubuntu as the default:

```powershell
# Run in PowerShell or Command Prompt
wsl --set-default Ubuntu
```

After setting the default, you can simply use `wsl` without specifying a distribution to launch Ubuntu.

## Appendix: Common Issues and Solutions

### Upgrading Node.js from Version 16 to 22

If you have an existing WSL installation with Node.js 16 (which is now deprecated), you should upgrade to Node.js 22 LTS. Here's how to safely upgrade:

#### Option 1: Using the NodeSource Repository (Recommended)

```bash
# Remove old Node.js repository source
sudo rm -f /etc/apt/sources.list.d/nodesource.list
sudo rm -f /etc/apt/sources.list.d/nodesource.list.save

# Remove existing Node.js installation
sudo apt purge -y nodejs
sudo apt autoremove -y

# Install the latest LTS version (Node.js 22.x)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Verify the installation
node --version  # Should show v22.x.x
npm --version   # Should show the corresponding npm version
```

#### Option 2: Using Node Version Manager (nvm)

If you prefer to manage multiple Node.js versions, you can use nvm:

```bash
# Install nvm if not already installed
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Reload shell configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js 22 LTS
nvm install --lts

# Set it as default
nvm alias default node

# Verify the installation
node --version  # Should show v22.x.x
npm --version   # Should show the corresponding npm version
```

With nvm, you can easily switch between Node.js versions using `nvm use <version>` if needed for specific projects.

### Git Authentication Issues with GitHub

Many users encounter authentication problems when trying to push to GitHub repositories from WSL. This typically manifests as "Invalid username or password" errors, even when using correct credentials. This happens because:

1. GitHub no longer supports password authentication for Git operations
2. WSL and Windows have separate credential stores
3. Default Git configurations in WSL may not be properly set up for GitHub's authentication requirements

To resolve these issues, you have several options:

- Use SSH keys (recommended for most users)
- Configure Personal Access Tokens (PAT)
- Set up GitHub CLI
- Use Windows Credential Manager from WSL

For detailed instructions on solving GitHub authentication issues in WSL, refer to the [WSL Git Setup Wiki](supplementary/wsl-git-setup-wiki.md).


For detailed instructions on configuring authentication with Azure DevOps repositories [Azure DevOps Authentication Setup](supplementary/devops-authentication-wiki.md)

## Next Steps

After setting up WSL with Ubuntu, proceed to [configuring VS Code to use WSL](03-vscode-wsl-integration.md).
