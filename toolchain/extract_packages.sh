#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine the directory where the script is located, resolving symlinks
source "/media/share/utils/resolver.sh"

# Define the path to the configuration file
config_file="${config_path}/disk.conf"

# Check if the configuration file exists
if [ ! -f "$config_file" ]; then
    echo -e "${RED}Configuration file not found: $config_file${NC}"
    exit 1
fi

# Source other scripts from the correct path
source "${utils_path}/parser.sh"

# Load configuration
sys_name=$(parse_ini "system" "name" "$config_file")
LFS="/mnt/${sys_name}"

# Processing packages
for package in $(cat "${config_path}/packages"); do
    if [ -f "${packages_path}/${package}.sh" ]; then
        source "${packages_path}/${package}.sh"
    fi
done
