# Run this script in PowerShell with administrator privileges

# Enable WSL feature
Write-Host "Enabling Windows Subsystem for Linux..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Cyan
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "Please restart your computer now, then run the second part of this script." -ForegroundColor Yellow
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
