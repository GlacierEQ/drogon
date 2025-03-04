#!/usr/bin/env python3
"""
Drogon Environment Verification Tool
-----------------------------------
This script verifies that all dependencies are correctly installed and available in the environment path.
It also checks that the build environment is properly configured.
"""

import os
import sys
import platform
import subprocess
import shutil
import json
from pathlib import Path

# Required dependencies for all platforms
COMMON_REQUIRED = {
    "cmake": {
        "command": ["cmake", "--version"],
        "min_version": "3.5.0",
        "name": "CMake"
    },
    "git": {
        "command": ["git", "--version"],
        "min_version": "2.0.0",
        "name": "Git"
    }
}

# Platform-specific required dependencies
PLATFORM_REQUIRED = {
    "windows": {
        "ninja": {
            "command": ["ninja", "--version"],
            "min_version": "1.8.0",
            "name": "Ninja Build"
        },
        "cl": {
            "command": ["cl", "/?"],  # Just check if it exists, output goes to stderr
            "min_version": None,
            "name": "MSVC Compiler"
        },
        "vcpkg": {
            "command": ["vcpkg", "version"],
            "min_version": None,
            "name": "vcpkg Package Manager"
        }
    },
    "linux": {
        "g++": {
            "command": ["g++", "--version"],
            "min_version": "7.0.0",
            "name": "GCC C++ Compiler"
        },
        "make": {
            "command": ["make", "--version"],
            "min_version": "4.0",
            "name": "GNU Make"
        }
    },
    "darwin": {
        "clang++": {
            "command": ["clang++", "--version"],
            "min_version": "9.0.0",
            "name": "Clang C++ Compiler"
        }
    }
}

# Libraries that should be in the path
REQUIRED_LIBRARIES = {
    "windows": [
        {"name": "JsonCpp", "file_pattern": "jsoncpp*.dll"},
        {"name": "OpenSSL", "file_pattern": "libssl*.dll"},
        {"name": "OpenSSL Crypto", "file_pattern": "libcrypto*.dll"},
        {"name": "zlib", "file_pattern": "zlib*.dll"},
        {"name": "Brotli", "file_pattern": "brotli*.dll"},
        {"name": "UUID", "file_pattern": "uuid*.dll"}
    ],
    "linux": [
        {"name": "JsonCpp", "file_pattern": "libjsoncpp.so*"},
        {"name": "OpenSSL", "file_pattern": "libssl.so*"},
        {"name": "OpenSSL Crypto", "file_pattern": "libcrypto.so*"},
        {"name": "zlib", "file_pattern": "libz.so*"},
        {"name": "Brotli", "file_pattern": "libbrotli*.so*"},
        {"name": "UUID", "file_pattern": "libuuid.so*"}
    ],
    "darwin": [
        {"name": "JsonCpp", "file_pattern": "libjsoncpp*.dylib"},
        {"name": "OpenSSL", "file_pattern": "libssl*.dylib"},
        {"name": "OpenSSL Crypto", "file_pattern": "libcrypto*.dylib"},
        {"name": "zlib", "file_pattern": "libz*.dylib"},
        {"name": "Brotli", "file_pattern": "libbrotli*.dylib"},
        {"name": "UUID", "file_pattern": "libuuid*.dylib"}
    ]
}

# Colors for terminal output
COLORS = {
    "RESET": "\033[0m",
    "RED": "\033[91m",
    "GREEN": "\033[92m",
    "YELLOW": "\033[93m",
    "BLUE": "\033[94m",
    "MAGENTA": "\033[95m",
    "CYAN": "\033[96m",
    "BOLD": "\033[1m"
}

# Disable colors on Windows unless running in a terminal that supports them
if platform.system() == "Windows" and not os.environ.get("TERM"):
    for key in COLORS:
        COLORS[key] = ""


def colored(text, color):
    """Return colored text if supported by the terminal"""
    return f"{COLORS[color]}{text}{COLORS['RESET']}"


