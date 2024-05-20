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

    # Base directory for the script relative to where it's executed from
    BASE_DIR=$(dirname "$(realpath "$0")")

    # Define the path to the configuration file
    config_file="${BASE_DIR}/../config/disk.conf"

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

    source "${BASE_DIR}/../utils/parser.sh"

    # Load configuration
    sys_name=$(parse_ini "system" "name" "$config_file")
    LFS="/mnt/${sys_name}"

    # Extract the packages
    echo -e "${GREEN}Extracting package...${NC}"
    tar -xf "${LFS}/sources/${package}" -C "${LFS}/${dest}"
    echo -e "${GREEN}Package extracted successfully${NC}"
}