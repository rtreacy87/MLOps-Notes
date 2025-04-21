# Run this script after restarting

# Download the WSL2 Linux kernel update package
Write-Host "Downloading WSL2 Linux kernel update package..." -ForegroundColor Cyan
$wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$wslUpdateInstaller = "$env:TEMP\wsl_update_x64.msi"
Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdateInstaller -UseBasicParsing

# Install the WSL2 Linux kernel update package
Write-Host "Installing WSL2 Linux kernel update package..." -ForegroundColor Cyan
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $wslUpdateInstaller /quiet" -Wait

# Set WSL 2 as the default version
Write-Host "Setting WSL 2 as the default version..." -ForegroundColor Cyan
wsl --set-default-version 2

# Download and install Ubuntu
Write-Host "Installing Ubuntu..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://aka.ms/wslubuntu2004" -OutFile "$env:TEMP\Ubuntu.appx" -UseBasicParsing
Add-AppxPackage "$env:TEMP\Ubuntu.appx"

Write-Host "WSL2 and Ubuntu have been installed successfully!" -ForegroundColor Green
Write-Host "Launch Ubuntu from the Start menu to complete the setup." -ForegroundColor Green
