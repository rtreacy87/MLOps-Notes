# Installing Visual Studio Code on Windows

This guide covers how to install Visual Studio Code on Windows using command-line tools and automation.

## Option 1: Install Using PowerShell Script

The following PowerShell script will download and install the latest version of VS Code:

```powershell
# Run this script in PowerShell with administrator privileges

# Create a temporary directory
$tempDir = Join-Path $env:TEMP "VSCodeInstall"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download the latest VS Code installer
$installerPath = Join-Path $tempDir "VSCodeSetup.exe"
Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile $installerPath

# Install VS Code silently with default options
Start-Process -FilePath $installerPath -Args "/VERYSILENT /MERGETASKS=!runcode" -Wait

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "VS Code has been installed successfully!" -ForegroundColor Green
```

Save this script as `install-vscode.ps1` and run it with administrator privileges.

## Option 2: Install Using Chocolatey

If you have [Chocolatey](https://chocolatey.org/) package manager installed, you can use a single command:

```powershell
# Run this in PowerShell with administrator privileges
choco install vscode -y
```

### Installing Chocolatey (if needed)

If you don't have Chocolatey installed, you can install it with this PowerShell command:

```powershell
# Run this in PowerShell with administrator privileges
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

## Option 3: Install Using winget

Windows 10 (with appropriate updates) and Windows 11 come with the Windows Package Manager (winget):

```powershell
# Run this in PowerShell or Command Prompt
winget install Microsoft.VisualStudioCode
```

## Automating VS Code Extensions Installation

Create a PowerShell script to install common extensions for ML development:

```powershell
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
```

Save this script as `install-vscode-extensions.ps1` and run it after VS Code is installed.

## Verifying the Installation

Run the following command to verify that VS Code was installed correctly:

```powershell
code --version
```

This should display the VS Code version number.

## Next Steps

After installing VS Code, proceed to [setting up WSL](02-wsl-setup.md) to create your Linux development environment.
