#!/bin/bash
# Script to create a new ML project with VS Code integration

# Check if project name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a project name"
    echo "Usage: ./create-ml-project.sh project_name"
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

ML project created with automated setup script.

## Project Structure

- \`data/\`: Data files
- \`src/models/\`: Model training code
- \`src/pipelines/\`: ML pipeline definitions
- \`config/\`: Configuration files
- \`notebooks/\`: Jupyter notebooks
- \`tests/\`: Unit and integration tests
EOF

# Create a Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install basic packages
pip install numpy pandas scikit-learn matplotlib jupyter

# Create a requirements.txt file
cat > requirements.txt << EOF
numpy
pandas
scikit-learn
matplotlib
jupyter
pytest
black
flake8
EOF

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
EOF

# Initialize git repository
git init

# Create VS Code workspace settings
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

echo "Project $PROJECT_NAME has been created at $PROJECT_DIR"
echo "To open it in VS Code, run: code $PROJECT_DIR"
