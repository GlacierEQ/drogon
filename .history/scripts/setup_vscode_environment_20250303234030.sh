#!/bin/bash
# VSCode Environment Setup for Drogon on Linux/macOS

echo -e "\033[36mSetting up development environment for Drogon in VSCode...\033[0m"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$WORKSPACE_ROOT/build"

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
    echo -e "\033[31mUnsupported OS: $(uname)\033[0m"
    exit 1
fi

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo -e "\033[32mChecking for required tools...\033[0m"

# Check for C++ compiler
if ! command_exists g++ && ! command_exists clang++; then
    echo -e "\033[33mNo C++ compiler found. Installing...\033[0m"
    
    if [ "$OS" = "macOS" ]; then
        # Install Xcode Command Line Tools
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install || true  # The command might return error if already installed
        
        # Wait for user to complete installation
        echo "Please complete the Xcode Command Line Tools installation."
        echo "Press Enter after installation is complete..."
        read -r
    elif [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ] || [ "$DISTRO" = "Linux Mint" ]; then
        echo "Installing GCC and build essentials..."
        sudo apt update
        sudo apt install -y build-essential
    elif [ "$DISTRO" = "Fedora" ] || [ "$DISTRO" = "CentOS" ] || [ "$DISTRO" = "Red Hat Enterprise Linux" ]; then
        echo "Installing GCC and development tools..."
        sudo dnf groupinstall -y "Development Tools"
    else
        echo -e "\033[31mUnsupported Linux distribution. Please install C++ compiler manually.\033[0m"
        exit 1
    fi
else
    if command_exists g++; then
        GXX_VERSION=$(g++ --version | head -n1)
        echo -e "\033[32mFound g++: $GXX_VERSION\033[0m"
    else
        CLANG_VERSION=$(clang++ --version | head -n1)
        echo -e "\033[32mFound clang++: $CLANG_VERSION\033[0m"
    fi
fi

# Check for CMake
if ! command_exists cmake; then
    echo -e "\033[33mCMake not found. Installing...\033[0m"
    
    if [ "$OS" = "macOS" ]; then
        if ! command_exists brew; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        echo "Installing CMake with Homebrew..."
        brew install cmake
    elif [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ] || [ "$DISTRO" = "Linux Mint" ]; then
        sudo apt update
        sudo apt install -y cmake
    elif [ "$DISTRO" = "Fedora" ] || [ "$DISTRO" = "CentOS" ] || [ "$DISTRO" = "Red Hat Enterprise Linux" ]; then
        sudo dnf install -y cmake
    else
        echo -e "\033[31mUnsupported Linux distribution. Please install CMake manually.\033[0m"
        exit 1
    fi
else
    CMAKE_VERSION=$(cmake --version | head -n1