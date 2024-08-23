# Decompile APK Extension

This is a VSCode extension that allows you to easily decompile APK files and view the code in VSCode.

## Features

- Decompile APK files using `apktool`.
- View Smali code and convert it to Java using `jadx` and the Smali2Java extension.

## Requirements

- [Homebrew](https://brew.sh)
- `jq`
- `apktool`
- `jadx`
- VSCode extensions: Smalise, Smali2Java

## Usage

1. Install the required tools:
```
brew install apktool jadx jq
```
2. Install the Smalise and Smali2Java extensions in VSCode.
3. Run the command "Decompile APK" from the Command Palette (`Ctrl+Shift+P`).
4. Select an APK file to decompile.

The decompiled APK will be opened in a new VSCode window, where you can browse and convert Smali code to Java.

## Release Notes

### 0.0.1

Initial release.