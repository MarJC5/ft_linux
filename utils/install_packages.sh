#!/bin/bash

# Base directory for the script relative to where it's executed from
BASE_DIR=$(dirname "$(realpath "$0")")

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Path to the package configuration file
config_file="${BASE_DIR}/../config/system.conf"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to download and install a package
install_package() {
    local name="$1"
    local version="$2"
    local url="$3"
    local md5="$4"

    # Determine the file extension from the URL
    local filename=$(basename "$url")
    local file_extension="${filename##*.}"
    local file_name="$name-$version.$file_extension"

    echo "Installing $name version $version..."
    wget -q -O "$file_name" "$url"

    if [ -n "$md5" ]; then
        local md5_check=$(md5sum "$file_name" | awk '{ print $1 }')
        if [ "$md5_check" != "$md5" ]; then
            echo "MD5 mismatch. Exiting installation for $name."
            return
        fi
    fi

    # Unpack based on file extension
    case "$file_extension" in
        tar.gz|tgz)
            tar -xzf "$file_name"
            ;;
        tar.bz2|tbz|tbz2)
            tar -xjf "$file_name"
            ;;
        tar.xz|txz)
            tar -xJf "$file_name"
            ;;
        tar)
            tar -xf "$file_name"
            ;;
        gz)
            gunzip "$file_name"
            ;;
        bz2)
            bzip2 -d "$file_name"
            ;;
        xz)
            unxz "$file_name"
            ;;
        *)
            echo "Unsupported file extension: $file_extension"
            return
            ;;
    esac

    local extracted_dir="${file_name%.*}"
    if [ -d "$extracted_dir" ]; then
        cd "$extracted_dir"
    else
        # Handle cases where the directory name does not match the file name minus the extension
        cd $(find . -maxdepth 1 -type d | head -n 2 | tail -n 1)
    fi

    if ./configure && make; then
        sudo make install
        echo "$name installed successfully."
    else
        echo "Failed to build $name."
    fi
    cd ..
}

# Function to parse .conf file and install each package
install_from_conf() {
    local conf_file="$1"
    while IFS= read -r line; do
        if [[ "$line" == "["*"]" ]]; then
            package_name=$(echo "$line" | tr -d '[]')
            version=""
            download=""
            md5=""
        elif [[ "$line" == "version = "* ]]; then
            version=$(echo "$line" | cut -d' ' -f3)
        elif [[ "$line" == "download = "* ]]; then
            download=$(echo "$line" | cut -d' ' -f3)
        elif [[ "$line" == "md5 = "* ]]; then
            md5=$(echo "$line" | cut -d' ' -f3)
        elif [[ -z "$line" ]]; then
            install_package "$package_name" "$version" "$download" "$md5"
        fi
    done < "$conf_file"
}

# Main script starts here
if [ ! -f "$config_file" ]; then
    echo "Configuration file not found: $config_file"
    exit 1
fi

install_from_conf "$config_file"
