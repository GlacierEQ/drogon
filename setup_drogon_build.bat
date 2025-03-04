@echo off
REM Step 1: Check for Visual Studio Build Tools
where cl >nul 2>nul
if %errorlevel% neq 0 (
    echo Visual Studio Build Tools not found. Please install them first.
    exit /b
)

REM Step 2: Run the environment setup script
call setup_build_env.bat

REM Step 3: Navigate to the build directory
cd build

REM Step 4: Run CMake configuration
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake

REM Step 5: Build the project
cmake --build .

echo Build process completed.
