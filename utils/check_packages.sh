#!/bin/bash

# Base directory for the script relative to where it's executed from
BASE_DIR=$(dirname "$(realpath "$0")")

# Path to the package configuration file
config_file="${BASE_DIR}/../config/system.conf"

# Color codes
RED='\033[0;31m'
REDB='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a package and its version are installed
check_package_installed() {
    local name="$1"
    local required_version="$2"

    # Attempt to locate the package binary in the system path and extract the version number
    local version_command_output=$("$name" --version 2>/dev/null)
    local installed_version=$(echo "$version_command_output" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)

    # Check if the command exists and the version matches
    if [ -z "$installed_version" ]; then
        echo -e "${REDB}$name${NC} is ${RED}NOT${NC} installed.${NC}"
    elif [ "$installed_version" = "$required_version" ]; then
        echo -e "${GREEN}$name ($required_version) is correctly installed.${NC}"
    else
        echo -e "${REDB}$name${NC} version mismatch => expected ${RED}$required_version${NC} but found ${RED}$installed_version.${NC}"
    fi
}

# Function to parse .conf file and check each package
check_packages_from_conf() {
    local conf_file="$1"
    while IFS= read -r line; do
        if [[ "$line" == "["*"]" ]]; then
            package_name=$(echo "$line" | tr -d '[]')
            version=""
        elif [[ "$line" == "version = "* ]]; then
            version=$(echo "$line" | cut -d' ' -f3)
        elif [[ -z "$line" ]]; then
            check_package_installed "$package_name" "$version"
        fi
    done < "$conf_file"
}

# Main script starts here
if [ ! -f "$config_file" ]; then
    echo -e "${RED}Configuration file not found: $config_file${NC}"
    exit 1
fi

check_packages_from_conf "$config_file"
