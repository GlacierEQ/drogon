#!/usr/bin/env python3
"""
Drogon Intelligent Build Manager
--------------------------------
This script automatically configures, optimizes, and manages Drogon builds.
It learns from previous builds to improve performance over time.
"""

import os
import sys
import json
import time
import shutil
import platform
import subprocess
import multiprocessing
from datetime import datetime
from pathlib import Path

# Configuration
BUILD_HISTORY_FILE = "build_history.json"
OPTIMIZATION_FILE = "build_optimizations.json"
DEFAULT_CONFIGS = {
    "windows": {
        "generator": "Ninja",
        "compiler": "msvc",
        "parallel_jobs": min(multiprocessing.cpu_count(), 16),
        "optimization_level": "O2",
        "toolchain": "C:/vcpkg/scripts/buildsystems/vcpkg.cmake"
    },
    "linux": {
        "generator": "Ninja",
        "compiler": "gcc",
        "parallel_jobs": min(multiprocessing.cpu_count(), 16),
        "optimization_level": "O3",
        "toolchain": ""
    },
    "darwin": {
        "generator": "Ninja",
        "compiler": "clang",
        "parallel_jobs": min(multiprocessing.cpu_count(), 8),
        "optimization_level": "O2",
        "toolchain": ""
    }
}

