@echo off
REM Step 1: Run the environment setup script
call setup_build_env.bat

REM Step 2: Instructions for the user
echo Please open the "Developer Command Prompt for Visual Studio" and then run the following commands:

REM Step 3: Navigate to the build directory
cd build

REM Step 4: Run CMake configuration
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake

REM Step 5: Build the project
cmake --build .
