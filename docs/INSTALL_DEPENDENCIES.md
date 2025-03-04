# Drogon Dependencies Installation Guide

This guide explains how to install all the necessary dependencies for the Drogon framework and set them up in your environment path.

## Dependencies Overview

Drogon relies on the following libraries:
- CMake (3.5+)
- C++ compiler supporting C++17/20
- OpenSSL (for HTTPS support)
- JsonCpp
- zlib
- UUID
- Brotli (optional)
- PostgreSQL client library (optional, for PostgreSQL support)
- MySQL client library (optional, for MySQL/MariaDB support)
- SQLite3 (optional, for SQLite support)
- hiredis (optional, for Redis support)
- YAML-CPP (optional, for YAML config support)

## Linux Systems

### Ubuntu/Debian

```bash
# Update package lists
sudo apt update

# Install essential build tools
sudo apt install -y git gcc g++ cmake make

# Install required dependencies
sudo apt install -y libjsoncpp-dev uuid-dev zlib1g-dev openssl libssl-dev

# Install optional database drivers
sudo apt install -y libsqlite3-dev libpq-dev libmysqlclient-dev libhiredis-dev

# Install other optional dependencies
sudo apt install -y libbrotli-dev libyaml-cpp-dev

# Add to environment path (add to ~/.bashrc)
echo 'export PATH=$PATH:/usr/local/lib' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib' >> ~/.bashrc
source ~/.bashrc
```

### CentOS/RHEL/Fedora

```bash
# Install development tools
sudo yum groupinstall -y "Development Tools"
sudo yum install -y cmake3

# Install required dependencies
sudo yum install -y jsoncpp-devel uuid-devel zlib-devel openssl-devel

# Install optional database drivers
sudo yum install -y sqlite-devel postgresql-devel mysql-devel hiredis-devel

# Install other optional dependencies
sudo yum install -y brotli-devel yaml-cpp-devel

# Add to environment path (add to ~/.bashrc)
echo 'export PATH=$PATH:/usr/local/lib' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib' >> ~/.bashrc
source ~/.bashrc
```

## macOS

Using Homebrew:

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install cmake jsoncpp ossp-uuid zlib openssl brotli

# Install optional database drivers
brew install sqlite3 postgresql mysql hiredis yaml-cpp

# Add to environment path (add to ~/.zshrc or ~/.bash_profile)
echo 'export PATH=$PATH:/usr/local/lib' >> ~/.zshrc
echo 'export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/usr/local/lib' >> ~/.zshrc
source ~/.zshrc
```

## Windows

Using vcpkg:

```powershell
# Install vcpkg if not already installed
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.bat

# Install dependencies
./vcpkg install jsoncpp zlib openssl uuid brotli

# Optional database dependencies
./vcpkg install sqlite3 libpq libmysql hiredis yaml-cpp

# Integrate with Visual Studio
./vcpkg integrate install

# Add to environment path
$env:PATH += ";C:\vcpkg\installed\x64-windows\bin"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, [EnvironmentVariableTarget]::User)
```

For permanent PATH setup:
1. Right-click on "This PC" or "My Computer"
2. Select "Properties"
3. Click on "Advanced system settings"
4. Click "Environment Variables"
5. Edit the "Path" variable and add the location of your installed libraries

## Verifying Installation

To verify that your environment is set up correctly:

```bash
# Check if libraries are in path
ldconfig -p | grep jsoncpp  # Linux
echo $PATH | tr ':' '\n'    # Check path entries
```

## Using Dependencies in CMake

In your CMakeLists.txt file, ensure you're finding the packages from the environment path:

```cmake
find_package(jsoncpp REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)
# Add other dependencies as needed

# Example target linking
target_link_libraries(your_target PRIVATE 
    jsoncpp_lib
    OpenSSL::SSL
    OpenSSL::Crypto
    ZLIB::ZLIB
    # Add other libraries
)
```

## Troubleshooting

If you encounter "library not found" errors at runtime:
- Ensure the libraries are in your PATH/LD_LIBRARY_PATH
- Try running `ldconfig` on Linux systems
- Verify that the correct versions are installed
- Check for any conflicting installations
