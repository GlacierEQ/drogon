#!/bin/bash
# Drogon Framework - Environment Setup Script
# This script detects the OS and installs all required dependencies

set -e

# Detect OS
if [ -f /etc/os-release ]; then
    # Linux
    . /etc/os-release
    OS=$NAME
    echo "Detected OS: $OS"
elif [ "$(uname)" = "Darwin" ]; then
    # macOS
    OS="macOS"
    echo "Detected OS: macOS"
elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" = "MINGW64_NT" ]; then
    # Windows
    OS="Windows"
    echo "Detected OS: Windows"
else
    echo "Unsupported operating system"
    exit 1
fi

# Function to update environment variables
update_env_path() {
    if [ "$OS" = "macOS" ]; then
        # macOS
        if [ -f ~/.zshrc ]; then
            echo 'export PATH=$PATH:/usr/local/lib' >> ~/.zshrc
            echo 'export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/usr/local/lib' >> ~/.zshrc
            source ~/.zshrc
        else
            echo 'export PATH=$PATH:/usr/local/lib' >> ~/.bash_profile
            echo 'export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/usr/local/lib' >> ~/.bash_profile
            source ~/.bash_profile
        fi
    elif [ "$OS" = "Windows" ]; then
        echo "For Windows, please add the following paths to your environment variables:"
        echo "C:\vcpkg\installed\x64-windows\bin"
    else
        # Linux
        echo 'export PATH=$PATH:/usr/local/lib' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib' >> ~/.bashrc
        source ~/.bashrc
    fi
}

# Install dependencies based on OS
if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
    echo "Installing dependencies for $OS"
    sudo apt update
    sudo apt install -y git gcc g++ cmake make
    sudo apt install -y libjsoncpp-dev uuid-dev zlib1g-dev openssl libssl-dev
    sudo apt install -y libsqlite3-dev libpq-dev libmysqlclient-dev libhiredis-dev
    sudo apt install -y libbrotli-dev libyaml-cpp-dev

elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "Red Hat"* ]] || [[ "$OS" == "Fedora"* ]]; then
    echo "Installing dependencies for $OS"
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y cmake3
    sudo yum install -y jsoncpp-devel uuid-devel zlib-devel openssl-devel
    sudo yum install -y sqlite-devel postgresql-devel mysql-devel hiredis-devel
    sudo yum install -y brotli-devel yaml-cpp-devel

elif [ "$OS" = "macOS" ]; then
    echo "Installing dependencies for macOS"
    # Check if Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew install cmake jsoncpp ossp-uuid zlib openssl brotli
    brew install sqlite3 postgresql mysql hiredis yaml-cpp

elif [ "$OS" = "Windows" ]; then
    echo "For Windows, please use vcpkg to install dependencies."
    echo "Run the following commands in PowerShell:"
    echo "git clone https://github.com/microsoft/vcpkg.git"
    echo "cd vcpkg"
    echo "./bootstrap-vcpkg.bat"
    echo "./vcpkg install jsoncpp zlib openssl uuid brotli sqlite3 libpq libmysql hiredis yaml-cpp"
    echo "./vcpkg integrate install"
else
    echo "Unsupported OS for automatic dependency installation"
    exit 1
fi

# Update environment variables
update_env_path

echo "Dependencies installed successfully!"
echo "You may need to restart your terminal or source your profile file to apply path changes."
