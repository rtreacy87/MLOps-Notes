# Run this script to configure VS Code to use WSL as the default terminal

# Get the VS Code settings file path
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# Check if the settings file exists
if (Test-Path $settingsPath) {
    # Read the current settings
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
} else {
    # Create a new settings object if the file doesn't exist
    $settings = New-Object PSObject
    # Create the directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path (Split-Path $settingsPath) | Out-Null
}

# Add or update the terminal settings
$settings | Add-Member -NotePropertyName "terminal.integrated.defaultProfile.windows" -NotePropertyValue "Ubuntu (WSL)" -Force

# Create or update the profiles object
if (-not ($settings."terminal.integrated.profiles.windows")) {
    $settings | Add-Member -NotePropertyName "terminal.integrated.profiles.windows" -NotePropertyValue (@{}) -Force
}

# Add or update the Ubuntu WSL profile
$settings."terminal.integrated.profiles.windows" | Add-Member -NotePropertyName "Ubuntu (WSL)" -NotePropertyValue (@{
    "path" = "C:\\WINDOWS\\System32\\wsl.exe"
    "args" = @("-d", "Ubuntu")
}) -Force

# Save the updated settings
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath

Write-Host "VS Code has been configured to use WSL as the default terminal." -ForegroundColor Green
