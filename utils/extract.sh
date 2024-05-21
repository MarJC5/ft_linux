#!/bin/bash

# Function to extract the packages
extract_package() {
    local package="$1"
    local dest="$2"
    # Ensure the script is run as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi

    # Determine the directory where the script is located, resolving symlinks
    source "/media/share/utils/resolver.sh"

    # Define the path to the configuration file
    config_file="${config_path}/disk.conf"

    # Color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    # Check if the configuration file exists
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Configuration file not found: $config_file${NC}"
        exit 1
    fi

    source "${utils_path}/parser.sh"

    # Load configuration
    sys_name=$(parse_ini "system" "name" "$config_file")
    LFS="/mnt/${sys_name}"

    # Extract the packages
    echo -e "Extracting package ${YELLOW}${package}${NC}..."
    tar -xvf "${LFS}/sources/${package}" -C "${LFS}/${dest}"
    # Check if package is extracted successfully
    if [ $? -ne 0 ]; then
        echo -e "Failed to extract package ${RED}${package}${NC}"
        exit 1
    fi
    echo -e "Package ${GREEN}${package}${NC} extracted successfully to ${LFS}/${dest}"
}