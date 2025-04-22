#!/bin/bash
# Script to create a new ML project with VS Code integration using Conda

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