def print_header(text):
    """Print a header with formatting"""
    print(f"\n{colored('┌─' + '─' * len(text) + '─┐', 'CYAN')}")
    print(f"{colored('│ ', 'CYAN')}{colored(text, 'BOLD')}{colored(' │', 'CYAN')}")
    print(f"{colored('└─' + '─' * len(text) + '─┘', 'CYAN')}")


def print_result(name, status, message=""):
    """Print a test result with colored status"""
    if status == "PASS":
        status_colored = colored("PASS", "GREEN")
    elif status == "WARN":
        status_colored = colored("WARN", "YELLOW")
    else:
        status_colored = colored("FAIL", "RED")
    
    if message:
        print(f"  {name:.<25} {status_colored} - {message}")
    else:
        print(f"  {name:.<25} {status_colored}")


def check_command_exists(command):
    """Check if a command exists on the system"""
    return shutil.which(command) is not None


def parse_version(version_str):
    """Parse version string into components"""
    # Extract the first version-like string from the text
    import re
    version_match = re.search(r'(\d+\.\d+(\.\d+)?)', version_str)
    if version_match:
        version = version_match.group(1)
        components = version.split('.')
        # Pad with zeros if needed
        while len(components) < 3:
            components.append('0')
        return [int(c) for c in components]
    return [0, 0, 0]


def compare_versions(version1, version2):
    """Compare two version strings, return True if version1 >= version2"""
    v1 = parse_version(version1)
    v2 = parse_version(version2)
    
    return v1 >= v2


def check_tool(name, spec):
    """Check if a tool is available and meets version requirements"""
    command = spec["command"][0]
    
    # Special handling for cl.exe which must be in the Visual Studio environment
    if command == "cl" and platform.system() == "Windows":
        # Try to detect if running in VS Developer Command Prompt
        if "VSCMD_ARG_TGT_ARCH" not in os.environ:
            return False, "Visual Studio environment not activated"
        
        # Check if cl.exe is in PATH
        if not check_command_exists(command):
            return False, "Not found in PATH"
            
        return True, "Visual Studio environment detected"
    
    # Check if command exists
    if not check_command_exists(command):
        return False, "Not found in PATH"
    
    # Run the command to get version info
    try:
        # Some commands output to stderr
        result = subprocess.run(
            spec["command"], 
            capture_output=True, 
            text=True, 
            check=False
        )
        
        output = result.stdout or result.stderr
        
        # Special handling for vcpkg
        if command == "vcpkg":
            return True, "Available in PATH"
            
        # Check version if required
        if spec["min_version"]:
            if not compare_versions(output, spec["min_version"]):
                return False, f"Version too old (need {spec['min_version']}+)"
                
        return True, output.split('\n')[0].strip()
    except Exception as e:
        return False, f"Error running command: {e}"


def find_library_in_path(file_pattern):
    """Check if a library exists in the system path"""
    import fnmatch
    import re
    
    system = platform.system().lower()
    
    # Determine which environment variable to check
    if system == "windows":
        path_var = "PATH"
        separator = ";"
    elif system == "darwin":
        path_var = "DYLD_LIBRARY_PATH"
        separator = ":"
    else:  # Linux and others
        path_var = "LD_LIBRARY_PATH"
        separator = ":"
    
    # Get the paths from environment
    paths = os.environ.get(path_var, "").split(separator)
    
    # Add standard system paths based on platform
    if system == "windows":
        paths.extend([
            "C:\\Windows\\System32",
            "C:\\vcpkg\\installed\\x64-windows\\bin"
        ])
    elif system == "darwin":
        paths.extend([
            "/usr/local/lib",
            "/usr/lib"
        ])
    else:  # Linux
        paths.extend([
            "/usr/local/lib",
            "/usr/lib",
            "/usr/lib/x86_64-linux-gnu"
        ])
    
    # Filter out empty paths
    paths = [p for p in paths if p.strip()]
    
    # Look for files matching pattern in paths
    for path in paths:
        if not os.path.exists(path):
            continue
        
        for file in os.listdir(path):
            if fnmatch.fnmatch(file.lower(), file_pattern.lower()):
                return True, os.path.join(path, file)
    
    return False, "Not found in library paths"


