# Run this script after installing VS Code

# List of extensions to install
$extensions = @(
    "ms-python.python",                 # Python support
    "ms-toolsai.jupyter",               # Jupyter Notebooks
    "ms-vscode-remote.remote-wsl",      # WSL integration
    "ms-azuretools.vscode-docker",      # Docker integration
    "ms-azure-devops.azure-pipelines",  # Azure Pipelines
    "GitHub.copilot",                   # GitHub Copilot (if licensed)
    "ms-vscode.azure-account",          # Azure Account
    "ms-vscode.azurecli",               # Azure CLI Tools
    "redhat.vscode-yaml"                # YAML support
)

# Install each extension
foreach ($extension in $extensions) {
    Write-Host "Installing extension: $extension"
    code --install-extension $extension
}

Write-Host "All extensions have been installed!" -ForegroundColor Green
