# SSH Agent Configuration for VS Code and WSL

This guide explains how to configure the SSH agent to avoid being repeatedly prompted for your SSH passphrase when using VS Code with WSL.

## Understanding the Problem

When using SSH keys with passphrases (which is recommended for security), you may encounter these issues:

1. Being prompted for your passphrase every time you open a new terminal in VS Code
2. SSH agent not persisting between terminal sessions
3. Having to re-enter your passphrase multiple times during a development session

## Solution: Configuring SSH Agent Properly

### Option 1: Improved .bashrc Configuration (Recommended)

The following configuration improves upon the basic SSH agent setup by:
- Using a socket file to maintain persistence
- Checking if the agent is actually running (not just if the environment variable exists)
- Ensuring the agent starts only once

Add this to your `~/.bashrc` file:

```bash
# SSH Agent Configuration
# Set SSH_AUTH_SOCK to a fixed path to maintain persistence
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

# Check if the agent socket exists and is valid
ssh-add -l &>/dev/null
if [ "$?" -eq 2 ]; then
  # Socket exists but agent is not running
  rm -f "$SSH_AUTH_SOCK"
  # Start a new agent
  ssh-agent -a "$SSH_AUTH_SOCK" > /dev/null
elif [ "$?" -eq 1 ]; then
  # Socket exists and agent is running but no keys
  # No action needed, we'll add keys below
  :
fi

# Add keys if they exist and aren't already added
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-add -l | grep -q "$(ssh-keygen -lf "$HOME/.ssh/id_ed25519" | awk '{print $2}')" || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
fi

if [ -f "$HOME/.ssh/id_rsa" ]; then
  ssh-add -l | grep -q "$(ssh-keygen -lf "$HOME/.ssh/id_rsa" | awk '{print $2}')" || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null
fi
```

### Option 2: Using Keychain

Keychain is a tool that helps manage SSH keys and provides a more robust solution:

1. Install keychain:
   ```bash
   sudo apt-get install keychain
   ```

2. Add to your `~/.bashrc`:
   ```bash
   # SSH agent configuration using keychain
   if [ -f /usr/bin/keychain ]; then
     eval $(keychain --eval --quiet --nogui --agents ssh id_ed25519 id_rsa)
   fi
   ```

### Option 3: Using the Windows OpenSSH Agent with WSL

You can configure WSL to use the Windows OpenSSH agent:

1. Enable the OpenSSH Authentication Agent service in Windows:
   - Open Services (Win+R, type `services.msc`)
   - Find "OpenSSH Authentication Agent"
   - Set startup type to "Automatic" and start the service

2. Add to your `~/.bashrc`:
   ```bash
   # Use Windows SSH agent
   export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
   
   # Check if the Windows SSH agent socket is already forwarded
   ss -a | grep -q $SSH_AUTH_SOCK
   if [ $? -ne 0 ]; then
     # Remove existing socket if present
     rm -f $SSH_AUTH_SOCK
     # Create directory for the socket
     mkdir -p $(dirname $SSH_AUTH_SOCK)
     # Forward the Windows SSH agent socket to the WSL socket
     (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
   fi
   ```

   Note: This requires installing `socat` and `npiperelay`:
   ```bash
   sudo apt-get install socat
   mkdir -p ~/.local/bin
   curl -L -o ~/.local/bin/npiperelay.exe https://github.com/jstarks/npiperelay/releases/latest/download/npiperelay.exe
   chmod +x ~/.local/bin/npiperelay.exe
   ```

## Troubleshooting

### SSH Agent Not Starting

If the SSH agent isn't starting properly:

```bash
# Check if the SSH agent is running
ps aux | grep ssh-agent

# Start the SSH agent manually
eval "$(ssh-agent -s)"

# Add your key manually
ssh-add ~/.ssh/id_ed25519
```

### Permission Issues

If you encounter permission errors:

```bash
# Fix permissions on your SSH directory and files
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### VS Code Terminal Integration Issues

If VS Code terminals aren't picking up your SSH agent:

1. Ensure VS Code is using the correct shell:
   - Open VS Code settings (Ctrl+,)
   - Search for "terminal.integrated.defaultProfile.linux"
   - Make sure it's set to "bash"

2. Try restarting VS Code after making changes to your `.bashrc`

## Best Practices

1. **Use a passphrase with your SSH key**: This adds an extra layer of security
2. **Configure the agent to start automatically**: As shown in the examples above
3. **Limit the lifetime of added keys**: For higher security, you can add the `-t` option to `ssh-add` to limit how long keys are cached
4. **Use different keys for different services**: Consider using separate keys for GitHub, work servers, etc.

## Conclusion

With the proper SSH agent configuration, you should no longer be prompted for your passphrase every time you open a new terminal in VS Code. The agent will maintain your unlocked keys across terminal sessions, making your development workflow smoother while maintaining security.