def check_cmake_modules():
    """Check if CMake can find required modules"""
    system = platform.system().lower()
    workspace_root = Path(__file__).resolve().parent.parent
    build_dir = workspace_root / "build" / "cmake_test"
    
    # Create a temporary directory for CMake test
    build_dir.mkdir(exist_ok=True, parents=True)
    
    # Create a test CMakeLists.txt file
    test_cmake = build_dir / "CMakeLists.txt"
    with open(test_cmake, "w") as f:
        f.write("""
cmake_minimum_required(VERSION 3.5)
project(DrogonDependencyTest)

# Find required packages
find_package(OpenSSL)
find_package(ZLIB)
find_package(jsoncpp)
find_package(UUID)

# Configure a header to pass information to C++ code
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/config.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/config.h"
)

# Create dummy output showing what was found
message(STATUS "OpenSSL found: ${OPENSSL_FOUND}")
message(STATUS "ZLIB found: ${ZLIB_FOUND}")
message(STATUS "jsoncpp found: ${jsoncpp_FOUND}")
message(STATUS "UUID found: ${UUID_FOUND}")
""")
    
    # Create a configuration header template
    config_header = build_dir / "config.h.in"
    with open(config_header, "w") as f:
        f.write("""
#define OPENSSL_FOUND @OPENSSL_FOUND@
#define ZLIB_FOUND @ZLIB_FOUND@
#define JSONCPP_FOUND @jsoncpp_FOUND@
#define UUID_FOUND @UUID_FOUND@
""")
    
    # Run cmake to test if it can find packages
    cmake_cmd = ["cmake", "."]
    
    # Add vcpkg toolchain on Windows
    if system == "windows":
        vcpkg_path = "C:/vcpkg/scripts/buildsystems/vcpkg.cmake"
        if os.path.exists(vcpkg_path):
            cmake_cmd.extend(["-DCMAKE_TOOLCHAIN_FILE=" + vcpkg_path])
    
    try:
        result = subprocess.run(
            cmake_cmd,
            cwd=str(build_dir),
            capture_output=True,
            text=True,
            check=False
        )
        
        # Check if packages were found
        packages_found = {
            "OpenSSL": "OpenSSL found: 1" in result.stdout,
            "ZLIB": "ZLIB found: 1" in result.stdout,
            "jsoncpp": "jsoncpp found: 1" in result.stdout,
            "UUID": "UUID found: 1" in result.stdout
        }
        
        return packages_found, result.stdout
    except Exception as e:
        return {
            "OpenSSL": False,
            "ZLIB": False,
            "jsoncpp": False,
            "UUID": False
        }, f"Error running CMake test: {e}"
    finally:
        # Clean up test directory
        try:
            import shutil
            shutil.rmtree(build_dir, ignore_errors=True)
        except:
            pass


def update_environment_path():
    """Update environment path variables with common library locations"""
    system = platform.system().lower()
    
    if system == "windows":
        # Add vcpkg and other common Windows paths
        vcpkg_path = "C:\\vcpkg\\installed\\x64-windows\\bin"
        if os.path.exists(vcpkg_path) and vcpkg_path not in os.environ.get("PATH", ""):
            os.environ["PATH"] = f"{vcpkg_path};{os.environ.get('PATH', '')}"
            print(f"Added to PATH: {vcpkg_path}")
    elif system == "darwin":
        # Add Homebrew and other common macOS paths
        paths_to_add = [
            "/usr/local/lib",
            "/usr/local/opt/openssl/lib",
            "/usr/local/opt/jsoncpp/lib"
        ]
        current_path = os.environ.get("DYLD_LIBRARY_PATH", "")
        for path in paths_to_add:
            if os.path.exists(path) and path not in current_path:
                current_path = f"{path}:{current_path}" if current_path else path
        os.environ["DYLD_LIBRARY_PATH"] = current_path
        print(f"Updated DYLD_LIBRARY_PATH: {current_path}")
    else:  # Linux
        # Add common Linux paths
        paths_to_add = [
            "/usr/local/lib",
            "/usr/lib",
            "/usr/lib/x86_64-linux-gnu"
        ]
        current_path = os.environ.get("LD_LIBRARY_PATH", "")
        for path in paths_to_add:
            if os.path.exists(path) and path not in current_path:
                current_path = f"{path}:{current_path}" if current_path else path
        os.environ["LD_LIBRARY_PATH"] = current_path
        print(f"Updated LD_LIBRARY_PATH: {current_path}")


