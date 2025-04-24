# Setting Up Python and Virtual Environments

This guide covers how to install Python and set up both venv and Conda virtual environments for ML development using infrastructure as code principles.

> **Note:** For efficient management of virtual environments to minimize shell startup time, refer to the [Virtual Environments Wiki](supplementary/virtual-environments-wiki.md).

## Prerequisites

- [WSL with Ubuntu installed](02-wsl-setup.md)
- [VS Code with WSL integration](03-vscode-wsl-integration.md)

## Why Virtual Environments?

Virtual environments are isolated Python environments that allow you to:

- Install packages without affecting the system Python installation
- Create project-specific environments with different package versions
- Easily share environment configurations with teammates
- Avoid dependency conflicts between projects

For ML development, virtual environments are essential because:
- ML libraries often have complex dependencies
- Different ML projects may require different versions of libraries
- Reproducibility is critical for ML experiments

## Installing Python in WSL

WSL Ubuntu typically comes with Python 3 pre-installed, but it's good practice to ensure you have the latest version and necessary tools.

### Checking Existing Python Installation

```bash
# Check if Python is installed and its version
python3 --version

# Check if pip is installed
pip3 --version
```

### Installing/Updating Python

```bash
# Update package lists
sudo apt update

# Install Python and development tools
sudo apt install -y python3 python3-pip python3-dev python3-venv

# Install build tools for compiling some Python packages
sudo apt install -y build-essential libssl-dev libffi-dev
```

### Creating a Python Installation Script

Create a script to automate Python installation and setup:

```bash
#!/bin/bash
# Save this as setup-python.sh

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
```

Make the script executable and run it:

```bash
chmod +x setup-python.sh
./setup-python.sh
```

## Setting Up Python Virtual Environments (venv)

Python's built-in `venv` module is a lightweight way to create virtual environments.

### Creating a Virtual Environment with venv

```bash
# Create a project directory
mkdir -p ~/projects/my-ml-project
cd ~/projects/my-ml-project

# Create a virtual environment
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate
```

After activation, your prompt will change to indicate the active environment. Now you can install packages that will only affect this environment:

```bash
# Install packages in the virtual environment
pip install numpy pandas scikit-learn matplotlib jupyter
```

### Creating a venv Setup Script

Create a script to automate virtual environment setup for ML projects:

```bash
#!/bin/bash
# Save this as create-ml-venv.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./create-ml-venv.sh project_name"
    exit 1
fi

PROJECT_NAME=$1
PROJECT_DIR=~/projects/$PROJECT_NAME

# Create project directory
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Create standard project structure
mkdir -p data src/models src/utils notebooks tests

# Create a README file
cat > README.md << EOF
# $PROJECT_NAME

ML project created with automated setup script.

## Setup

1. Activate the virtual environment:
   \`\`\`
   source .venv/bin/activate
   \`\`\`

2. Install dependencies:
   \`\`\`
   pip install -r requirements.txt
   \`\`\`
EOF

# Create a virtual environment
echo "Creating virtual environment..."
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Create a requirements.txt file with common ML packages
cat > requirements.txt << EOF
# Data manipulation
numpy>=1.20.0
pandas>=1.3.0
scipy>=1.7.0

# Machine learning
scikit-learn>=1.0.0
tensorflow>=2.8.0
torch>=1.10.0

# Visualization
matplotlib>=3.5.0
seaborn>=0.11.0

# Jupyter
jupyter>=1.0.0
ipykernel>=6.0.0

# Development tools
pytest>=6.0.0
black>=22.0.0
flake8>=4.0.0
isort>=5.0.0
EOF

# Install packages
echo "Installing packages..."
pip install -r requirements.txt

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

# Virtual Environment
.venv/
venv/
ENV/

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

# Models
*.pkl
*.h5
*.pt
*.pb
EOF

# Create VS Code settings
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "python.defaultInterpreterPath": "${PROJECT_DIR}/.venv/bin/python",
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

# Create a sample Python script
mkdir -p src/utils
cat > src/utils/data_loader.py << EOF
"""
Data loading utilities for $PROJECT_NAME.
"""

import pandas as pd
from pathlib import Path


def load_csv(file_path):
    """
    Load a CSV file into a pandas DataFrame.

    Args:
        file_path: Path to the CSV file

    Returns:
        pandas.DataFrame: The loaded data
    """
    return pd.read_csv(file_path)


def save_csv(df, file_path):
    """
    Save a pandas DataFrame to a CSV file.

    Args:
        df: pandas.DataFrame to save
        file_path: Path where the CSV file will be saved
    """
    # Create directory if it doesn't exist
    Path(file_path).parent.mkdir(parents=True, exist_ok=True)

    # Save the DataFrame
    df.to_csv(file_path, index=False)
    print(f"Data saved to {file_path}")
EOF

# Create a sample test
mkdir -p tests
cat > tests/test_data_loader.py << EOF
"""
Tests for data_loader module.
"""

import pandas as pd
import pytest
from src.utils.data_loader import load_csv, save_csv
import tempfile
import os


def test_save_and_load_csv():
    """Test that we can save and load a CSV file."""
    # Create a sample DataFrame
    data = {'col1': [1, 2, 3], 'col2': ['a', 'b', 'c']}
    df = pd.DataFrame(data)

    # Create a temporary file
    with tempfile.NamedTemporaryFile(suffix='.csv', delete=False) as tmp:
        tmp_path = tmp.name

    try:
        # Save the DataFrame
        save_csv(df, tmp_path)

        # Check that the file exists
        assert os.path.exists(tmp_path)

        # Load the DataFrame
        loaded_df = load_csv(tmp_path)

        # Check that the loaded DataFrame is equal to the original
        pd.testing.assert_frame_equal(df, loaded_df)
    finally:
        # Clean up
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
EOF

# Create a sample Jupyter notebook
mkdir -p notebooks
cat > notebooks/01-data-exploration.ipynb << EOF
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Exploration for $PROJECT_NAME"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "%matplotlib inline\n",
    "sns.set_style('whitegrid')"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Load Data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Add code to load your data\n",
    "# Example:\n",
    "# df = pd.read_csv('../data/your_data.csv')"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Explore Data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Add code to explore your data\n",
    "# Example:\n",
    "# df.head()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.10"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Register the kernel for Jupyter
python -m ipykernel install --user --name=$PROJECT_NAME --display-name="Python ($PROJECT_NAME)"

echo "Virtual environment setup complete for $PROJECT_NAME!"
echo "To activate the environment, run: source $PROJECT_DIR/.venv/bin/activate"
echo "To start Jupyter, run: jupyter notebook"
```

