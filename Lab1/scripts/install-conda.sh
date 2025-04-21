#!/bin/bash
# Script to install Miniconda

echo "Installing Miniconda..."

# Download Miniconda installer
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh

# Make the installer executable
chmod +x ~/miniconda.sh

# Run the installer
~/miniconda.sh -b -p $HOME/miniconda

# Remove the installer
rm ~/miniconda.sh

# Initialize Conda
~/miniconda/bin/conda init bash

echo "Miniconda installation complete!"
echo "Please restart your shell or run 'source ~/.bashrc' to start using Conda."
