# VSCode Environment Setup for Drogon

Write-Host "Setting up development environment for Drogon in VSCode..." -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$workspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$buildDir = Join-Path $workspaceRoot "build"

# Function to check if command exists
function Test-Command {
    param($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { if (Get-Command $command) { $true } }
    catch { $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "This script is not running as Administrator. Some operations may fail."
    $confirmContinue = Read-Host "Continue anyway? (y/n)"
    if ($confirmContinue -ne 'y') {
        Write-Host "Exiting script. Please restart VSCode as Administrator." -ForegroundColor Red
        exit 1
    }
}

# Check for required tools
Write-Host "Checking for required tools..." -ForegroundColor Green

# Check for Visual Studio
$vsInstallations = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022"
)

$vsEditions = @("Community", "Professional", "Enterprise")
$vsFound = $false
$vsPath = $null
$vsVer = $null

foreach ($vsInstall in $vsInstallations) {
    if (Test-Path $vsInstall) {
        foreach ($edition in $vsEditions) {
            $vcvarsPath = Join-Path $vsInstall "$edition\VC\Auxiliary\Build\vcvarsall.bat"
            if (Test-Path $vcvarsPath) {
                $vsFound = $true
                $vsPath = $vcvarsPath
                $vsVer = if ($vsInstall -like "*2022*") { "2022" } else { "2019" }
                break
            }
        }
    }
    if ($vsFound) { break }
}

if (-not $vsFound) {
    Write-Host "Visual Studio not found. Installing Visual Studio Build Tools..." -ForegroundColor Yellow
    
    # Download and install VS Build Tools
    $vsToolsUrl = "https://aka.ms/vs/16/release/vs_buildtools.exe"
    $vsToolsInstaller = Join-Path $env:TEMP "vs_buildtools.exe"
    
    try {
        Write-Host "Downloading Visual Studio Build Tools..."
        Invoke-WebRequest -Uri $vsToolsUrl -OutFile $vsToolsInstaller
        
        Write-Host "Installing Visual Studio Build Tools..."
        Start-Process -FilePath $vsToolsInstaller -ArgumentList "--quiet", "--wait", "--norestart", "--nocache", `
            "--installPath", "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools", `
            "--add", "Microsoft.VisualStudio.Workload.VCTools", `
            "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", `
            "--add", "Microsoft.VisualStudio.Component.Windows10SDK.19041" -Wait

        $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
        $vsVer = "2019"
        Write-Host "Visual Studio Build Tools installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Visual Studio Build Tools. Please install manually." -ForegroundColor Red
        Write-Host "Download URL: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2019" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host "Visual Studio $vsVer found at: $vsPath" -ForegroundColor Green
}

# Check for CMake
if (-not (Test-Command cmake)) {
    Write-Host "CMake not found. Installing CMake..." -ForegroundColor Yellow
    
    try {
        # Install CMake via chocolatey if available
        if (Test-Command choco) {
            Write-Host "Installing CMake via Chocolatey..."
            choco install cmake --yes --no-progress
        }
        # Otherwise, download the installer
        else {
            $cmakeUrl = "https://github.com/Kitware/CMake/releases/download/v3.21.3/cmake-3.21.3-windows-x86_64.msi"
            $cmakeInstaller = Join-Path $env:TEMP "cmake-installer.msi"
            
            Write-Host "Downloading CMake..."
            Invoke-WebRequest -Uri $cmakeUrl -OutFile $cmakeInstaller
            
            Write-Host "Installing CMake..."
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $cmakeInstaller, "/quiet", "/norestart", "ADD_CMAKE_TO_PATH=System" -Wait
        }
        
        # Reload PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        if (-not (Test-Command cmake)) {
            throw "CMake not found in PATH after installation"
        }
        
        Write-Host "CMake installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install CMake. Please install manually." -ForegroundColor Red
        Write-Host "Download URL: https://cmake.org/download/" -ForegroundColor Yellow
        exit 1
    }
}
else {
    $cmakeVersion = (cmake --version).Split(' ')[2]
    Write-Host "CMake $cmakeVersion found." -ForegroundColor Green
}

# Check for Ninja
if (-not (Test-Command ninja)) {
    Write-Host "Ninja not found. Installing Ninja..." -ForegroundColor Yellow
    
    try {
        # Install Ninja via chocolatey if available
        if (Test-Command choco) {
            Write-Host "Installing Ninja via Chocolatey..."
            choco install ninja --yes --no-progress
        }
        # Otherwise, download and extract manually
        else {
            $ninjaUrl = "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip"
            $ninjaZip = Join-Path $env:TEMP "ninja-win.zip"
            $ninjaPath = "C:\Ninja"
            
            Write-Host "Downloading Ninja..."
            Invoke-WebRequest -Uri $ninjaUrl -OutFile $ninjaZip
            
            Write-Host "Extracting Ninja..."
            if (-not (Test-Path $ninjaPath)) {
                New-Item -ItemType Directory -Path $ninjaPath | Out-Null
            }
            Expand-Archive -Path $ninjaZip -DestinationPath $ninjaPath -Force
            
            # Add Ninja to the PATH
            $envPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($envPath -notlike "*$ninjaPath*") {
                [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$ninjaPath", "Machine")
                $env:Path += ";$ninjaPath"
            }
        }
        
        if (-not (Test-Command ninja)) {
            throw "Ninja not found in PATH after installation"
        }
        
        Write-Host "Ninja installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Ninja. Please install manually." -ForegroundColor Red
        exit 1
    }
}
else {
    $ninjaVersion = (ninja --version).Trim()
    Write-Host "Ninja $ninjaVersion found." -ForegroundColor Green
}

# Check for vcpkg
$vcpkgPath = "C:\vcpkg"
if (-not (Test-Path (Join-Path $vcpkgPath "vcpkg.exe"))) {
    Write-Host "vcpkg not found. Installing vcpkg..." -ForegroundColor Yellow
    
    try {
        # Clone vcpkg repository
        Write-Host "Cloning vcpkg repository..."
        git clone https://github.com/microsoft/vcpkg.git $vcpkgPath
        
        # Bootstrap vcpkg
        Write-Host "Bootstrapping vcpkg..."
        Push-Location $vcpkgPath
        .\bootstrap-vcpkg.bat
        
        # Install required dependencies
        Write-Host "Installing Drogon dependencies with vcpkg..."
        .\vcpkg install jsoncpp:x64-windows zlib:x64-windows openssl:x64-windows uuid:x64-windows brotli:x64-windows
        .\vcpkg install sqlite3:x64-windows libpq:x64-windows libmysql:x64-windows hiredis:x64-windows yaml-cpp:x64-windows
        
        # Integrate vcpkg with Visual Studio
        .\vcpkg integrate install
        
        Pop-Location
        
        Write-Host "vcpkg and dependencies installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install vcpkg or dependencies. Please install manually." -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "vcpkg found at $vcpkgPath" -ForegroundColor Green
    
    # Update vcpkg
    Write-Host "Updating vcpkg..."
    Push-Location $vcpkgPath
    git pull
    .\vcpkg update
    Pop-Location
}

# Create/ensure build directory exists
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
    Write-Host "Created build directory at $buildDir" -ForegroundColor Green
}

# Create a batch file to run the build with VS environment variables
$buildScriptPath = Join-Path $workspaceRoot "auto_build.bat"
@"
@echo off
echo Setting up Visual Studio environment...
call "$vsPath" x64
cd /d "$buildDir"
echo.
echo Configuring Drogon with CMake...
cmake .. -G Ninja -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
echo.
echo Building Drogon...
cmake --build .
echo.
echo Drogon build completed.
"@ | Out-File -FilePath $buildScriptPath -Encoding ASCII

# Create an environment initialization script that runs on VSCode startup
$vscodeStartupPath = Join-Path $workspaceRoot ".vscode" "startup.ps1"
if (-not (Test-Path (Join-Path $workspaceRoot ".vscode"))) {
    New-Item -ItemType Directory -Path (Join-Path $workspaceRoot ".vscode") | Out-Null
}

@"
# This script runs automatically when VSCode opens the workspace
Write-Host "Initializing Drogon development environment..." -ForegroundColor Cyan

# Ensure the build directory exists
`$buildDir = Join-Path "$workspaceRoot" "build"
if (-not (Test-Path `$buildDir)) {
    New-Item -ItemType Directory -Path `$buildDir | Out-Null
}

# Add C:\vcpkg\installed\x64-windows\bin to the PATH for the current session
`$env:Path += ";C:\vcpkg\installed\x64-windows\bin"

# Set environment variables for building
`$env:VCPKG_ROOT = "C:\vcpkg"
`$env:CMAKE_TOOLCHAIN_FILE = "C:\vcpkg\scripts\buildsystems\vcpkg.cmake"

Write-Host "Environment initialized. Ready for Drogon development!" -ForegroundColor Green
"@ | Out-File -FilePath $vscodeStartupPath -Encoding UTF8

# Create PowerShell Terminal profile to auto-initialize build environment
$vscodeTerminalProfilePath = Join-Path $workspaceRoot ".vscode" "terminal_profile.ps1"
@"
# Load Visual Studio environment
function Initialize-VsEnvironment {
    Write-Host "Loading Visual Studio environment..." -ForegroundColor Cyan
    `$vsDevCmdPath = "$vsPath"
    cmd /c "`"`$vsDevCmdPath`" x64 & set" | ForEach-Object {
        if (`$_ -match "=") {
            `$name, `$value = `$_ -split "=", 2
            Set-Item -Path env:`$name -Value `$value
        }
    }
    Write-Host "Visual Studio environment loaded." -ForegroundColor Green
}

# Initialize environment
Initialize-VsEnvironment
`$env:Path += ";C:\vcpkg\installed\x64-windows\bin"
`$env:CMAKE_TOOLCHAIN_FILE = "C:\vcpkg\scripts\buildsystems\vcpkg.cmake"
Set-Location "$workspaceRoot"
"@ | Out-File -FilePath $vscodeTerminalProfilePath -Encoding UTF8

# Create shortcut to run the auto-build
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Build Drogon.lnk"
$WScriptObj = New-Object -ComObject ("WScript.Shell")
$shortcut = $WscriptObj.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $buildScriptPath
$shortcut.WorkingDirectory = $workspaceRoot
$shortcut.Save()

Write-Host "Environment setup complete!" -ForegroundColor Cyan
Write-Host "To build Drogon:"
Write-Host "  1. Use the VSCode integrated terminal (which will be automatically configured)"
Write-Host "  2. Run the 'Build Drogon' task from the Terminal > Run Task menu"
Write-Host "  3. Click the 'Build Drogon' shortcut on your desktop"
Write-Host ""
Write-Host "The build process will start automatically when VSCode opens this folder."
