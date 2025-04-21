#!/bin/bash
# Script to manage API keys for ML projects using pass

# Function to show usage
show_usage() {
    echo "Usage: $0 [add|get|list] [service] [key_name]"
    echo ""
    echo "Commands:"
    echo "  add service key_name  - Add a new API key"
    echo "  get service key_name  - Retrieve an API key"
    echo "  list                  - List all stored API keys"
    echo ""
    echo "Examples:"
    echo "  $0 add azure subscription-key"
    echo "  $0 get azure subscription-key"
    echo "  $0 list"
}

# Check if pass is installed
if ! command -v pass &> /dev/null; then
    echo "Error: pass is not installed. Please run setup-pass.sh first."
    exit 1
fi

# Process commands
case "$1" in
    add)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Error: Missing service or key name"
            show_usage
            exit 1
        fi
        echo "Adding API key for $2/$3"
        pass insert "ml-projects/$2/$3"
        ;;
    get)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Error: Missing service or key name"
            show_usage
            exit 1
        fi
        pass "ml-projects/$2/$3"
        ;;
    list)
        echo "Stored API keys:"
        pass ls ml-projects
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
