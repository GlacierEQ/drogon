#!/bin/bash
# Drogon Automated Environment and Build Setup Script for Linux/macOS

echo -e "\033[1mDrogon Framework - Automated Environment Setup and Build\033[0m"
echo "======================================================="
echo

# Detect OS
if [ "$(uname)" = "Darwin" ]; then
    OS="macOS"
    echo "Detected OS: macOS"
elif [ "$(uname)" = "Linux" ]; then
    OS="Linux"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$NAME
        echo "Detected OS: Linux ($DISTRO)"
    else
        DISTRO="Unknown"
        echo "Detected OS: Linux (unknown distribution)"
    fi
else
    echo "Unsupported operating system"
    exit 1
fi

# Create directory structure
mkdir -p scripts build install

# Check Python installation
if ! command -v python3 &> /dev/null; then
    echo "Python not found. Installing Python..."
    
    if [ "$OS" = "macOS" ]; then
        # Install Homebrew if not available
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install python3
    elif [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        sudo apt update
        sudo apt install -y python3 python3-pip
    elif [ "$DISTRO" = "Fedora" ] || [ "$DISTRO" = "CentOS" ]; then
        sudo dnf install -y python3 python3-pip
    else
        echo "Please install Python manually"
        exit 1
    fi
fi

# Run environment setup script
echo
echo "Step 1: Setting up development environment..."
echo
bash ./setup_env.sh

# Generate VSCode configuration
echo
echo "Step 2: Configuring VSCode integration..."
echo
mkdir -p .vscode

# Copy necessary scripts
cp scripts/auto_build_manager.py scripts/auto_build_manager.py &> /dev/null || true

# Make scripts executable
chmod +x scripts/*.py scripts/*.sh &> /dev/null || true

# Run the verification tool
echo
echo "Step 3: Verifying environment setup..."
echo
python3 scripts/verify_environment.py

# Update environment variables for current session
if [ "$OS" = "macOS" ]; then
    export PATH="$PATH:$(pwd)/install/bin:/usr/local/lib"
    export DYLD_LIBRARY