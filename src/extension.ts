import * as vscode from 'vscode';
import { exec } from 'child_process';

export function activate(context: vscode.ExtensionContext) {

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

                exec(`${scriptPath} ${apkPath}`, (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`Error: ${stderr}`);
                        return;
                    }
                    vscode.window.showInformationMessage(`Success: ${stdout}`);
                });
            }
        });
    });

    context.subscriptions.push(disposable);
}

export function deactivate() {}
