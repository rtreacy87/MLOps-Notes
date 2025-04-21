#!/bin/bash
# Script to set up VS Code for Python development

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
        "\${workspaceFolder}"
    ],
    "jupyter.notebookFileRoot": "\${workspaceFolder}"
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