def fix_missing_dependencies():
    """Attempt to fix missing dependencies"""
    system = platform.system().lower()
    
    if system == "windows":
        print("\nTo fix missing dependencies on Windows, try running:")
        print(colored("  cd C:\\vcpkg", "CYAN"))
        print(colored("  .\\vcpkg install jsoncpp:x64-windows zlib:x64-windows openssl:x64-windows uuid:x64-windows", "CYAN"))
        print(colored("  .\\vcpkg install brotli:x64-windows sqlite3:x64-windows libpq:x64-windows libmysql:x64-windows", "CYAN"))
        print(colored("  .\\vcpkg integrate install", "CYAN"))
    elif system == "darwin":
        print("\nTo fix missing dependencies on macOS, try running:")
        print(colored("  brew install cmake jsoncpp ossp-uuid zlib openssl brotli", "CYAN"))
        print(colored("  brew install sqlite3 postgresql mysql hiredis yaml-cpp", "CYAN"))
    else:  # Linux
        print("\nTo fix missing dependencies on Linux, try running:")
        if os.path.exists("/usr/bin/apt"):
            print(colored("  sudo apt update", "CYAN"))
            print(colored("  sudo apt install -y libjsoncpp-dev uuid-dev zlib1g-dev openssl libssl-dev", "CYAN"))
            print(colored("  sudo apt install -y libsqlite3-dev libpq-dev libmysqlclient-dev libhiredis-dev", "CYAN"))
        elif os.path.exists("/usr/bin/yum"):
            print(colored("  sudo yum install -y jsoncpp-devel uuid-devel zlib-devel openssl-devel", "CYAN"))
            print(colored("  sudo yum install -y sqlite-devel postgresql-devel mysql-devel", "CYAN"))
        else:
            print(colored("  Please install the required dependencies using your system's package manager.", "CYAN"))


def check_enviro_script_setup():
    """Check if environment setup scripts are properly installed"""
    workspace_root = Path(__file__).resolve().parent.parent
    system = platform.system().lower()
    
    if system == "windows":
        setup_script = workspace_root / "setup_env.ps1"
        if not setup_script.exists():
            print(colored("Warning: setup_env.ps1 not found. Environment setup script is missing.", "YELLOW"))
            return False
    else:  # Linux/macOS
        setup_script = workspace_root / "setup_env.sh"
        if not setup_script.exists():
            print(colored("Warning: setup_env.sh not found. Environment setup script is missing.", "YELLOW"))
            return False
    
    return True


def check_vscode_integration():
    """Check if VSCode integration is set up properly"""
    workspace_root = Path(__file__).resolve().parent.parent
    vscode_dir = workspace_root / ".vscode"
    
    required_files = ["settings.json", "tasks.json", "launch.json"]
    missing_files = []
    
    for file in required_files:
        if not (vscode_dir / file).exists():
            missing_files.append(file)
    
    if missing_files:
        print(colored(f"Warning: VSCode integration missing: {', '.join(missing_files)}", "YELLOW"))
        return False
    
    return True