class BuildManager:
    def __init__(self, workspace_root):
        self.workspace_root = Path(workspace_root)
        self.build_dir = self.workspace_root / "build"
        self.scripts_dir = self.workspace_root / "scripts"
        self.history_file = self.scripts_dir / BUILD_HISTORY_FILE
        self.optimization_file = self.scripts_dir / OPTIMIZATION_FILE
        self.system = platform.system().lower()
        
        # Ensure directories exist
        self.build_dir.mkdir(exist_ok=True)
        self.scripts_dir.mkdir(exist_ok=True)
        
        # Load build history and optimizations
        self.build_history = self._load_json(self.history_file, [])
        self.optimizations = self._load_json(self.optimization_file, DEFAULT_CONFIGS)
        
        # Detect environment
        self._detect_environment()
        
    def _load_json(self, file_path, default_value):
        """Load JSON file or return default if file doesn't exist"""
        try:
            if file_path.exists():
                with open(file_path, 'r') as f:
                    return json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load {file_path}: {e}")
        return default_value
        
    def _save_json(self, file_path, data):
        """Save data to JSON file"""
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def _detect_environment(self):
        """Detect build environment and available tools"""
        self.config = self.optimizations.get(self.system, DEFAULT_CONFIGS[self.system])
        
        # Detect compilers
        if self.system == "windows":
            self._detect_windows_environment()
        elif self.system == "linux":
            self._detect_linux_environment()
        elif self.system == "darwin":
            self._detect_macos_environment()
    
    def _detect_windows_environment(self):
        """Detect Visual Studio and other tools on Windows"""
        # Try to find VS installation path
        vs_paths = [
            os.environ.get("VS_PATH", ""),
            r"C:\Program Files\Microsoft Visual Studio\2022",
            r"C:\Program Files\Microsoft Visual Studio\2019",
            r"C:\Program Files (x86)\Microsoft Visual Studio\2019"
        ]
        
        editions = ["Community", "Professional", "Enterprise", "BuildTools"]
        
        for vs_path in vs_paths:
            if not vs_path or not os.path.exists(vs_path):
                continue
            
            for edition in editions:
                vcvars_path = os.path.join(vs_path, edition, "VC", "Auxiliary", "Build", "vcvarsall.bat")
                if os.path.exists(vcvars_path):
                    self.config["vs_path"] = vs_path
                    self.config["vcvars_path"] = vcvars_path
                    self.config["vs_edition"] = edition
                    break
            
            if "vs_path" in self.config:
                break
        
        # Check if Ninja exists
        try:
            subprocess.run(["ninja", "--version"], stdout=subprocess.PIPE, check=True)
            self.config["has_ninja"] = True
        except (subprocess.SubprocessError, FileNotFoundError):
            self.config["has_ninja"] = False
            # Fall back to Visual Studio generator if Ninja is not available
            if "vs_path" in self.config:
                vs_year = "2022" if "2022" in self.config["vs_path"] else "2019"
                self.config["generator"] = f"Visual Studio {17 if vs_year=='2022' else 16} {vs_year}"
    
    def _detect_linux_environment(self):
        """Detect compilers and tools on Linux"""
        # Check for GCC and Clang
        try:
            gcc_version = subprocess.run(["gcc", "--version"], stdout=subprocess.PIPE, text=True, check=False).stdout
            self.config["gcc_version"] = gcc_version.split("\n")[0] if gcc_version else ""
            self.config["has_gcc"] = bool(self.config["gcc_version"])
        except (subprocess.SubprocessError, FileNotFoundError):
            self.config["has_gcc"] = False
            
        try:
            clang_version = subprocess.run(["clang", "--version"], stdout=subprocess.PIPE, text=True, check=False).stdout
            self.config["clang_version"] = clang_version.split("\n")[0] if clang_version else ""
            self.config["has_clang"] = bool(self.config["clang_version"])
        except (subprocess.SubprocessError, FileNotFoundError):
            self.config["has_clang"] = False
        
        # Set compiler preference
        if not self.config["has_gcc"] and self.config["has_clang"]:
            self.config["compiler"] = "clang"
        
        # Check for Ninja
        try:
            subprocess.run(["ninja", "--version"], stdout=subprocess.PIPE, check=True)
            self.config["has_ninja"] = True
        except (subprocess.SubprocessError, FileNotFoundError):
            self.config["has_ninja"] = False
            self.config["generator"] = "Unix Makefiles"
    
    def _detect_macos_environment(self):
        """Detect compilers and tools on macOS"""
        # macOS typically uses Clang
        try:
            clang_version = subprocess.run(["clang", "--version"], stdout=subprocess.PIPE, text=True, check=False).stdout
            self.config["clang_version"] = clang_version.split("\n")[0] if clang_version else ""
            self.config["has_clang"] = bool(self.config["clang_version"])
        except (subprocess.SubprocessError, FileNotFoundError):
            self.config["has_clang"] = False
        
        # Check for Ninja
        try:
            subprocess.run(["ninja", "--version"], stdout=subprocess.PIPE, check=True)
            self.config["has_ninja"] = True
        except (subprocess.SubprocessError, FileNotFoundError):
            self.config["has_ninja"] = False
            self.config["generator"] = "Unix Makefiles"
    
    def generate_cmake_config(self):
        """Generate CMake configuration command based on environment and history"""
        cmake_args = ["cmake"]
        
        # Add source directory
        cmake_args.extend(["-S", str(self.workspace_root)])
        
        # Add build directory
        cmake_args.extend(["-B", str(self.build_dir)])
        
        # Add generator
        if self.config.get("generator"):
            cmake_args.extend(["-G", self.config["generator"]])
        
        # Add toolchain file if available
        if self.config.get("toolchain"):
            cmake_args.extend([f"-DCMAKE_TOOLCHAIN_FILE={self.config['toolchain']}"])
        
        # Add compiler settings
        if self.system == "linux" or self.system == "darwin":
            if self.config["compiler"] == "gcc":
                cmake_args.extend(["-DCMAKE_C_COMPILER=gcc", "-DCMAKE_CXX_COMPILER=g++"])
            elif self.config["compiler"] == "clang":
                cmake_args.extend(["-DCMAKE_C_COMPILER=clang", "-DCMAKE_CXX_COMPILER=clang++"])
        
        # Add optimization flags
        opt_level = self.config.get("optimization_level", "O2")
        cmake_args.append(f"-DCMAKE_CXX_FLAGS=-{opt_level}")
        
        # Add build type
        cmake_args.append("-DCMAKE_BUILD_TYPE=Release")
        
        # Add any learned optimizations from previous builds
        if "cmake_extra_args" in self.config:
            cmake_args.extend(self.config["cmake_extra_args"])
        
        return cmake_args
    
    def generate_build_command(self):
        """Generate build command based on environment and history"""
        build_args = ["cmake", "--build", str(self.build_dir)]
        
        # Add parallel jobs
        jobs = self.config.get("parallel_jobs", multiprocessing.cpu_count())
        build_args.extend(["--parallel", str(jobs)])
        
        # Add build type for multi-config generators (Visual Studio)
        if self.system == "windows" and not self.config.get("generator", "").startswith("Ninja"):
            build_args.extend(["--config", "Release"])
        
        return build_args
    
    def _run_windows_with_vcvars(self, cmd):
        """Run command with Visual Studio environment on Windows"""
        if "vcvars_path" not in self.config:
            return subprocess.run(cmd, check=False)
        
        # Create a batch file to set up environment and run command
        temp_batch = self.build_dir / "temp_build_cmd.bat"
        with open(temp_batch, "w") as f:
            f.write(f"@echo off\n")
            f.write(f"call \"{self.config['vcvars_path']}\" x64\n")
            f.write(" ".join(cmd) + "\n")
        
        result = subprocess.run([temp_batch], check=False)
        
        # Clean up temp file
        try:
            os.remove(temp_batch)
        except:
            pass
            
        return result
    
    def configure(self):
        """Run CMake configuration"""
        cmake_cmd = self.generate_cmake_config()
        print(f"Running CMake configuration: {' '.join(cmake_cmd)}")
        
        start_time = time.time()
        
        # Run CMake configure command
        if self.system == "windows" and "vcvars_path" in self.config:
            result = self._run_windows_with_vcvars(cmake_cmd)
        else:
            result = subprocess.run(cmake_cmd, check=False)
        
        end_time = time.time()
        success = result.returncode == 0
        
        # Record configure stats
        self.build_history.append({
            "timestamp": datetime.now().isoformat(),
            "type": "configure",
            "command": " ".join(cmake_cmd),
            "success": success,
            "duration": end_time - start_time,
            "returncode": result.returncode
        })
        
        self._save_json(self.history_file, self.build_history)
        return success
    
    def build(self):
        """Run the build command"""
        build_cmd = self.generate_build_command()
        print(f"Running build: {' '.join(build_cmd)}")
        
        start_time = time.time()
        
        # Run build command
        if self.system == "windows" and "vcvars_path" in self.config:
            result = self._run_windows_with_vcvars(build_cmd)
        else:
            result = subprocess.run(build_cmd, check=False)
        
        end_time = time.time()
        success = result.returncode == 0
        
        # Record build stats
        self.build_history.append({
            "timestamp": datetime.now().isoformat(),
            "type": "build",
            "command": " ".join(build_cmd),
            "success": success,
            "duration": end_time - start_time,
            "returncode": result.returncode
        })
        
        self._save_json(self.history_file, self.build_history)
        
        # If successful, analyze build for optimizations
        if success:
            self._analyze_and_optimize()
        
        return success
    
    def _analyze_and_optimize(self):
        """Analyze build history and optimize future builds"""
        # This is a simple implementation that could be expanded with more sophisticated analysis
        successful_builds = [b for b in self.build_history[-10:] if b["type"] == "build" and b["success"]]
        if not successful_builds:
            return
        
        # Calculate average build time
        avg_build_time = sum(b["duration"] for b in successful_builds) / len(successful_builds)
        
        # Adjust parallel jobs based on build time trend
        if len(successful_builds) >= 3:
            # Check if builds are getting faster
            if successful_builds[-1]["duration"] < avg_build_time * 0.9:
                # Increase parallelism slightly
                self.config["parallel_jobs"] = min(self.config["parallel_jobs"] + 1, multiprocessing.cpu_count() * 2)
            # Check if builds are getting slower
            elif successful_builds[-1]["duration"] > avg_build_time * 1.1 and self.config["parallel_jobs"] > 1:
                # Decrease parallelism slightly
                self.config["parallel_jobs"] = max(self.config["parallel_jobs"] - 1, 1)
        
        # Save optimizations
        self.optimizations[self.system] = self.config
        self._save_json(self.optimization_file, self.optimizations)
    
    def clean(self):
        """Clean the build directory"""
        if self.build_dir.exists():
            # Use CMake clean if build system files exist
            if (self.build_dir / "CMakeCache.txt").exists():
                clean_cmd = ["cmake", "--build", str(self.build_dir), "--target", "clean"]
                
                if self.system == "windows" and "vcvars_path" in self.config:
                    self._run_windows_with_vcvars(clean_cmd)
                else:
                    subprocess.run(clean_cmd, check=False)
            else:
                # Otherwise remove build dir contents but keep the directory
                for item in self.build_dir.iterdir():
                    if item.is_file():
                        item.unlink()
                    elif item.is_dir():
                        shutil.rmtree(item)
    
    def generate_makefile(self):
        """Generate a platform-specific build script that will be auto-executed"""
        if self.system == "windows":
            makefile_path = self.workspace_root / "auto_make.bat"
            with open(makefile_path, "w") as f:
                f.write("@echo off\n")
                f.write("echo Running Drogon Auto Build System\n")
                f.write(f"python {self.scripts_dir / 'auto_build_manager.py'} build\n")
                f.write("if %ERRORLEVEL% NEQ 0 (\n")
                f.write("    echo Build failed!\n")
                f.write("    exit /b %ERRORLEVEL%\n")
                f.write(")\n")
            
            # Make executable
            try:
                os.chmod(makefile_path, 0o755)
            except:
                pass
        else:
            makefile_path = self.workspace_root / "Makefile"
            with open(makefile_path, "w") as f:
                f.write("# Auto-generated Makefile for Drogon\n")
                f.write("\n")
                f.write(".PHONY: all clean\n")
                f.write("\n")
                f.write("all:\n")
                f.write(f"\tpython3 {self.scripts_dir / 'auto_build_manager.py'} build\n")
                f.write("\n")
                f.write("clean:\n")
                f.write(f"\tpython3 {self.scripts_dir / 'auto_build_manager.py'} clean\n")
            
            # Make executable
            try:
                os.chmod(makefile_path, 0o755)
            except:
                pass
        
        print(f"Generated build script at {makefile_path}")
    
    def generate_vscode_integration(self):
        """Generates VSCode integration files"""
        vscode_dir = self.workspace_root / ".vscode"
        vscode_dir.mkdir(exist_ok=True)
        
        # Create tasks.json with build tasks
        tasks_file = vscode_dir / "tasks.json"
        tasks = {
            "version": "2.0.0",
            "tasks": [
                {
                    "label": "Auto-Build Drogon (Intelligent)",
                    "type": "shell",
                    "command": "python",
                    "args": [
                        "${workspaceFolder}/scripts/auto_build_manager.py",
                        "build"
                    ],
                    "group": {
                        "kind": "build",
                        "isDefault": True
                    },
                    "problemMatcher": ["$gcc", "$msCompile"],
                    "presentation": {
                        "reveal": "always",
                        "panel": "shared"
                    },
                    "runOptions": {
                        "runOn": "folderOpen"
                    }
                },
                {
                    "label": "Clean Drogon Build",
                    "type": "shell",
                    "command": "python",
                    "args": [
                        "${workspaceFolder}/scripts/auto_build_manager.py",
                        "clean"
                    ],
                    "problemMatcher": []
                }
            ]
        }
        
        with open(tasks_file, "w") as f:
            json.dump(tasks, f, indent=2)
    
    def run_command(self, cmd):
        """Run a specific command"""
        if cmd == "configure":
            return self.configure()
        elif cmd == "build":
            # Configure first, then build
            if not self.configure():
                return False
            return self.build()
        elif cmd == "clean":
            self.clean()
            return True
        elif cmd == "generate-makefile":
            self.generate_makefile()
            return True
        elif cmd == "setup-vscode":
            self.generate_vscode_integration()
            return True
        else:
            print(f"Unknown command: {cmd}")
            return False

def main():
    workspace_root = os.environ.get("DROGON_WORKSPACE_ROOT")
    if not workspace_root:
        workspace_root = Path(__file__).resolve().parent.parent
    
    manager = BuildManager(workspace_root)
    
    if len(sys.argv) < 2:
        print("Usage: python auto_build_manager.py [configure|build|clean|generate-makefile|setup-vscode]")
        return 1
    
    cmd = sys.argv[1]
    success = manager.run_command(cmd)
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
