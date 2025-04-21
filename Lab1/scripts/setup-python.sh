#!/bin/bash
# Script to set up Python environment

echo "Setting up Python environment..."

# Update package lists
sudo apt update

# Install Python and development tools
echo "Installing Python and development tools..."
sudo apt install -y python3 python3-pip python3-dev python3-venv

# Install build tools
echo "Installing build tools..."
sudo apt install -y build-essential libssl-dev libffi-dev

# Upgrade pip
echo "Upgrading pip..."
python3 -m pip install --upgrade pip

# Install common Python tools
echo "Installing common Python tools..."
python3 -m pip install --user pipx
python3 -m pipx ensurepath
python3 -m pip install --user black isort flake8 mypy pytest

echo "Python setup complete!"
echo "Python version: $(python3 --version)"
echo "Pip version: $(pip3 --version)"
