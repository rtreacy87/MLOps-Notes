#!/bin/bash
# Script to set up pass password manager on macOS

echo "Setting up pass password manager on macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs if needed
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew is already installed."
fi

# Install required packages
echo "Installing required packages..."
brew install pass gnupg pinentry-mac

# Configure GPG to use pinentry-mac
echo "Configuring GPG..."

# Create the .gnupg directory if it doesn't exist
mkdir -p ~/.gnupg

# Set the correct ownership (get current user)
CURRENT_USER=$(whoami)
sudo chown -R "$CURRENT_USER:staff" ~/.gnupg

# Set the correct permissions for the directory
chmod 700 ~/.gnupg

# Set the correct permissions for all files in the directory
find ~/.gnupg -type f -exec chmod 600 {} \; 2>/dev/null || true

# Set the correct permissions for all subdirectories
find ~/.gnupg -type d -exec chmod 700 {} \; 2>/dev/null || true

# Find pinentry-mac path
PINENTRY_PATH=$(which pinentry-mac)
if [ -z "$PINENTRY_PATH" ]; then
    echo "Error: pinentry-mac not found. Please install it manually with 'brew install pinentry-mac'."
    exit 1
fi

# Create or update gpg-agent.conf
cat > ~/.gnupg/gpg-agent.conf << EOF
pinentry-program $PINENTRY_PATH
default-cache-ttl 3600
max-cache-ttl 7200
EOF

# Create or update gpg.conf to prevent permission warnings
touch ~/.gnupg/gpg.conf
if ! grep -q "no-permission-warning" ~/.gnupg/gpg.conf; then
    echo "no-permission-warning" >> ~/.gnupg/gpg.conf
fi

# Set proper permissions for all configuration files
chmod 600 ~/.gnupg/gpg-agent.conf
chmod 600 ~/.gnupg/gpg.conf

# Restart GPG agent
gpgconf --kill gpg-agent

# Check if GPG key exists
if ! gpg --list-secret-keys | grep -q "sec"; then
    echo "No GPG key found. Generating a new GPG key..."
    echo "You will be prompted to enter information for your key."
    echo "For key type, select RSA and RSA (default)."
    echo "For key size, enter 4096 for stronger security."
    echo "For expiration, choose an appropriate value (0 = does not expire)."
    echo "Enter your name and email when prompted."
    echo "Set a secure passphrase when asked."

    # Start key generation
    gpg --full-generate-key

    if [ $? -ne 0 ]; then
        echo "Error: GPG key generation failed. Please try again manually with 'gpg --full-generate-key'."
        exit 1
    fi
else
    echo "GPG key already exists."
fi

# Get the GPG key ID
GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | head -1 | awk '{print $2}' | cut -d'/' -f2)

if [ -z "$GPG_KEY_ID" ]; then
    echo "Error: Could not determine GPG key ID. Please initialize pass manually with:"
    echo "pass init \"YOUR_GPG_KEY_ID\""
    exit 1
fi

# Initialize the password store if it doesn't exist
if [ ! -d "$HOME/.password-store" ]; then
    echo "Initializing password store with key ID: $GPG_KEY_ID"
    pass init "$GPG_KEY_ID"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to initialize pass. Please try manually with:"
        echo "pass init \"$GPG_KEY_ID\""
        exit 1
    fi
else
    echo "Password store already initialized."
fi

# Set up Git for the password store
echo "Setting up Git for the password store..."
pass git init

# Install Pass for macOS (optional)
read -p "Would you like to install Pass for macOS GUI application? (y/n) " install_gui
if [[ $install_gui == "y" ]]; then
    echo "Installing Pass for macOS..."
    brew install --cask pass-for-macos
    echo "Pass for macOS installed. You can find it in your Applications folder."
fi

# Install browserpass (optional)
read -p "Would you like to install browser integration for Pass? (y/n) " install_browser
if [[ $install_browser == "y" ]]; then
    echo "Installing browserpass..."
    brew install browserpass
    /opt/homebrew/opt/browserpass/bin/browserpass-setup
    echo "Browser integration installed. Please install the browser extension from:"
    echo "https://github.com/browserpass/browserpass-extension"
fi

echo "Password management setup complete!"
echo "Your GPG key ID is: $GPG_KEY_ID"
echo ""
echo "Basic usage:"
echo "  - Add a password: pass insert category/service/username"
echo "  - Retrieve a password: pass category/service/username"
echo "  - Generate a password: pass generate category/service/username 20"
echo "  - List passwords: pass"
echo ""
echo "For more information, run: man pass"
