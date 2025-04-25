# Setting Up Password Management with Pass

This guide covers how to set up `pass`, the standard Unix password manager, for secure storage of API keys and credentials in your WSL environment.

## Prerequisites

- [WSL with Ubuntu installed](02-wsl-setup.md)
- [Python environment setup](04-python-environment-setup.md)
- Basic familiarity with command line operations

## What is Pass?

`pass` is a simple password manager that follows the Unix philosophy. It stores passwords in encrypted GPG files organized in a directory structure. Key features:

- Passwords are stored in GPG-encrypted files
- Organized in a directory hierarchy
- Git integration for version control and synchronization
- Command-line interface with bash completion
- Can be extended with plugins

For a comprehensive guide on using `pass` effectively, including synchronization across devices, browser integration, mobile access, and automation, see our [Pass Workflow Guide](supplementary/pass-workflow-wiki.md).

## Installation and Setup

### Step 1: Install Required Packages

#### For WSL/Ubuntu

Run the following commands in your WSL Ubuntu terminal:

```bash
# Update package lists
sudo apt update

# Install pass and its dependencies
sudo apt install -y pass gnupg2
```

#### For macOS

Run the following commands in your macOS terminal:

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install pass and its dependencies
brew install pass gnupg pinentry-mac

# Configure GPG to use the macOS pinentry program
mkdir -p ~/.gnupg
cat > ~/.gnupg/gpg-agent.conf << EOF
pinentry-program $(which pinentry-mac)
default-cache-ttl 600
max-cache-ttl 7200
EOF

# Restart the GPG agent
gpgconf --kill gpg-agent
```

##### Fixing "Unsafe Permissions" Warning on macOS

If you see the warning `gpg: WARNING: unsafe permissions on homedir '/Users/your_username/.gnupg'`, run these commands to fix it:

```bash
# Set the correct ownership (replace with your username)
CURRENT_USER=$(whoami)
sudo chown -R "$CURRENT_USER:staff" ~/.gnupg

# Set the correct permissions for the directory
chmod 700 ~/.gnupg

# Set the correct permissions for all files
find ~/.gnupg -type f -exec chmod 600 {} \; 2>/dev/null || true

# Set the correct permissions for all subdirectories
find ~/.gnupg -type d -exec chmod 700 {} \; 2>/dev/null || true

# Create a gpg.conf file with proper permissions
touch ~/.gnupg/gpg.conf
chmod 600 ~/.gnupg/gpg.conf

# Add option to suppress permission warnings if they persist
echo "no-permission-warning" >> ~/.gnupg/gpg.conf

# Restart the GPG agent
gpgconf --kill gpg-agent
```

**Line-by-Line Explanation:**

1. `CURRENT_USER=$(whoami)`
   - **What it does:** Gets your current username and stores it in the variable `CURRENT_USER`
   - **Why it's important:** We need your username to set the correct ownership of the .gnupg directory
   - **How to verify:** To check if the variable was set correctly, run `echo $CURRENT_USER` - this should display your username
   - **If you get an error:** If you see `zsh: bad substitution`, your shell might be interpreting the `$` character differently. Try running this command by itself first, or replace it with your actual username manually

2. `sudo chown -R "$CURRENT_USER:staff" ~/.gnupg`
   - **What it does:** Changes the ownership of the .gnupg directory and all its contents to your user and the staff group
   - **Why it's important:** GPG requires that you own your .gnupg directory
   - **If you get an error:** Replace `"$CURRENT_USER:staff"` with your actual username, like `"john:staff"` or just run `sudo chown -R $(whoami):staff ~/.gnupg` as a single command

3. `chmod 700 ~/.gnupg`
   - **What it does:** Sets permissions on the .gnupg directory so only you can access it
   - **Why it's important:** GPG requires that only the owner can read, write, or enter the directory
   - **No modification needed:** This should work as is

4. `find ~/.gnupg -type f -exec chmod 600 {} \; 2>/dev/null || true`
   - **What it does:** Finds all files in the .gnupg directory and sets permissions so only you can read/write them
   - **Why it's important:** GPG requires that all configuration files have strict permissions
   - **No modification needed:** The `2>/dev/null || true` part suppresses errors if no files exist yet

5. `find ~/.gnupg -type d -exec chmod 700 {} \; 2>/dev/null || true`
   - **What it does:** Finds all subdirectories in .gnupg and sets permissions so only you can access them
   - **Why it's important:** GPG requires that all directories have strict permissions
   - **No modification needed:** This should work as is

6. `touch ~/.gnupg/gpg.conf`
   - **What it does:** Creates an empty gpg.conf file if it doesn't exist
   - **Why it's important:** We need this file to add configuration options
   - **No modification needed:** This should work as is

7. `chmod 600 ~/.gnupg/gpg.conf`
   - **What it does:** Sets permissions on the gpg.conf file so only you can read/write it
   - **Why it's important:** GPG requires that configuration files have strict permissions
   - **No modification needed:** This should work as is

8. `echo "no-permission-warning" >> ~/.gnupg/gpg.conf`
   - **What it does:** Adds an option to gpg.conf to suppress permission warnings
   - **Why it's important:** This is a fallback in case the permission fixes don't resolve all warnings
   - **No modification needed:** This should work as is

9. `gpgconf --kill gpg-agent`
   - **What it does:** Restarts the GPG agent to apply all the changes
   - **Why it's important:** Changes won't take effect until the agent is restarted
   - **No modification needed:** This should work as is

**Alternative Fix for zsh Users:**

If you're using zsh and experiencing the "bad substitution" error, try these commands instead:

```bash
# Set ownership manually (replace 'yourusername' with your actual username)
sudo chown -R yourusername:staff ~/.gnupg

