# Secure File Transfer with SSH

This guide explains how to set up SSH connections between different machines for secure file transfer, with a focus on transferring GPG keys for password management. It includes specific instructions for Mac to WSL Ubuntu and WSL to WSL connections.

## Table of Contents

- [Understanding SSH for Secure Transfer](#understanding-ssh-for-secure-transfer)
- [Setting Up SSH Keys](#setting-up-ssh-keys)
- [Mac to WSL Ubuntu Connection](#mac-to-wsl-ubuntu-connection)
- [WSL to WSL Connection](#wsl-to-wsl-connection)
- [Using GitHub to Transfer SSH Keys](#using-github-to-transfer-ssh-keys)
- [Transferring GPG Keys Securely](#transferring-gpg-keys-securely)
- [Troubleshooting](#troubleshooting)

## Understanding SSH for Secure Transfer

SSH (Secure Shell) provides a secure channel over an unsecured network. When transferring sensitive files like GPG keys, SSH ensures:

1. **Encryption**: All data is encrypted during transfer
2. **Authentication**: Ensures you're connecting to the intended machine
3. **Integrity**: Verifies data hasn't been tampered with during transfer

## Setting Up SSH Keys

Before establishing connections, you should set up SSH keys on both machines.

### On Your Source Machine (e.g., Mac or WSL)

```bash
# Check if you already have SSH keys
ls -la ~/.ssh

# If you don't see id_ed25519.pub or id_rsa.pub, generate new keys
ssh-keygen -t ed25519 -C "your_email@example.com"
# Or use RSA if needed for compatibility
# ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Start the SSH agent in the background
eval "$(ssh-agent -s)"

# Add your private key to the SSH agent
ssh-add ~/.ssh/id_ed25519  # or ~/.ssh/id_rsa
```

### On Your Target Machine (e.g., WSL Ubuntu)

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create or open the authorized_keys file
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## Mac to WSL Ubuntu Connection

### Step 1: Find Your WSL IP Address

On your WSL Ubuntu system:

```bash
# Install SSH server if not already installed
sudo apt update
sudo apt install openssh-server

# Configure SSH server
sudo sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Start or restart SSH service
sudo service ssh start
# or
sudo service ssh restart

# Get your WSL IP address
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
# Note this IP address (e.g., 172.x.x.x)
```

### Step 2: Copy Your SSH Public Key from Mac to WSL

On your Mac:

```bash
# Copy your public key to WSL
# Replace username and IP_ADDRESS with your actual username and WSL IP
ssh-copy-id username@IP_ADDRESS

# If ssh-copy-id is not available, use this alternative:
cat ~/.ssh/id_ed25519.pub | ssh username@IP_ADDRESS "cat >> ~/.ssh/authorized_keys"
```

### Step 3: Test the Connection

```bash
# Try connecting to your WSL machine
ssh username@IP_ADDRESS

# If successful, you should be logged in without a password prompt
```

### Step 4: Configure for Easier Access (Optional)

On your Mac, edit `~/.ssh/config`:

```
Host wsl
    HostName IP_ADDRESS
    User username
    IdentityFile ~/.ssh/id_ed25519
```

Now you can connect simply with:

```bash
ssh wsl
```

## WSL to WSL Connection

### Step 1: Set Up SSH on Both WSL Instances

On both WSL instances:

```bash
# Install SSH server
sudo apt update
sudo apt install openssh-server

# Configure SSH server
sudo sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Start SSH service
sudo service ssh start

# Get IP address
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
```

### Step 2: Exchange SSH Keys

On the first WSL instance (source):

```bash
# Generate SSH key if you haven't already
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy your public key to the second WSL instance
# Replace username and TARGET_IP with the actual username and IP
ssh-copy-id username@TARGET_IP
```

### Step 3: Test the Connection

```bash
# Try connecting to the second WSL instance
ssh username@TARGET_IP

# If successful, you should be logged in without a password prompt
```

## Using GitHub to Transfer SSH Keys

If you already have SSH keys stored in your GitHub account, you can use them to establish connections between your machines. This is particularly useful for setting up SSH between a Mac and WSL environment.

### Prerequisites

- SSH keys already uploaded to your GitHub account
- Access to both machines (Mac and WSL)
- GitHub account access

### Step 1: Retrieve the Public Key from GitHub

1. Log in to your GitHub account
2. Go to Settings → SSH and GPG keys
3. Find the key you want to use (e.g., "Mac SSH Key")
4. Click on the key to view its details
5. Copy the entire public key content

### Step 2: Set Up the Target Machine (WSL)

```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create or open the authorized_keys file
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Add the GitHub-stored public key to authorized_keys
# Replace with the actual key you copied from GitHub
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... myemail@email.com" >> ~/.ssh/authorized_keys
```

### Example: Using Mac's SSH Key for WSL Access

**Scenario:**
- You have a Mac with SSH key already stored in GitHub as "Mac SSH Key"
- You want to set up SSH access from this Mac to your WSL environment
- The WSL username is "adam"
- The WSL machine's IP address is 192.55.55.555

#### Method 1: Using GitHub Web Interface

**On GitHub:**
1. Go to your GitHub account → Settings → SSH and GPG keys
2. Find the entry labeled "Mac SSH Key"
3. Click on it and copy the entire public key

**On WSL (as user adam):**
```bash
# Ensure .ssh directory exists with proper permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the Mac's public key to authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... copied-key-from-github" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Start SSH server if not already running
sudo service ssh start

# Get your WSL IP address to provide to the Mac user
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
# This should show 192.55.55.555
```

**On Mac:**
```bash
# Test the connection
ssh adam@192.55.55.555

# If you want to make it easier to connect, add an entry to ~/.ssh/config
echo "Host wsl-adam
    HostName 192.55.55.555
    User adam
    IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config

# Now you can connect simply with
ssh wsl-adam
```

#### Method 2: Using Command Line Only

**On WSL (as user adam):**

```bash
# Ensure .ssh directory exists with proper permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Install curl if not already installed
sudo apt update && sudo apt install -y curl jq

# Fetch the public key from GitHub API (replace USERNAME with your GitHub username)
GITHUB_USERNAME="your-github-username"

# List all SSH keys to find the one you want
curl -s https://api.github.com/users/$GITHUB_USERNAME/keys | jq -r '.[] | "ID: \(.id), Title: \(.title)"'

# Get a specific key by ID (replace KEY_ID with the ID from the list above)
KEY_ID="12345678"  # Replace with actual key ID
curl -s https://api.github.com/users/$GITHUB_USERNAME/keys | jq -r ".[] | select(.id == $KEY_ID) | .key" > ~/.ssh/github_mac_key.pub

# Or, if you know the exact title of your key (e.g., "Mac SSH Key")
KEY_TITLE="Mac SSH Key"  # Replace with your actual key title if needed
curl -s https://api.github.com/users/$GITHUB_USERNAME/keys | jq -r ".[] | select(.title == \"$KEY_TITLE\") | .key" > ~/.ssh/github_mac_key.pub

# Add the key to authorized_keys
cat ~/.ssh/github_mac_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Clean up
rm ~/.ssh/github_mac_key.pub

# Start SSH server if not already running
sudo service ssh start

# Get your WSL IP address to provide to the Mac user
ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
# This should show 192.55.55.555
```

**On Mac:**
```bash
# Test the connection
ssh adam@192.55.55.555

# If you want to make it easier to connect, add an entry to ~/.ssh/config
cat >> ~/.ssh/config << EOF
Host wsl-adam
    HostName 192.55.55.555
    User adam
    IdentityFile ~/.ssh/id_ed25519
EOF

# Now you can connect simply with
ssh wsl-adam
```

**Note:** The GitHub API method only works for public keys that are publicly visible on your GitHub profile. If your keys are not public, you'll need to use the web interface method or directly copy the key from your Mac.

### Benefits of Using GitHub for Key Transfer

1. **No direct machine-to-machine transfer needed**: Useful when direct access between machines is difficult
2. **Verified keys**: You're using keys that are already working with GitHub
3. **Convenience**: No need to generate new keys if you already have them in GitHub
4. **Documentation**: Your GitHub account serves as documentation of which keys exist

### Security Considerations

1. **GitHub as intermediary**: Remember that GitHub has seen your public key (not the private key)
2. **Key naming**: Use descriptive names in GitHub (e.g., "WSL-Windows-adam@192.55.55.555") to track where keys are used
3. **Key rotation**: Consider rotating keys periodically for better security
4. **Revocation**: If a device is lost, revoke its key from both GitHub and any machines where you've authorized it

## Transferring GPG Keys Securely

Once you have SSH set up between your machines, you can securely transfer GPG keys.

### Preparing GPG Keys for Transfer

On your source machine (where your GPG key exists):

```bash
# Export your public and private keys
gpg --export-secret-keys --armor YOUR_GPG_KEY_ID > ~/gpg-private-key.asc
gpg --export --armor YOUR_GPG_KEY_ID > ~/gpg-public-key.asc

# Export your trust database
gpg --export-ownertrust > ~/gpg-ownertrust.txt
```

### Transferring from Mac to WSL

```bash
# Using the SSH connection you set up
scp ~/gpg-private-key.asc ~/gpg-public-key.asc ~/gpg-ownertrust.txt username@IP_ADDRESS:~

# Or using the SSH config shortcut if you set it up
scp ~/gpg-private-key.asc ~/gpg-public-key.asc ~/gpg-ownertrust.txt wsl:~
```

### Transferring from WSL to WSL

```bash
# Using the SSH connection you set up
scp ~/gpg-private-key.asc ~/gpg-public-key.asc ~/gpg-ownertrust.txt username@TARGET_IP:~
```

### Transferring from WSL to Mac

```bash
# On your Mac, run:
scp username@WSL_IP:~/gpg-private-key.asc username@WSL_IP:~/gpg-public-key.asc username@WSL_IP:~/gpg-ownertrust.txt ~
```

## Importing GPG Keys on the Target Machine

After transferring, import the keys on your target machine:

```bash
# Import your GPG keys
gpg --import ~/gpg-public-key.asc
gpg --import ~/gpg-private-key.asc

# Import your trust database
gpg --import-ownertrust ~/gpg-ownertrust.txt

# Verify the key was imported correctly
gpg --list-secret-keys --keyid-format LONG

# Clean up (important for security)
shred -u ~/gpg-private-key.asc
rm ~/gpg-public-key.asc ~/gpg-ownertrust.txt
```

## Troubleshooting

### Connection Issues

1. **Cannot connect to WSL via SSH**:
   - Ensure SSH server is running: `sudo service ssh status`
   - Check firewall settings: `sudo ufw status`
   - Verify the IP address hasn't changed: `ip addr show eth0`

2. **Permission denied (publickey)**:
   - Verify your public key is in the target's `~/.ssh/authorized_keys`
   - Check permissions: `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/authorized_keys`

3. **SSH connection works but scp fails**:
   - Check file permissions in the source directory
   - Try using absolute paths instead of relative paths

### GPG Key Issues

1. **"No such file or directory" when importing keys**:
   - Verify the files were transferred correctly: `ls -la ~/*gpg*`
   - Check if the paths in your commands match the actual file locations

2. **"gpg: key not found" after import**:
   - Ensure you're using the correct key ID
   - Try listing available keys: `gpg --list-keys`

3. **"gpg: decryption failed: No secret key"**:
   - The private key may not have been imported correctly
   - Check if the secret key is available: `gpg --list-secret-keys`

## Security Considerations

1. **Delete transferred key files after import**:
   ```bash
   # Securely delete private key file
   shred -u ~/gpg-private-key.asc

   # Remove other files
   rm ~/gpg-public-key.asc ~/gpg-ownertrust.txt
   ```

2. **Use temporary SSH access if needed**:
   ```bash
   # After transferring files, you can remove the authorized key
   # Edit ~/.ssh/authorized_keys and remove the temporary key
   ```

3. **Consider network security**:
   - Perform transfers on a trusted network
   - Consider using a VPN if transferring over public networks

## Conclusion

Using SSH for transferring GPG keys provides a secure method to set up password management across multiple devices. By following this guide, you can ensure your sensitive cryptographic keys are transferred with proper encryption and authentication.

Remember to always protect your private keys and clean up any temporary files after the transfer is complete.
