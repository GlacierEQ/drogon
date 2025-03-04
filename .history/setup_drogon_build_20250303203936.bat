@echo off
REM Step 1: Run the environment setup script
call setup_build_env.bat

REM Step 2: Navigate to the build directory
cd build

REM Step 3: Run CMake configuration
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake

REM Step 4: Build the project
cmake --build .
