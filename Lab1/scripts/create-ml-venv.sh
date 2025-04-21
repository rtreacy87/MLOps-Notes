#!/bin/bash
# Script to create a Python virtual environment for ML projects

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