Make the script executable and run it:

```bash
chmod +x create-ml-venv.sh
./create-ml-venv.sh my-ml-project
```

### Managing venv Environments

```bash
# Activate the environment
source ~/projects/my-ml-project/.venv/bin/activate

# Deactivate the environment
deactivate

# List installed packages
pip list

# Export environment to requirements.txt
pip freeze > requirements.txt

# Install packages from requirements.txt
pip install -r requirements.txt
```

## Setting Up Conda for Virtual Environments

Conda is a more comprehensive environment and package manager, particularly useful for ML development because it can manage non-Python dependencies.

### Installing Miniconda

```bash
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
```

You'll need to restart your shell or run `source ~/.bashrc` for the changes to take effect.

### Creating a Conda Installation Script

```bash
#!/bin/bash
# Save this as install-conda.sh

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
```

Make the script executable and run it:

```bash
chmod +x install-conda.sh
./install-conda.sh
source ~/.bashrc
```

### Creating a Conda Environment

```bash
# Create a new Conda environment
conda create -n ml-env python=3.9

# Activate the environment
conda activate ml-env

# Install packages
conda install numpy pandas scikit-learn matplotlib jupyter

# Install packages from pip (if not available in Conda)
pip install some-package
```

### Creating a Conda Environment Setup Script

```bash
#!/bin/bash
# Save this as create-ml-conda.sh

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./create-ml-conda.sh project_name"
    exit 1
fi

PROJECT_NAME=$1
PROJECT_DIR=~/projects/$PROJECT_NAME

# Create project directory
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Create standard project structure
mkdir -p data src/models src/utils notebooks tests

# Create a README file
cat > README.md << EOF
# $PROJECT_NAME

ML project created with automated setup script using Conda.

## Setup

1. Activate the Conda environment:
   \`\`\`
   conda activate $PROJECT_NAME
   \`\`\`

2. Install dependencies:
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
  - numpy>=1.20.0
  - pandas>=1.3.0
  - scipy>=1.7.0
  - scikit-learn>=1.0.0
  - matplotlib>=3.5.0
  - seaborn>=0.11.0
  - jupyter>=1.0.0
  - ipykernel>=6.0.0
  - pytest>=6.0.0
  - pip>=21.0.0
  - pip:
    - tensorflow>=2.8.0
    - torch>=1.10.0
    - black>=22.0.0
    - flake8>=4.0.0
    - isort>=5.0.0
EOF

# Create the Conda environment
echo "Creating Conda environment..."
conda env create -f environment.yml

# Create a .gitignore file
cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
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

# Models
*.pkl
*.h5
*.pt
*.pb
EOF

# Create VS Code settings
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

# Activate the environment and register the kernel for Jupyter
echo "Registering Jupyter kernel..."
conda activate $PROJECT_NAME
python -m ipykernel install --user --name=$PROJECT_NAME --display-name="Python ($PROJECT_NAME)"

echo "Conda environment setup complete for $PROJECT_NAME!"
echo "To activate the environment, run: conda activate $PROJECT_NAME"
echo "To start Jupyter, run: jupyter notebook"
```

