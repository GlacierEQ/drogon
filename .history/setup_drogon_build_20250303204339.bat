@echo off
REM Step 1: Check for Visual Studio Build Tools
where cl >nul 2>nul
if %errorlevel% neq 0 (
    echo Visual Studio Build Tools not found. Please install them first.
    exit /b
)

REM Step 2: Run the environment setup script
call setup_build_env.bat

REM Step 3: Create build directory if it doesn't exist
if not exist build (
    mkdir build
)

REM Step 4: Navigate to the build directory
cd build

REM Step 5: Run CMake configuration
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
if %errorlevel% neq 0 (
    echo CMake configuration failed. Please check the output for errors.
    exit /b
)

REM Step 6: Build the project
cmake --build .
if %errorlevel% neq 0 (
    echo Build process failed. Please check the output for errors.
    exit /b
)

echo Build process completed successfully.
