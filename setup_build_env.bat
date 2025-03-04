@echo off
:: Drogon Framework - Windows Build Environment Setup Script

echo Drogon Framework - Windows Build Environment Setup
echo ================================================

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrative privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Create build directory if it doesn't exist
if not exist build mkdir build

:: Check for Visual Studio installation
echo Checking for Visual Studio installation...
set "VS_FOUND=0"

:: Check for Visual Studio 2022
if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VS_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Community"
    set "VS_YEAR=2022"
    set "VS_FOUND=1"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VS_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Professional"
    set "VS_YEAR=2022"
    set "VS_FOUND=1"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VS_PATH=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise"
    set "VS_YEAR=2022"
    set "VS_FOUND=1"
)

:: Check for Visual Studio 2019
if %VS_FOUND% equ 0 (
    if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community"
        set "VS_YEAR=2019"
        set "VS_FOUND=1"
    ) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional"
        set "VS_YEAR=2019"
        set "VS_FOUND=1"
    ) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
        set "VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise"
        set "VS_YEAR=2019"
        set "VS_FOUND=1"
    )
)

if %VS_FOUND% equ 0 (
    echo ERROR: Visual Studio 2019 or 2022 with C++ workload not found.
    echo Please install Visual Studio with C++ development workload.
    echo Download from: https://visualstudio.microsoft.com/downloads/
    pause
    exit /b 1
)

echo Found Visual Studio %VS_YEAR% at: %VS_PATH%

:: Check for vcpkg
echo Checking for vcpkg installation...
set "VCPKG_PATH=C:\vcpkg"

if not exist "%VCPKG_PATH%\vcpkg.exe" (
    echo vcpkg not found at %VCPKG_PATH%
    echo Running PowerShell script to install vcpkg and dependencies...
    
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_env.ps1"
    
    if %ERRORLEVEL% neq 0 (
        echo Error running PowerShell script.
        pause
        exit /b 1
    )
) else (
    echo vcpkg found at %VCPKG_PATH%
)

:: Create a command script to open Developer Command Prompt
echo Creating build_drogon.bat script...

(
    echo @echo off
    echo echo Setting up Visual Studio Developer Environment...
    echo call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64
    echo cd /d "%~dp0build"
    echo echo.
    echo echo Configuring Drogon with CMake...
    echo cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
    echo.
    echo echo Building Drogon...
    echo cmake --build . --config Release
    echo.
    echo echo.
    echo echo Build completed. Check for any errors above.
    echo pause
) > "%~dp0build_drogon.bat"

echo.
echo Setup complete!
echo.
echo To build Drogon:
echo 1. Run the generated 'build_drogon.bat' script
echo    OR
echo 2. Open Developer Command Prompt for VS %VS_YEAR%
echo    Navigate to your build directory
echo    Run: cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
echo    Run: cmake --build .
echo.
echo See docs\BUILD_GUIDE_WINDOWS.md for detailed instructions

pause