Make the script executable and run it:

```bash
chmod +x create-ml-conda.sh
./create-ml-conda.sh my-conda-project
```

### Managing Conda Environments

```bash
# List all Conda environments
conda env list

# Activate an environment
conda activate my-conda-project

# Deactivate the current environment
conda deactivate

# Export environment to YAML file
conda env export > environment.yml

# Create environment from YAML file
conda env create -f environment.yml

# Update environment from YAML file
conda env update -f environment.yml

# Remove an environment
conda env remove -n my-conda-project
```

## Integrating with VS Code

VS Code can automatically detect and use your virtual environments.

### Configuring VS Code for Python Development

1. Install the Python extension in VS Code if you haven't already
2. Open your project folder in VS Code
3. Press `Ctrl+Shift+P` to open the Command Palette
4. Type "Python: Select Interpreter" and select it
5. Choose your virtual environment from the list

### Creating a VS Code Python Configuration Script

```bash
#!/bin/bash
# Save this as setup-vscode-python.sh

# Check if project directory is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project directory"
    echo "Usage: ./setup-vscode-python.sh project_directory"
    exit 1
fi

PROJECT_DIR=$1

# Check if directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Directory $PROJECT_DIR does not exist"
    exit 1
fi

# Create VS Code settings directory
mkdir -p "$PROJECT_DIR/.vscode"

# Create settings.json
cat > "$PROJECT_DIR/.vscode/settings.json" << EOF
{
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.linting.pylintEnabled": false,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true,
    "python.testing.pytestEnabled": true,
    "python.testing.unittestEnabled": false,
    "python.testing.nosetestsEnabled": false,
    "python.testing.pytestArgs": [
        "tests"
    ],
    "python.analysis.extraPaths": [
        "${workspaceFolder}"
    ],
    "jupyter.notebookFileRoot": "${workspaceFolder}"
}
EOF

# Create launch.json for debugging
cat > "$PROJECT_DIR/.vscode/launch.json" << EOF
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "\${file}",
            "console": "integratedTerminal",
            "justMyCode": false
        },
        {
            "name": "Python: Debug Tests",
            "type": "python",
            "request": "launch",
            "program": "\${file}",
            "purpose": ["debug-test"],
            "console": "integratedTerminal",
            "justMyCode": false
        }
    ]
}
EOF

echo "VS Code Python configuration created in $PROJECT_DIR/.vscode/"
```

Make the script executable and run it:

```bash
chmod +x setup-vscode-python.sh
./setup-vscode-python.sh ~/projects/my-ml-project
```

## Comparing venv and Conda

| Feature | venv | Conda |
|---------|------|-------|
| **Package Management** | Python packages only | Python and non-Python packages |
| **Installation** | Built into Python | Separate installation required |
| **Ease of Use** | Simple, lightweight | More complex, more features |
| **Cross-Platform** | Limited on Windows | Works well on all platforms |
| **Package Sources** | PyPI | Conda repositories and PyPI |
| **Environment Sharing** | requirements.txt | environment.yml |
| **System Integration** | Minimal | More integrated |
| **ML Development** | Good for simple projects | Better for complex ML projects |

### When to Use venv

- For simple Python-only projects
- When you want a lightweight solution
- When you don't need non-Python dependencies
- When working with web development or simple scripts

### When to Use Conda

- For complex ML projects with non-Python dependencies
- When working with data science libraries that have complex dependencies
- When you need specific versions of packages that are difficult to install with pip
- When you need to manage environments across different platforms

## Best Practices for ML Environment Management

1. **Version Control Your Environment Files**:
   - Always include `requirements.txt` or `environment.yml` in your repository
   - Update these files when you add new dependencies

2. **Use Specific Versions**:
   - Pin package versions to ensure reproducibility
   - Example: `numpy==1.20.3` instead of just `numpy`

3. **Document Environment Setup**:
   - Include setup instructions in your README
   - Provide scripts for environment creation

4. **Separate Development and Production Environments**:
   - Keep development tools separate from production dependencies
   - Consider using separate files: `requirements-dev.txt` and `requirements.txt`

5. **Regularly Update Dependencies**:
   - Check for security updates
   - Test your code with updated dependencies

6. **Use Environment Variables for Configuration**:
   - Store sensitive information in environment variables, not in code
   - Use a `.env` file for local development (but don't commit it)

## Next Steps

After setting up your Python environment, proceed to [setting up password management](05-password-management.md) for secure storage of API keys and credentials.
