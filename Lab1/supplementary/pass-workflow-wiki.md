# Pass Password Manager: Complete Workflow Guide

This guide covers the complete workflow for using the `pass` password manager effectively across multiple devices and platforms, including synchronization, browser integration, mobile access, and automation.

## Table of Contents

- [Daily Workflow](#daily-workflow)
- [Password Store Structure](#password-store-structure)
- [Synchronizing Across Devices](#synchronizing-across-devices)
- [Browser Integration](#browser-integration)
- [Mobile Access](#mobile-access)
- [Automation and Webhooks](#automation-and-webhooks)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## Daily Workflow

### Basic Operations

```bash
# List all passwords
pass

# Create a new password
pass insert category/service/username

# Generate a secure random password (20 characters)
pass generate category/service/username 20

# Copy a password to clipboard (clears after 45 seconds)
pass -c category/service/username

# Show a password (avoid in shared environments)
pass category/service/username

# Edit an existing password
pass edit category/service/username

# Remove a password
pass rm category/service/username
```

### Renaming Password Entries

If you need to rename a password entry (for example, changing `home/github/username` to `home/github.com/username`), you can use the `mv` command in pass:

```bash
# Rename a password entry
pass mv home/github/username home/github.com/username

# Verify the new path works
pass home/github.com/username

# Verify the old path no longer exists
pass home/github/username  # Should show "Error: home/github/username is not in the password store."
```

You can also move entries between different categories:

```bash
# Move from personal to work category
pass mv personal/github/username work/github/username

# Move an entire directory
pass mv personal/github work/github
```

If you're using Git with pass, these changes are automatically committed with a message like "Rename password from X to Y".

### Storing and Retrieving Usernames and Emails

When storing usernames or emails, it's important to understand that `pass` expects you to enter the password/content after running the insert command, not as part of the command itself:

```bash
# INCORRECT way (this won't work):
pass insert home/github/username person@email.com
# This tries to create an entry named 'person@email.com' under home/github/username

# CORRECT way:
pass insert home/github/username
# After running this command, you'll be prompted to enter the content
# Type 'person@email.com' at the prompt and press Enter
# Then confirm by typing it again

# To verify it was stored correctly:
pass home/github/username
# This should display: person@email.com
```

**Example session:**

```
$ pass insert home/github/username
Enter password for home/github/username: person@email.com
Retype password for home/github/username: person@email.com

$ pass home/github/username
person@email.com
```

You can also store multiple lines of information using the multiline option:

```bash
# Store username, email, and notes in one entry
pass insert -m home/github/full-info
# Type or paste multiple lines:
# username: johndoe
# email: person@email.com
# notes: This is my personal GitHub account
# Press Ctrl+D when finished

# Retrieve the information
pass home/github/full-info
```

### Working with Non-Password Data

Pass can store any type of data, not just passwords:

```bash
# Store multiline content (JSON, SSH keys, notes)
pass insert -m category/service/config
# Type or paste your content, then press Ctrl+D to save

# Store a file directly
pass insert category/service/certificate < certificate.pem

# Extract stored data to a file
pass category/service/certificate > certificate.pem
```

## Password Store Structure

The password store is organized hierarchically in a directory structure:

```
~/.password-store/
├── personal/
│   ├── email/
│   │   ├── gmail.gpg
│   │   └── outlook.gpg
│   └── banking/
│       ├── chase.gpg
│       └── wellsfargo.gpg
└── work/
    ├── azure/
    │   ├── subscription-key.gpg
    │   └── storage-account.gpg
    └── aws/
        ├── access-key.gpg
        └── secret-key.gpg
```

### Examining the Structure

```bash
# List all passwords with tree structure
pass

# View the password store structure with more details
pass ls

# View the structure with the system tree command (if installed)
tree ~/.password-store

# Find passwords containing a specific term
pass find azure

# Show the full path of a password
pass show -c azure/subscription-key

# Count the number of passwords in your store
find ~/.password-store -name "*.gpg" | wc -l
```

Example output of `pass` or `pass ls` command:

```
Password Store
├── personal
│   ├── email
│   │   ├── gmail
│   │   └── outlook
│   └── banking
│       ├── chase
│       └── wellsfargo
└── work
    ├── azure
    │   ├── subscription-key
    │   └── storage-account
    └── aws
        ├── access-key
        └── secret-key
```

### Organizing Your Password Store

Best practices for organizing your password store:

1. **Use Categories**: Create top-level directories for different areas (personal, work, clients)
2. **Use Services**: Create subdirectories for different services or platforms
3. **Use Descriptive Names**: Include usernames in password names for clarity
4. **Use Consistent Naming**: Establish a naming convention (e.g., `category/service/username`)

Example organization:

```bash
# Create a structured password store
pass insert personal/email/gmail
pass insert personal/email/outlook
pass insert work/azure/subscription-key
pass insert work/aws/access-key
```

## Synchronizing Across Devices

### Setting Up Git Synchronization

Pass integrates with Git for version control and synchronization:

```bash
# Initialize Git repository (if not done during setup)
pass git init

# Add a remote repository
pass git remote add origin git@github.com:username/password-store.git

# Push your password store to GitHub
pass git push -u origin main

# Set up automatic commits on changes
echo 'password-store.bash-completion' >> ~/.gitignore
echo 'password-store.bash-completion' >> ~/.password-store/.gitignore
```

### Cloning an Existing Password Store

To set up pass on a new device with your existing store:

```bash
# 1. Install pass and import your GPG key
# (See the setup guide for details)

# 2. Clone your password store
git clone git@github.com:username/password-store.git ~/.password-store

# 3. Initialize pass with your GPG key
pass init your-gpg-key-id
```

### Synchronizing Changes

```bash
# Pull changes from remote repository
pass git pull

# Make changes (add/edit passwords)
pass insert new/password

# Push changes to remote repository
pass git push

# View history of changes
pass git log
```

### Automatic Synchronization

Set up automatic synchronization with a Git hook:

1. Create a post-commit hook:

```bash
cat > ~/.password-store/.git/hooks/post-commit << 'EOF'
#!/bin/bash
git push origin main
EOF
chmod +x ~/.password-store/.git/hooks/post-commit
```

2. Create a pre-commit hook to pull changes:

```bash
cat > ~/.password-store/.git/hooks/pre-commit << 'EOF'
#!/bin/bash
git pull --rebase origin main
EOF
chmod +x ~/.password-store/.git/hooks/pre-commit
```

## Browser Integration

### Browserpass Extension

Browserpass allows you to autofill passwords from your pass store:

#### Setup on Linux

```bash
# Install browserpass native host
sudo apt install browserpass

# Or on Arch Linux
sudo pacman -S browserpass
```

#### Setup on macOS

```bash
# Install browserpass native host
brew install browserpass

# Configure the native host
/usr/local/opt/browserpass/bin/browserpass-setup
# Or on Apple Silicon Macs
/opt/homebrew/opt/browserpass/bin/browserpass-setup
```

#### Browser Extensions

1. Install the browser extension:
   - [Chrome Extension](https://chrome.google.com/webstore/detail/browserpass/naepdomgkenhinolocfifgehidddafch)
   - [Firefox Extension](https://addons.mozilla.org/en-US/firefox/addon/browserpass-ce/)

2. Configure the extension:
   - Set the path to your password store
   - Configure keyboard shortcuts
   - Set default username matching rules

### Using Browserpass

1. Navigate to a login page
2. Click the browserpass icon or use the keyboard shortcut (default: Ctrl+Shift+L)
3. Select the appropriate password entry
4. Browserpass will autofill the username and password

### Password Naming for Browser Integration

For best results with browserpass, name your passwords to match the domain:

```bash
# For github.com
pass insert websites/github.com/username

# For multiple accounts on the same site
pass insert websites/github.com/work-username
pass insert websites/github.com/personal-username
```

## Mobile Access

### Android: Password Store App

[Password Store](https://github.com/android-password-store/Android-Password-Store) is an Android app for managing your pass password store:

1. Install from [Google Play](https://play.google.com/store/apps/details?id=dev.msfjarvis.aps) or [F-Droid](https://f-droid.org/packages/dev.msfjarvis.aps/)
2. Set up OpenKeychain for GPG key management
3. Import your GPG key
4. Clone your password repository

```
# Repository URL format
https://github.com/username/password-store.git
```

### iOS: Pass for iOS

[Pass for iOS](https://github.com/mssun/passforios) allows you to use pass on iOS devices:

1. Install from the [App Store](https://apps.apple.com/us/app/pass-password-store/id1205820573)
2. Import your GPG key
3. Clone your password repository

### Synchronizing on Mobile

Both Android and iOS apps support:

1. **Manual synchronization**: Pull/push changes with a button
2. **Automatic synchronization**: Configure to sync on app open/close
3. **SSH key authentication**: Use SSH keys for GitHub access

### Using Biometric Authentication

Both apps support using fingerprint or face recognition instead of typing your GPG passphrase every time:

1. **Android**: Enable in app settings under "Authentication"
2. **iOS**: Enable in app settings under "Security"

## Automation and Webhooks

### Setting Up Webhooks for Automatic Updates

You can use GitHub webhooks to trigger updates on your devices:

1. **Set up a webhook server**:

```bash
# Install webhook
sudo apt install webhook

# Create a webhook configuration
cat > ~/webhooks.json << EOF
[
  {
    "id": "password-store-update",
    "execute-command": "/home/username/update-passwords.sh",
    "command-working-directory": "/home/username"
  }
]
EOF

# Create the update script
cat > ~/update-passwords.sh << EOF
#!/bin/bash
cd ~/.password-store
git pull
EOF
chmod +x ~/update-passwords.sh

# Run the webhook server
webhook -hooks ~/webhooks.json -verbose
```

2. **Configure GitHub webhook**:
   - Go to your password-store repository on GitHub
   - Go to Settings > Webhooks > Add webhook
   - Set Payload URL to your server's address
   - Set Content type to application/json
   - Select "Just the push event"
   - Add the webhook

### Automating Password Rotation

Create a script to automatically rotate passwords:

```bash
#!/bin/bash
# rotate-password.sh

SERVICE=$1
LENGTH=${2:-30}  # Default to 30 characters if not specified

if [ -z "$SERVICE" ]; then
  echo "Usage: $0 service/path [length]"
  exit 1
fi

# Generate new password
NEW_PASSWORD=$(pass generate -f "$SERVICE" "$LENGTH")

# Use the new password to update the service
# This part depends on the service - here's an example for GitHub using the API
# TOKEN=$(pass github/api-token)
# curl -X PATCH -H "Authorization: token $TOKEN" \
#      -d "{\"password\":\"$NEW_PASSWORD\"}" \
#      https://api.github.com/user

echo "Password for $SERVICE has been rotated"
```

### Scheduled Password Rotation

Use cron to schedule password rotation:

```bash
# Edit crontab
crontab -e

# Add a line to rotate a password monthly
0 0 1 * * /home/username/rotate-password.sh work/github/personal 32
```

## Advanced Usage

### Using Pass with OTP (One-Time Passwords)

Install the pass-otp extension to manage TOTP tokens:

```bash
# Install pass-otp
sudo apt install pass-otp  # Debian/Ubuntu
brew install pass-otp      # macOS

# Add a TOTP secret to an existing password
pass otp append -s service/username

# Generate a TOTP code
pass otp service/username
```

### Importing from Other Password Managers

#### From KeePass:

```bash
# Install pass-import
pip install pass-import

# Import from KeePass
pass import keepass database.kdbx
```

#### From LastPass:

```bash
# Export from LastPass as CSV
# Then import to pass
pass import lastpass lastpass_export.csv
```

### Backing Up Your GPG Key

Always back up your GPG key securely:

```bash
# Export your public and private keys
gpg --export-secret-keys --armor your-key-id > private-key.asc
gpg --export --armor your-key-id > public-key.asc

# Store these files securely (e.g., on an encrypted USB drive)
```

### Using Multiple Password Stores

You can maintain separate password stores for different purposes:

```bash
# Create a new password store
export PASSWORD_STORE_DIR=~/.password-store-work
pass init your-gpg-key-id

# Use the work password store
PASSWORD_STORE_DIR=~/.password-store-work pass insert work/secret

# Create an alias for easy switching
echo 'alias pass-work="PASSWORD_STORE_DIR=~/.password-store-work pass"' >> ~/.bashrc
source ~/.bashrc

# Now you can use
pass-work insert new-secret
```

## Troubleshooting

### Common Issues and Solutions

#### Git Synchronization Issues

```bash
# Fix merge conflicts
cd ~/.password-store
git status
# Edit conflicted files
git add .
git commit -m "Resolve merge conflicts"
pass git push
```

#### GPG Key Issues

```bash
# Check if your GPG key is available
gpg --list-secret-keys

# If your key is missing, import it
gpg --import private-key.asc

# If you get "decryption failed: No secret key" error
# Make sure you're using the same GPG key that encrypted the passwords
pass init your-correct-gpg-key-id
```

#### Permission Issues

```bash
# Fix permissions on the password store
find ~/.password-store -type d -exec chmod 700 {} \;
find ~/.password-store -type f -exec chmod 600 {} \;
```

### Getting Help

```bash
# View pass help
pass help

# View help for a specific command
pass help insert

# View man page
man pass
```

## Best Practices

1. **Use Strong Master Password**: Your GPG key passphrase is the key to all your passwords
2. **Regular Backups**: Back up your GPG key and password store regularly
3. **Use Git**: Keep your password store in a Git repository for version control and synchronization
4. **Use Categories**: Organize passwords in a logical hierarchy
5. **Generate Strong Passwords**: Use `pass generate` with at least 20 characters
6. **Rotate Critical Passwords**: Regularly update important passwords
7. **Use OTP When Available**: Add TOTP secrets to your password entries for 2FA

## Conclusion

The `pass` password manager provides a secure, flexible, and extensible system for managing your passwords and other sensitive information. By following this workflow guide, you can effectively use pass across all your devices while maintaining security and convenience.

For more information, visit the [official pass website](https://www.passwordstore.org/) or the [GitHub repository](https://github.com/zx2c4/password-store).
