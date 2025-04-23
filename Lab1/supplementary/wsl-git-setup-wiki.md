# Configuring Git Authentication in WSL

This guide will help you set up proper Git authentication in Windows Subsystem for Linux (WSL) to successfully push to GitHub repositories.

## Understanding the Issue

The error message "Invalid username or password" occurs because GitHub no longer supports password authentication for Git operations. You need to use either:
- Personal Access Tokens (PAT)
- SSH keys
- Credential Manager

## Method 1: Using Personal Access Token (PAT)

### Step 1: Generate a GitHub Personal Access Token

1. Go to GitHub.com and log in
2. Click your profile picture → Settings → Developer settings
3. Select "Personal access tokens" → "Tokens (classic)"
4. Click "Generate new token" → "Generate new token (classic)"
5. Give your token a descriptive name (e.g., "WSL Git Access")
6. Set expiration (recommended: 90 days)
7. Select scopes (required: `repo` for full repository access)
8. Click "Generate token"
9. Copy the token immediately (you won't see it again!)

### Step 2: Configure Git Credential Storage

```bash
# Configure credential helper to cache your credentials
git config --global credential.helper store

# Or use credential manager
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
```

### Step 3: Use the Token

Next time you push, use:
- Username: Your GitHub username
- Password: Your Personal Access Token (not your GitHub password)

## Method 2: Using SSH Keys (Recommended)

### Step 1: Generate or Reuse SSH Keys

#### Creating New SSH Keys vs. Reusing Existing Keys

**Creating new SSH keys for each computer (Recommended):**

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Press Enter to accept default file location
# Enter a passphrase (optional but recommended)
```

**Reusing existing SSH keys from a password manager:**

```bash
# Create the .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create the private key file (id_ed25519) and public key file (id_ed25519.pub)
# by pasting the content from your password manager

# Set proper permissions
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Comparing the two approaches:**

| Aspect | Creating New Keys | Reusing Existing Keys |
|--------|------------------|----------------------|
| **Security** | More secure - each device has unique keys | Less secure - compromise of one device affects all |
| **Traceability** | Better - can identify which device accessed repositories | Worse - can't distinguish between devices |
| **Revocation** | Easier - can revoke access for a specific device | Harder - revoking affects all devices using the key |
| **Convenience** | Less convenient - need to add each key to GitHub | More convenient - set up once, use everywhere |
| **Backup needs** | Higher - need to back up keys from each device | Lower - only need to back up once |

**Recommendation:** Create new SSH keys for each computer/environment for better security and control. This allows you to:
- Revoke access for specific devices if lost or compromised
- Track which device is being used for repository access
- Maintain security isolation between different environments

If you choose to reuse keys, ensure they are stored securely and use a strong passphrase.

### Step 2: Add SSH Key to SSH Agent

```bash
# Start the ssh-agent
eval "$(ssh-agent -s)"

# Add your SSH private key
ssh-add ~/.ssh/id_ed25519
```

### Step 3: Add SSH Key to GitHub

1. Copy your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   You'll see output like this:
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... myemail@email.com
   ```
   **Important**: Copy the ENTIRE output, including:
   - The key type (`ssh-ed25519`)
   - The key itself (the long string starting with `AAAAC3...`)
   - Your email address at the end

2. Go to GitHub.com → Settings → SSH and GPG keys
3. Click "New SSH key"
4. Paste the entire key (all of it from step 1) and save

### Step 4: Update Remote URL

```bash
# Change from HTTPS to SSH
git remote set-url origin git@github.com:username/repository.git

# Verify the change
git remote -v
```
For detailed instructions on solving common SSH problems, refer to the [SSH Agent Configuration Wiki](ssh-agent-configuration.md).

### Troubleshooting: Constantly Asked for SSH Key Password

If you're repeatedly prompted for your SSH key password in WSL, try these solutions:

**Quick solution guide:**

- **For a quick fix**: Try solution #5 (Verify SSH Agent Has Your Key)
- **For a permanent fix**: Set up solution #1 (Automatic SSH Agent) or #3 (Keychain)
- **For the most robust solution**: Implement both #1 and #2 (SSH Config)

Each solution below includes a simple explanation of what the code does and why it helps:

#### 1. Ensure SSH Agent is Running Automatically

Add these lines to your `~/.bashrc` or `~/.zshrc` file to start the SSH agent automatically:

```bash
# Start SSH agent automatically
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check if ssh-agent is already running
   ps -aux | grep ssh-agent | grep -v grep > /dev/null
   if [ $? -ne 0 ]; then
      eval "$(ssh-agent -s)" > /dev/null
   fi
fi

# Add your SSH key to the agent automatically
if [ -f "$HOME/.ssh/id_ed25519" ]; then
   ssh-add -l | grep "$HOME/.ssh/id_ed25519" > /dev/null
   if [ $? -ne 0 ]; then
      ssh-add $HOME/.ssh/id_ed25519 2>/dev/null
   fi
fi
```

**Simple explanation of what this script does:**

1. **First part (SSH agent check):**
   - Checks if the SSH agent is already running
   - If it's not running, starts it automatically
   - The SSH agent is a program that holds your private keys in memory so you don't have to type your password each time

2. **Second part (Adding your key):**
   - Checks if your SSH key file exists
   - Checks if your key is already loaded in the agent
   - If the key isn't loaded, adds it to the agent
   - This means your key is available for authentication without requiring your password repeatedly

After adding these lines, restart your terminal or run `source ~/.bashrc` (or `source ~/.zshrc`).

#### 2. Use SSH Config to Persist Connections

Create or edit `~/.ssh/config` to maintain persistent connections:

```bash
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes
    ControlMaster auto
    ControlPath ~/.ssh/control/%r@%h:%p
    ControlPersist yes
```

**Simple explanation of this configuration:**

- `Host github.com`: This section applies to connections to GitHub
- `IdentityFile`: Tells SSH which key file to use (so you don't have to specify it each time)
- `AddKeysToAgent yes`: Automatically adds your key to the SSH agent when used
- `IdentitiesOnly yes`: Only uses the specified key, avoiding key negotiation delays
- `ControlMaster auto`: Creates a single shared connection that all other connections can use
- `ControlPath`: Where to store the control socket file
- `ControlPersist yes`: Keeps the connection open in the background even after you close your terminal

The overall effect is that SSH will establish one connection and reuse it, avoiding password prompts for each new connection.

Make sure to create the control directory:

```bash
mkdir -p ~/.ssh/control
chmod 700 ~/.ssh/control
```

#### 3. Use Keychain for Persistent SSH Agent

Install and configure keychain to manage your SSH keys across sessions:

```bash
# Install keychain
sudo apt update && sudo apt install keychain

# Add to your ~/.bashrc or ~/.zshrc
if [ -f "/usr/bin/keychain" ]; then
    eval $(keychain --eval --quiet id_ed25519)
fi
```

**Simple explanation:**

- Keychain is a special tool that manages SSH keys across login sessions
- The first command installs the keychain program
- The second part adds code to your shell startup file that:
  - Checks if keychain is installed
  - If it is, starts keychain and tells it to manage your SSH key
  - Keychain will remember your password and keep your key available even after reboots
  - This means you'll only need to enter your password once after each system restart

#### 4. Check SSH Key Permissions

Incorrect permissions can cause authentication issues:

```bash
# Set correct permissions for SSH directory and files
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Simple explanation:**

- SSH is very strict about file permissions for security reasons
- These commands set the correct permissions that SSH requires:
  - `chmod 700 ~/.ssh`: Only you can access your SSH directory
  - `chmod 600 ~/.ssh/id_ed25519`: Only you can read/write your private key
  - `chmod 644 ~/.ssh/id_ed25519.pub`: Everyone can read your public key, but only you can modify it
- If permissions are wrong, SSH will refuse to use your keys as a security measure

#### 5. Verify SSH Agent Has Your Key

```bash
# List keys in SSH agent
ssh-add -l

# If your key isn't listed, add it
ssh-add ~/.ssh/id_ed25519
```

**Simple explanation:**

- The SSH agent needs to have your key loaded to use it
- `ssh-add -l` shows all keys currently loaded in the agent
- If you don't see your key listed, the second command adds it
- When you add a key, you'll be asked for your password once
- After that, the agent will use the key without asking for your password again

#### 6. Test Your SSH Connection

```bash
# Test connection to GitHub
ssh -T git@github.com
```

**Simple explanation:**

- This command tests if your SSH key is working correctly with GitHub
- It tries to establish a connection to GitHub using your SSH key
- If everything is set up correctly, GitHub will recognize you
- You'll see a message like: "Hi username! You've successfully authenticated..."
- If you see this message, your SSH setup is working properly
- If you're prompted for a password, one of the previous steps needs attention

## Method 3: Using GitHub CLI

### Step 1: Install GitHub CLI

```bash
# For Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### Step 2: Authenticate with GitHub CLI

```bash
gh auth login

# Follow the prompts to authenticate
```

## Method 4: Using Windows Credential Manager

If you have Git installed on Windows, you can use the Windows Credential Manager:

```bash
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
```

This allows your WSL Git to use the same credentials as your Windows Git installation.

## Troubleshooting

### Clear Cached Credentials

```bash
# Clear any cached credentials
git credential-cache exit
git credential reject https://github.com
```

### Check Configuration

```bash
# Check your Git configuration
git config --list

# Verify remote URL
git remote -v
```

### Test Connection

```bash
# For SSH
ssh -T git@github.com

# For HTTPS
git ls-remote https://github.com/username/repository
```

## Best Practices

1. **Use SSH for persistence**: SSH keys provide more secure and convenient authentication
2. **Set token expiration**: Always set expiration dates for PATs
3. **Use minimal permissions**: Only grant necessary scopes to tokens
4. **Regularly rotate credentials**: Update tokens and keys periodically
5. **Never commit credentials**: Never store tokens or keys in your repositories

## Common Issues and Solutions

### Issue: WSL can't find SSH key
```bash
# Ensure correct permissions
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Issue: Credential helper timeout
```bash
# Set a longer timeout (in seconds)
git config --global credential.helper 'cache --timeout=3600'
```

### Issue: Multiple GitHub accounts
```bash
# Use different SSH keys for different accounts
# Create ~/.ssh/config
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal

Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work

# Update remote URL
git remote set-url origin git@github.com-personal:username/repository.git
```

## Summary

For the best experience with Git in WSL:

1. Use SSH keys for authentication
2. Configure Git with your name and email
3. Set up credential caching if using HTTPS
4. Keep your credentials secure and updated

With these configurations, you should be able to push to GitHub repositories from WSL without authentication issues.
