/**
 * VSCode Startup Script for Drogon
 * This script is executed when the VSCode workspace is opened
 * It configures the build environment and starts the intelligent build process
 */

const vscode = require('vscode');
const path = require('path');
const fs = require('fs');
const child_process = require('child_process');

/**
 * Activates the intelligent build system for Drogon
 * @param {vscode.ExtensionContext} context Extension context
 */
async function activate(context) {
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!workspaceRoot) return;

    const config = vscode.workspace.getConfiguration();
    const terminal = vscode.window.createTerminal('Drogon Build');
    
    // Check if auto build manager exists
    const buildManagerPath = path.join(workspaceRoot, 'scripts', 'auto_build_manager.py');
    
    if (!fs.existsSync(buildManagerPath)) {
        const choice = await vscode.window.showInformationMessage(
            'Drogon Intelligent Build Manager not found. Do you want to set it up?',
            'Yes', 'No'
        );
        
        if (choice === 'Yes') {
            await setupBuildManager(workspaceRoot, terminal);
        } else {
            return;
        }
    }
    
    // Show notification
    vscode.window.showInformationMessage('Drogon Intelligent Build System activated');
    
    // Start build manager setup
    terminal.sendText(`cd "${workspaceRoot}"`);
    terminal.sendText(`python "${buildManagerPath}" setup-vscode`);
    terminal.sendText(`python "${buildManagerPath}" generate-makefile`);
    
    // Suggest first build
    const buildChoice = await vscode.window.showInformationMessage(
        'Do you want to build Drogon now?',
        'Yes', 'No'
    );
    
    if (buildChoice === 'Yes') {
        terminal.sendText(`python "${buildManagerPath}" build`);
        terminal.show();
    }
    
    // Register command to run build manually
    context.subscriptions.push(
        vscode.commands.registerCommand('drogon.build', () => {
            terminal.sendText(`python "${buildManagerPath}" build`);
            terminal.show();
        })
    );
    
    // Register command to clean
    context.subscriptions.push(
        vscode.commands.registerCommand('drogon.clean', () => {
            terminal.sendText(`python "${buildManagerPath}" clean`);
            terminal.show();
        })
    );
    
    // Register command to configure only
    context.subscriptions.push(
        vscode.commands.registerCommand('drogon.configure', () => {
            terminal.sendText(`python "${buildManagerPath}" configure`);
            terminal.show();
        })
    );
}

/**
 * Set up the build manager if it doesn't exist
 */
async function setupBuildManager(workspaceRoot, terminal) {
    const scriptsDir = path.join(workspaceRoot, 'scripts');
    
    // Create scripts directory if it doesn't exist
    if (!fs.existsSync(scriptsDir)) {
        fs.mkdirSync(scriptsDir, { recursive: true });
    }
    
    // Copy build manager script from extension to workspace
    const buildManagerSrc = path.join(__dirname, 'auto_build_manager.py');
    const buildManagerDest = path.join(scriptsDir, 'auto_build_manager.py');
    
    fs.copyFileSync(buildManagerSrc, buildManagerDest);
    
    // Set up environment
    terminal.sendText(`cd "${workspaceRoot}"`);
    terminal.sendText(`python "${buildManagerDest}" setup-vscode`);
    terminal.sendText(`python "${buildManagerDest}" generate-makefile`);
    
    vscode.window.showInformationMessage('Drogon Intelligent Build Manager has been set up.');
}

// Export functions for VSCode extension API
exports.activate = activate;
