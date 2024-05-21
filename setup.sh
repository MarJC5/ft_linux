#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Base directory for the script relative to where it's executed from
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

# export the LFS variable
echo "Exporting LFS variable..."
export LFS="/mnt/${sys_name}"
echo "LFS variable exported as $LFS"

# Save LFS variable to /etc/profile if not already there
if ! grep -qs "export LFS" /etc/profile; then
    echo "export LFS=${LFS}" >> /etc/profile
    echo "export LFS_SCRIPT_PATH=${base_path}" >> /etc/profile
    echo "LFS variable saved to /etc/profile"
fi

# Source the /etc/profile file
source /etc/profile

# Create ~/.bashrc if it doesn't exist
if [ ! -f ~/.bashrc ]; then
    echo "Creating ~/.bashrc..."
    touch ~/.bashrc
fi

# Save LFS variable to ~/.bashrc if not already there
if ! grep -qs "export LFS" ~/.bashrc; then
    echo "export LFS=${LFS}" >> ~/.bashrc
    echo "LFS variable saved to ~/.bashrc"
fi

# Save LFS_SCRIPT_PATH variable to ~/.bashrc if not already there
if ! grep -qs "export LFS_SCRIPT_PATH" ~/.bashrc; then
    echo "export LFS_SCRIPT_PATH=${base_path}" >> ~/.bashrc
    echo "LFS_SCRIPT_PATH variable saved to ~/.bashrc"
fi

# Save LFS_TGT variable to ~/.bashrc if not already there
if ! grep -qs "export LFS_TGT" ~/.bashrc; then
    echo "export LFS_TGT=$(uname -m)-lfs-linux-gnu" >> ~/.bashrc
    echo "LFS_TGT variable saved to ~/.bashrc"
fi

# Source the ~/.bashrc file
source ~/.bashrc