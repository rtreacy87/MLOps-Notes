# Configuring VS Code to Use WSL as Default Terminal

This guide covers how to integrate Visual Studio Code with Windows Subsystem for Linux (WSL) and set WSL as the default terminal.

## Prerequisites

- [Visual Studio Code installed](01-vscode-installation.md)
- [WSL with Ubuntu installed](02-wsl-setup.md)

## Installing the Remote - WSL Extension

The Remote - WSL extension allows you to use WSL as your integrated development environment from VS Code.

### Option 1: Install via VS Code UI

1. Open VS Code
2. Click on the Extensions icon in the Activity Bar (or press `Ctrl+Shift+X`)
3. Search for "Remote - WSL"
4. Click "Install" on the "Remote - WSL" extension by Microsoft

### Option 2: Install via Command Line

Run this command in PowerShell:

```powershell
code --install-extension ms-vscode-remote.remote-wsl
```

## Setting WSL as the Default Terminal

### Option 1: Using VS Code Settings UI

1. Open VS Code
2. Press `Ctrl+,` to open Settings
3. Search for "terminal.integrated.defaultProfile.windows"
4. Click "Edit in settings.json"
5. Add or modify these settings:

```json
{
    "terminal.integrated.defaultProfile.windows": "Ubuntu (WSL)",
    "terminal.integrated.profiles.windows": {
        "Ubuntu (WSL)": {
            "path": "C:\\WINDOWS\\System32\\wsl.exe",
            "args": ["-d", "Ubuntu"]
        }
    }
}
```

### Option 2: Automated Script

Create a PowerShell script to automate this configuration:

```powershell
# Run this script to configure VS Code to use WSL as the default terminal

# Get the VS Code settings file path
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# Check if the settings file exists
if (Test-Path $settingsPath) {
    # Read the current settings
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
} else {
    # Create a new settings object if the file doesn't exist
    $settings = New-Object PSObject
    # Create the directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path (Split-Path $settingsPath) | Out-Null
}

# Add or update the terminal settings
$settings | Add-Member -NotePropertyName "terminal.integrated.defaultProfile.windows" -NotePropertyValue "Ubuntu (WSL)" -Force

# Create or update the profiles object
if (-not ($settings."terminal.integrated.profiles.windows")) {
    $settings | Add-Member -NotePropertyName "terminal.integrated.profiles.windows" -NotePropertyValue (@{}) -Force
}

# Add or update the Ubuntu WSL profile
$settings."terminal.integrated.profiles.windows" | Add-Member -NotePropertyName "Ubuntu (WSL)" -NotePropertyValue (@{
    "path" = "C:\\WINDOWS\\System32\\wsl.exe"
    "args" = @("-d", "Ubuntu")
}) -Force

# Save the updated settings
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath

Write-Host "VS Code has been configured to use WSL as the default terminal." -ForegroundColor Green
```

Save this script as `configure-vscode-wsl.ps1` and run it with PowerShell.

## Opening a Project in WSL

### Method 1: From VS Code

1. Press `F1` to open the Command Palette
2. Type "WSL: New Window" and select it
3. VS Code will open a new window connected to WSL

### Method 2: From WSL Terminal

1. Open your WSL terminal
2. Navigate to your project directory
3. Run `code .` to open VS Code with the current directory

### Method 3: Using the Remote Explorer

1. Click on the Remote Explorer icon in the Activity Bar
2. Under "WSL Targets", find your Ubuntu distribution
3. Click on the folder icon next to it to open a folder in WSL

## Creating a Script to Set Up a New Project with Conda

Create a bash script in your WSL environment to set up a new ML project with VS Code and Conda:

```bash
#!/bin/bash
# Save this as create-ml-project.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./create-ml-project.sh project_name"
    exit 1
fi

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo "Conda is not installed. Please install Miniconda or Anaconda first."
    echo "You can run: ./install-conda.sh"
    exit 1
fi

PROJECT_NAME=$1
PROJECT_DIR=~/projects/$PROJECT_NAME

# Create project directory
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Create standard project structure
mkdir -p data src/models src/pipelines config notebooks tests

# Create a README file
cat > README.md << EOF
# $PROJECT_NAME

ML project created with automated setup script using Conda.

## Project Structure

- \`data/\`: Data files
- \`src/models/\`: Model training code
- \`src/pipelines/\`: ML pipeline definitions
- \`config/\`: Configuration files
- \`notebooks/\`: Jupyter notebooks
- \`tests/\`: Unit and integration tests

## Setup

1. Activate the Conda environment:
   \`\`\`
   conda activate $PROJECT_NAME
   \`\`\`

2. Update the environment if needed:
   \`\`\`
   conda env update -f environment.yml
   \`\`\`
EOF

# Create a Conda environment file
cat > environment.yml << EOF
name: $PROJECT_NAME
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.9
  - numpy
  - pandas
  - scikit-learn
  - matplotlib
  - jupyter
  - ipykernel
  - pytest
  - pip
  - pip:
    - black
    - flake8
EOF

# Create the Conda environment
echo "Creating Conda environment '$PROJECT_NAME'..."
conda env create -f environment.yml

# Create a .gitignore file
cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Conda Environment
.conda/
miniconda/
anaconda/

# Jupyter Notebook
.ipynb_checkpoints

# VS Code
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# Data
data/
*.csv
*.parquet
*.h5
EOF

# Initialize git repository
git init

# Create VS Code workspace settings
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "python.defaultInterpreterPath": "~/miniconda/envs/$PROJECT_NAME/bin/python",
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true,
    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.nosetestsEnabled": false,
    "python.testing.pytestArgs": [
        "tests"
    ]
}
EOF

# Register the kernel for Jupyter
echo "Registering Jupyter kernel..."
conda activate $PROJECT_NAME
python -m ipykernel install --user --name=$PROJECT_NAME --display-name="Python ($PROJECT_NAME)"

echo "Project $PROJECT_NAME has been created at $PROJECT_DIR"
echo "To activate the Conda environment, run: conda activate $PROJECT_NAME"
echo "To open it in VS Code, run: code $PROJECT_DIR"
```

To use this script:
1. Make sure Conda is installed (see [Python Environment Setup](04-python-environment-setup.md))
2. Save the script as `create-ml-project.sh` in your WSL home directory
3. Make it executable: `chmod +x create-ml-project.sh`
4. Run it with a project name: `./create-ml-project.sh my-ml-project`
5. Activate the Conda environment: `conda activate my-ml-project`
6. Open the project in VS Code: `code ~/projects/my-ml-project`

## Verifying the Integration

To verify that VS Code is properly integrated with WSL:

1. Open VS Code
2. Press `` Ctrl+` `` to open the terminal
3. The terminal should open with your WSL Ubuntu shell
4. Check the bottom-left corner of VS Code - it should show "WSL: Ubuntu" indicating you're connected to WSL

## Next Steps

After configuring VS Code to use WSL, proceed to [setting up Python and virtual environments](04-python-environment-setup.md) for your ML development work.
