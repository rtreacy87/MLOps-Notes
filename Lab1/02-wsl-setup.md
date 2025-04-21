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
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
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

## Verifying WSL Installation

To verify that WSL is installed correctly and Ubuntu is running:

```powershell
# Run in PowerShell
wsl -l -v
```

This should show Ubuntu running on WSL version 2.

## Next Steps

After setting up WSL with Ubuntu, proceed to [configuring VS Code to use WSL](03-vscode-wsl-integration.md).
