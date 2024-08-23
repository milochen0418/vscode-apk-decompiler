#!/bin/bash

# Check if an APK file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <apk-file>"
    exit 1
fi

apkfile=$1

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please resolve the Homebrew installation issue. Possible steps:"
    echo "1. Open Terminal."
    echo "2. Run the following command to install Homebrew:"
    echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
    echo "For more information, visit https://brew.sh"
    exit 1
else
    echo "Homebrew is already installed."
fi

# Check if apktool is installed
# apktool is used to unpack APK files into smali code and view the full AndroidManifest.xml
if ! command -v apktool &> /dev/null
then
    echo "apktool could not be found, installing..."
    brew install apktool
fi

# Check if jadx is installed
# jadx decompiles smali into Java code; in VSCode, we use the Smali2Java extension to convert smali to Java files for viewing.
if ! command -v jadx &> /dev/null
then
    echo "jadx could not be found, installing..."
    brew install jadx
fi

# Path to the VSCode extension directory
VSCODE_EXTENSIONS="$HOME/.vscode/extensions"

# Check if the Smalise extension is installed
if ls "$VSCODE_EXTENSIONS" | grep -q "smalise"; then
    echo "Smalise extension is installed."
else
    echo "Please install the Smalise extension in VSCode."
fi

# Check if the Smali2Java extension is installed
if ls "$VSCODE_EXTENSIONS" | grep -q "smali2java"; then
    echo "Smali2Java extension is installed."
else
    echo "Please install the Smali2Java extension in VSCode."
fi

setup_jadx_path_for_smali2java_vscode_extension() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed, installing via brew..."
        brew install jq
        if [ $? -ne 0 ]; then
            echo "Failed to install jq. Please install jq manually and retry."
            return 1
        fi
    fi

    # Path to the Visual Studio Code extension directory
    VSCODE_EXTENSIONS="$HOME/.vscode/extensions"

    # Locate the Smali2Java extension directory
    smali2java_dir=$(find "$VSCODE_EXTENSIONS" -type d -name "*smali2java*" -print -quit)

    if [ -z "$smali2java_dir" ]; then
        echo "Could not find the Smali2Java extension directory."
        return 1
    else
        echo "Smali2Java extension directory found at: $smali2java_dir"
    fi

    # Locate the package.json file
    package_json="$smali2java_dir/package.json"

    # Check if jadx path is already set
    jadx_path=$(jq -r '.contributes.configuration.properties["smali2java.decompiler.jadx.path"].default' "$package_json")

    if [ "$jadx_path" == "null" ]; then
        echo "smali2java.decompiler.jadx.path is not set. Setting it now..."

        # Find the path to the jadx executable
        jadx_executable=$(which jadx)
        if [ -z "$jadx_executable" ]; then
            echo "Could not find jadx. Please ensure jadx is installed."
            return 1
        fi

        # Set the jadx path using jq
        jq '.contributes.configuration.properties["smali2java.decompiler.jadx.path"].default = "'$jadx_executable'"' "$package_json" > tmp.$$.json && mv tmp.$$.json "$package_json"

        echo "smali2java.decompiler.jadx.path has been set to $jadx_executable."
        echo "Please restart VSCode to apply the new smali2java.decompiler.jadx.path setting."
    else
        echo "smali2java.decompiler.jadx.path is already set to $jadx_path."
    fi
}

# Ensure that the jadx path is correctly set in the smali2java VSCode extension
setup_jadx_path_for_smali2java_vscode_extension
# Capture the return value of the previous command
return_value=$?

# Handle success or failure based on the return value
if [ "$return_value" -eq 0 ]; then
    echo "setup_jadx_path_for_smali2java_vscode_extension function executed successfully."
else
    echo "setup_jadx_path_for_smali2java_vscode_extension function failed, return value: $return_value."
    # You can add additional handling code here
fi

# Determine the output directory
output_dir="/tmp/$(basename "$apkfile" .apk)"

# Check if the output directory already exists
if [ -d "$output_dir" ]; then
    echo "Directory $output_dir already exists, deleting it..."
    rm -rf "$output_dir"
fi

# Use apktool to unpack the APK
apktool d "$apkfile" -o "$output_dir"

echo "Unpacking complete, output directory: $output_dir"

# Open the output directory in VSCode
code "$output_dir"
