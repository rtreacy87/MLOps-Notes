#!/bin/bash
# Script to create a Conda environment for ML projects

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
