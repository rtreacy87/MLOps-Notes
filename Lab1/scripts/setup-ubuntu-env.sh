#!/bin/bash
# Setup script for Ubuntu WSL environment

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
