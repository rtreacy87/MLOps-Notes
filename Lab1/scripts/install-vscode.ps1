# Run this script in PowerShell with administrator privileges

# Create a temporary directory
$tempDir = Join-Path $env:TEMP "VSCodeInstall"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download the latest VS Code installer
$installerPath = Join-Path $tempDir "VSCodeSetup.exe"
Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" -OutFile $installerPath

# Install VS Code silently with default options
Start-Process -FilePath $installerPath -Args "/VERYSILENT /MERGETASKS=!runcode" -Wait

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "VS Code has been installed successfully!" -ForegroundColor Green
