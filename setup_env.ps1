# Drogon Framework - Windows Environment Setup Script
# This script installs vcpkg and all required dependencies

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator"
    exit 1
}

# Set error action preference
$ErrorActionPreference = "Stop"

# Create a temporary directory for vcpkg if it doesn't exist
$vcpkgPath = "C:\vcpkg"
if (-not (Test-Path $vcpkgPath)) {
    Write-Host "Cloning vcpkg repository..."
    git clone https://github.com/microsoft/vcpkg.git $vcpkgPath
    
    # Bootstrap vcpkg
    Write-Host "Bootstrapping vcpkg..."
    Push-Location $vcpkgPath
    .\bootstrap-vcpkg.bat
    Pop-Location
} else {
    Write-Host "vcpkg already exists at $vcpkgPath"
}

# Install dependencies
Write-Host "Installing dependencies..."
Push-Location $vcpkgPath
.\vcpkg install jsoncpp:x64-windows zlib:x64-windows openssl:x64-windows uuid:x64-windows brotli:x64-windows
.\vcpkg install sqlite3:x64-windows libpq:x64-windows libmysql:x64-windows hiredis:x64-windows yaml-cpp:x64-windows

# Integrate with Visual Studio
.\vcpkg integrate install
Pop-Location

# Add to environment path
$binPath = "C:\vcpkg\installed\x64-windows\bin"
$libPath = "C:\vcpkg\installed\x64-windows\lib"
$includePath = "C:\vcpkg\installed\x64-windows\include"

# Update PATH environment variable
$currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
if ($currentPath -notlike "*$binPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$binPath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Added $binPath to system PATH"
}

# Update LIB environment variable
$currentLib = [Environment]::GetEnvironmentVariable("LIB", [EnvironmentVariableTarget]::Machine)
if ($null -eq $currentLib) {
    [Environment]::SetEnvironmentVariable("LIB", $libPath, [EnvironmentVariableTarget]::Machine)
    Write-Host "Created LIB environment variable with $libPath"
} elseif ($currentLib -notlike "*$libPath*") {
    [Environment]::SetEnvironmentVariable("LIB", "$currentLib;$libPath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Added $libPath to system LIB"
}

# Update INCLUDE environment variable
$currentInclude = [Environment]::GetEnvironmentVariable("INCLUDE", [EnvironmentVariableTarget]::Machine)
if ($null -eq $currentInclude) {
    [Environment]::SetEnvironmentVariable("INCLUDE", $includePath, [EnvironmentVariableTarget]::Machine)
    Write-Host "Created INCLUDE environment variable with $includePath"
} elseif ($currentInclude -notlike "*$includePath*") {
    [Environment]::SetEnvironmentVariable("INCLUDE", "$currentInclude;$includePath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Added $includePath to system INCLUDE"
}

Write-Host "Dependencies installed successfully!"
Write-Host "You may need to restart your terminal or IDE to apply path changes."
