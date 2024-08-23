import * as vscode from 'vscode';
import { exec, spawn } from 'child_process';

export function activate(context: vscode.ExtensionContext) {

    // Create an output channel for the extension
    const outputChannel = vscode.window.createOutputChannel('APK Decompiler');

    let disposable = vscode.commands.registerCommand('extension.decompileApk', () => {
        vscode.window.showOpenDialog({
            canSelectMany: false,
            openLabel: 'Select APK',
            filters: {
                'APK files': ['apk']
            }
        }).then(fileUri => {
            if (fileUri && fileUri[0]) {
                const apkPath = fileUri[0].fsPath;
                const scriptPath = context.asAbsolutePath('scripts/watch_decompile_apk.sh');

                outputChannel.show(true); // Show the output channel
                outputChannel.appendLine(`Starting decompilation of ${apkPath}...`);

                // Use spawn instead of exec to get real-time output
                const process = spawn(scriptPath, [apkPath]);

                process.stdout.on('data', (data) => {
                    outputChannel.appendLine(data.toString());
                });

                process.stderr.on('data', (data) => {
                    outputChannel.appendLine(`Error: ${data.toString()}`);
                });

                process.on('close', (code) => {
                    if (code === 0) {
                        vscode.window.showInformationMessage('APK decompilation completed successfully.');
                        outputChannel.appendLine('Decompilation completed successfully.');
                    } else {
                        vscode.window.showErrorMessage(`APK decompilation failed with exit code ${code}.`);
                        outputChannel.appendLine(`Decompilation failed with exit code ${code}.`);
                    }
                });
            }
        });
    });

    context.subscriptions.push(disposable);
}

export function deactivate() {}
