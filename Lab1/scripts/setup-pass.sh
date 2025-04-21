#!/bin/bash
# Script to set up pass password manager

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
