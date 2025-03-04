# Building Drogon on Windows

This guide provides step-by-step instructions for building the Drogon framework on Windows systems.

## Prerequisites

Before building Drogon, ensure you have installed:

1. **Visual Studio Build Tools**: Contains the C++ compiler and necessary build tools
2. **CMake**: Version 3.5 or higher
3. **Git**: For cloning the repository and its dependencies
4. **Dependencies**: See [INSTALL_DEPENDENCIES.md](./INSTALL_DEPENDENCIES.md) for installation of required libraries

## Installing Visual Studio Build Tools

1. Download Visual Studio Build Tools from [Microsoft's official website](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2019)
2. Run the installer
3. Select the "C++ build tools" workload
4. Ensure the following components are selected:
   - MSVC C++ Build Tools
   - Windows 10 SDK
   - C++ CMake tools for Windows
5. Complete the installation

## Building Drogon

### Step 1: Clone the Repository

```powershell
git clone https://github.com/drogonframework/drogon.git
cd drogon
```

### Step 2: Create a Build Directory

```powershell
mkdir build
cd build
```

### Step 3: Configure with CMake

**Important**: Use the Developer Command Prompt for Visual Studio instead of regular PowerShell or Command Prompt.

1. Open "Developer Command Prompt for Visual Studio" from the Start Menu
2. Navigate to your Drogon build directory:
   ```cmd
   cd C:\path\to\drogon\build
   ```

3. Run CMake configuration:
   ```cmd
   cmake ..
   ```

   If using vcpkg for dependencies, add the toolchain file:
   ```cmd
   cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
   ```

### Step 4: Build the Project

Still in the Developer Command Prompt:

```cmd
cmake --build .
```

For Release build:

```cmd
cmake --build . --config Release
```

### Step 5: Install (Optional)

```cmd
cmake --build . --target install
```

## Common Issues

### CMake Cannot Find Compiler

**Error**:
```
No CMAKE_C_COMPILER could be found.
No CMAKE_CXX_COMPILER could be found.
```

**Solution**:
1. Ensure Visual Studio Build Tools are properly installed
2. **Always use the Developer Command Prompt** for Visual Studio (not regular PowerShell)
3. Check if environment variables are set properly:
   ```cmd
   echo %VCINSTALLDIR%
   ```
   If empty, your environment is not set up correctly.

### Missing Dependencies

**Error**:
```
Could not find package SomeLibrary
```

**Solution**:
1. Install the missing library using vcpkg
   ```cmd
   vcpkg install somelibrary:x64-windows
   ```
2. Add vcpkg toolchain to CMake:
   ```cmd
   cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
   ```

### Build Errors

If you encounter build errors, try:

1. Clean the build directory:
   ```cmd
   cmake --build . --target clean
   ```
   
2. Reconfigure with explicit generator:
   ```cmd
   cmake .. -G "Visual Studio 16 2019" -A x64
   ```

3. Building with detailed output to identify issues:
   ```cmd
   cmake --build . --verbose
   ```

## Advanced Configuration

### Using Conan Package Manager

If you're using Conan instead of vcpkg:

```cmd
conan install .. --build=missing
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .
```

### Custom Build Options

Drogon provides several build options:

```cmd
cmake .. -DBUILD_ORM=ON -DBUILD_EXAMPLES=OFF -DBUILD_CTL=ON
```

See the main README for a complete list of build options.

### Using Different Visual Studio Versions

Specify the generator explicitly:

```cmd
# For Visual Studio 2019
cmake .. -G "Visual Studio 16 2019" -A x64

# For Visual Studio 2022
cmake .. -G "Visual Studio 17 2022" -A x64
```

## Testing the Build

After a successful build, run the tests:

```cmd
ctest -C Debug
```

Or run one of the examples:

```cmd
.\examples\Debug\hello_world.exe
```
