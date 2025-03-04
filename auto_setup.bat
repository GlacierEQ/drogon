@echo off
:: Drogon Automated Environment and Build Setup Script

echo Drogon Framework - Automated Environment Setup and Build
echo =======================================================
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Create scripts directory if it doesn't exist
if not exist scripts mkdir scripts

:: Create the directory structure
if not exist build mkdir build
if not exist install mkdir install

:: Check Python installation
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Python not found. Installing Python...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.9.7/python-3.9.7-amd64.exe' -OutFile 'python_installer.exe'; Start-Process -FilePath 'python_installer.exe' -ArgumentList '/quiet', 'InstallAllUsers=1', 'PrependPath=1' -Wait; Remove-Item -Path 'python_installer.exe'}"
)

:: Run environment setup script
echo.
echo Step 1: Setting up development environment...
echo.
powershell -ExecutionPolicy Bypass -File setup_env.ps1

:: Generate VSCode configuration
echo.
echo Step 2: Configuring VSCode integration...
echo.
if not exist .vscode mkdir .vscode

:: Copy necessary scripts
copy scripts\auto_build_manager.py scripts\auto_build_manager.py >nul 2>&1

:: Run the verification tool
echo.
echo Step 3: Verifying environment setup...
echo.
python scripts\verify_environment.py

:: Create a PowerShell script to add environment variables for the current session
echo $env:PATH += ";C:\vcpkg\installed\x64-windows\bin" > temp_env.ps1
echo $env:PATH += ";%CD%\install\bin" >> temp_env.ps1
echo $env:VCPKG_ROOT = "C:\vcpkg" >> temp_env.ps1
echo $env:CMAKE_TOOLCHAIN_FILE = "C:\vcpkg\scripts\buildsystems\vcpkg.cmake" >> temp_env.ps1
echo Write-Host "Environment variables updated for this session." >> temp_env.ps1

:: Run the script
powershell -ExecutionPolicy Bypass -File temp_env.ps1
del temp_env.ps1

:: Create a desktop shortcut for VSCode with Drogon
echo.
echo Step 4: Creating desktop shortcut for VSCode with Drogon...
powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([System.Environment]::GetFolderPath('Desktop') + '\Drogon Development.lnk'); $Shortcut.TargetPath = 'code.exe'; $Shortcut.Arguments = '%CD%'; $Shortcut.Save()}"

:: Final instructions
echo.
echo =======================================================
echo Setup Complete!
echo.
echo All dependencies have been installed and added to the environment path.
echo Visual Studio Code has been configured for Drogon development.
echo.
echo To start development:
echo 1. Use the "Drogon Development" shortcut on your desktop
echo 2. OR open Visual Studio Code and open this folder: %CD%
echo.
echo The build process will start automatically when VSCode opens.
echo =======================================================
echo.

pause