def main():
    """Main function that checks all dependencies and environment"""
    print_header("DROGON ENVIRONMENT VERIFICATION")
    
    # Update environment paths first to improve detection
    update_environment_path()
    
    # Detect system
    system = platform.system().lower()
    print(f"Detected platform: {colored(system.capitalize(), 'BOLD')}")
    
    # Check basic environment setup
    print_header("CHECKING ENVIRONMENT SETUP")
    enviro_script_setup = check_enviro_script_setup()
    print_result("Environment scripts", "PASS" if enviro_script_setup else "WARN", 
                "Setup scripts found" if enviro_script_setup else "Setup scripts missing")
    
    vscode_integration = check_vscode_integration()
    print_result("VSCode integration", "PASS" if vscode_integration else "WARN",
                "VSCode settings found" if vscode_integration else "VSCode settings incomplete")
    
    # Check required tools
    print_header("CHECKING REQUIRED TOOLS")
    all_tools_available = True
    
    # Check common required tools
    for name, spec in COMMON_REQUIRED.items():
        success, message = check_tool(name, spec)
        print_result(spec["name"], "PASS" if success else "FAIL", message)
        if not success:
            all_tools_available = False
    
    # Check platform-specific tools
    if system in PLATFORM_REQUIRED:
        for name, spec in PLATFORM_REQUIRED[system].items():
            success, message = check_tool(name, spec)
            print_result(spec["name"], "PASS" if success else "FAIL", message)
            if not success:
                all_tools_available = False
    
    # Check libraries
    print_header("CHECKING REQUIRED LIBRARIES")
    all_libs_available = True
    
    if system in REQUIRED_LIBRARIES:
        for lib in REQUIRED_LIBRARIES[system]:
            success, path = find_library_in_path(lib["file_pattern"])
            if success:
                print_result(lib["name"], "PASS", f"Found at {path}")
            else:
                print_result(lib["name"], "FAIL", path)
                all_libs_available = False
    
    # Check CMake modules
    print_header("CHECKING CMAKE MODULES")
    cmake_packages, cmake_output = check_cmake_modules()
    
    for package, found in cmake_packages.items():
        print_result(package, "PASS" if found else "FAIL", 
                    "CMake can find package" if found else "Package not found by CMake")
        if not found:
            all_libs_available = False
    
    # Summary and recommendations
    print_header("SUMMARY")
    
    if all_tools_available and all_libs_available:
        print(colored("✓ All dependencies are properly set up!", "GREEN"))
        print(colored("✓ Your environment is ready for Drogon development.", "GREEN"))
    else:
        print(colored("⚠ Some dependencies are missing or not correctly set up.", "YELLOW"))
        print(colored("  Please install the missing dependencies and update your environment paths.", "YELLOW"))
        fix_missing_dependencies()
    
    # Create a JSON report
    workspace_root = Path(__file__).resolve().parent.parent
    report = {
        "timestamp": str(datetime.now().isoformat()),
        "platform": system,
        "tools": {},
        "libraries": {},
        "cmake_packages": cmake_packages,
        "environment_setup": {
            "scripts_setup": enviro_script_setup,
            "vscode_integration": vscode_integration
        }
    }
    
    # Add tools to report
    for name, spec in COMMON_REQUIRED.items():
        success, message = check_tool(name, spec)
        report["tools"][name] = {
            "available": success,
            "message": message
        }
    
    # Add platform-specific tools
    if system in PLATFORM_REQUIRED:
        for name, spec in PLATFORM_REQUIRED[system].items():
            success, message = check_tool(name, spec)
            report["tools"][name] = {
                "available": success,
                "message": message
            }
    
    # Add libraries
    if system in REQUIRED_LIBRARIES:
        for lib in REQUIRED_LIBRARIES[system]:
            success, path = find_library_in_path(lib["file_pattern"])
            report["libraries"][lib["name"]] = {
                "available": success,
                "path": path if success else None
            }
    
    # Save report
    report_file = workspace_root / "scripts" / "environment_report.json"
    with open(report_file, "w") as f:
        json.dump(report, f, indent=2)
    
    print(f"\nDetailed report saved to: {report_file}")
    return 0 if all_tools_available and all_libs_available else 1


if __name__ == "__main__":
    try:
        from datetime import datetime
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nVerification cancelled by user.")
        sys.exit(130)
    except Exception as e:
        print(colored(f"\nError during verification: {e}", "RED"))
        sys.exit(1)
