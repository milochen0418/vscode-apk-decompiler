#!/bin/bash

# Check if the script is running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script is only supported on macOS."
    exit 1
fi


# Check if an APK file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <apk-file>"
    exit 1
fi

apkfile=$1

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install it using the following command:"
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
    exit 1
else
    echo "Homebrew is already installed."
fi

# Install required packages using Homebrew
required_brews=("apktool" "jadx" "jq")
for brew_package in "${required_brews[@]}"; do
    if ! command -v $brew_package &> /dev/null; then
        echo "$brew_package could not be found, installing..."
        brew install $brew_package
    else
        echo "$brew_package is already installed."
    fi
done

# Function to find the VSCode executable
find_vscode_executable() {
    # Check if 'code' is available in the PATH
    if command -v code &> /dev/null; then
        echo "code"
        return 0
    fi

    # Check common installation paths
    local vscode_paths=(
        "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        "/usr/local/bin/code"
        "/usr/bin/code"
    )

    for path in "${vscode_paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    # If not found, prompt the user to input the path
    read -p "Could not find VSCode automatically. Please enter the path to the VSCode executable: " user_path
    if [ -x "$user_path" ]; then
        echo "$user_path"
        return 0
    else
        echo "Invalid path provided. Exiting..."
        return 1
    fi
}

# Get the VSCode executable path
code_cmd=$(find_vscode_executable)
if [ $? -ne 0 ]; then
    exit 1
fi

echo "Using VSCode executable: $code_cmd"

# Install required VSCode extensions
required_extensions=("loyieking.smalise" "ooooonly.smali2java")
for extension in "${required_extensions[@]}"; do
    if ! $code_cmd --list-extensions | grep -q "$extension"; then
        echo "VSCode extension $extension is not installed, installing..."
        $code_cmd --install-extension "$extension"
    else
        echo "VSCode extension $extension is already installed."
    fi
done

setup_jadx_path_for_smali2java_vscode_extension() {
    # Ensure jq is installed (already handled in the package installation step)

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
$code_cmd "$output_dir"