# Or use this single command that doesn't require variables
sudo chown -R $(whoami):staff ~/.gnupg
```

### Step 2: Generate a GPG Key Pair

Before using `pass`, you need to create a GPG key pair:

```bash
# Generate a GPG key pair
gpg --full-generate-key
```

Follow the prompts:
1. Select key type: Choose `RSA and RSA` (default)
2. Key size: Choose `4096` for stronger security
3. Validity period: Choose how long the key should be valid (0 = does not expire)
4. Provide your user information:
   - Real name: Your name
   - Email address: Your email
   - Comment: Optional
5. Set a secure passphrase (you'll need this to decrypt passwords)

### Step 3: Initialize the Password Store

Initialize the password store with your GPG key:

```bash
# Get your GPG key ID
gpg --list-secret-keys --keyid-format LONG

# Look for a line like: sec   rsa4096/1A2B3C4D5E6F7G8H
# The part after the slash is your key ID (1A2B3C4D5E6F7G8H in this example)

# Initialize the password store with your key ID
pass init "YOUR_GPG_KEY_ID"
```

### Step 4: Create a Script to Set Up Pass

#### For WSL/Ubuntu

Create an automated setup script for `pass` on Ubuntu/WSL:

```bash
#!/bin/bash
# Save this as setup-pass.sh

# Check if pass is already installed
if ! command -v pass &> /dev/null; then
    echo "Installing pass and dependencies..."
    sudo apt update
    sudo apt install -y pass gnupg2
else
    echo "pass is already installed."
fi

# Check if GPG key exists
if ! gpg --list-secret-keys | grep -q "sec"; then
    echo "No GPG key found. Generating a new GPG key..."

    # Generate a GPG key non-interactively
    cat > /tmp/gpg-gen-key << EOF
%echo Generating a GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $(whoami)
Name-Email: $(whoami)@example.com
Expire-Date: 0
Passphrase: $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
%commit
%echo Done
EOF

    gpg --batch --generate-key /tmp/gpg-gen-key
    rm /tmp/gpg-gen-key

    echo "GPG key generated."
    echo "IMPORTANT: Save the passphrase shown above in a secure location!"
else
    echo "GPG key already exists."
fi

# Get the GPG key ID
GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d'/' -f2)

# Initialize the password store if it doesn't exist
if [ ! -d ~/.password-store ]; then
    echo "Initializing password store with key ID: $GPG_KEY_ID"
    pass init "$GPG_KEY_ID"
else
    echo "Password store already initialized."
fi

# Set up Git for the password store
echo "Setting up Git for the password store..."
pass git init

echo "Password management setup complete!"
echo "Your GPG key ID is: $GPG_KEY_ID"
echo "Use 'pass insert service/username' to add a new password."
echo "Use 'pass service/username' to retrieve a password."
```

Make the script executable and run it:

```bash
chmod +x setup-pass.sh
./setup-pass.sh
```

#### For macOS

We've created a dedicated setup script for macOS users. You can find it at `scripts/setup-pass-macos.sh` in this repository. Here's how to use it:

```bash
# Navigate to the scripts directory
cd scripts

# Make the script executable if it's not already
chmod +x setup-pass-macos.sh

# Run the script
./setup-pass-macos.sh
```

The script will:
1. Install Homebrew if needed
2. Install pass, GPG, and pinentry-mac
3. Configure GPG to use the macOS pinentry program
4. Generate a GPG key if you don't have one
5. Initialize pass with your GPG key
6. Optionally install the Pass for macOS GUI application
7. Optionally set up browser integration

## Using Pass for API Keys and Credentials

### Adding a New Password or API Key

```bash
# General syntax
pass insert category/service/username

# Examples
pass insert azure/subscription-key
pass insert github/personal-access-token
pass insert openai/api-key
```

When prompted, enter your API key or password.

### Retrieving a Password or API Key

```bash
# General syntax
pass category/service/username

# Examples
pass azure/subscription-key
pass github/personal-access-token
```

### Using API Keys in Scripts

You can use `pass` in your scripts to securely retrieve API keys:

```bash
#!/bin/bash
# Example script using an API key from pass

# Get the API key
API_KEY=$(pass azure/subscription-key)

# Use the API key
curl -H "Authorization: Bearer $API_KEY" https://api.example.com/data
```

### Creating a Script to Manage ML Project API Keys

Create a script to help manage API keys for ML projects:

```bash
#!/bin/bash
# Save this as ml-api-keys.sh

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
```

Make the script executable and use it:

```bash
chmod +x ml-api-keys.sh
./ml-api-keys.sh add azure subscription-key
./ml-api-keys.sh get azure subscription-key
./ml-api-keys.sh list
```

## Setting Up Pass for Multiple Devices

If you want to use your passwords on multiple devices, you can use Git to synchronize your password store:

```bash
# Initialize Git repository (if not done already)
pass git init

# Add a remote repository (replace with your own repository URL)
pass git remote add origin git@github.com:yourusername/password-store.git

# Push your passwords to the remote repository
pass git push -u origin master
```

On another device, after setting up GPG with the same key:

```bash
# Clone the password store
git clone git@github.com:yourusername/password-store.git ~/.password-store
```

## Next Steps

After setting up password management, proceed to [setting up an Azure DevOps board](06-devops-board-setup.md) for project management.
