#!/bin/bash

# - Check the vm deps & packages versions
# - Partition the disk (boot, root, swap)
# - Build the kernel
# - Copy the kernel to the boot partition
# - Copy the modules to the root partition
# - Update the bootloader configuration
# - Reboot

# Exit on error
set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Base directory for the script relative to where it's executed from
BASE_DIR=$(dirname "$(realpath "$0")")

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

source "${BASE_DIR}/utils/parser.sh"

# Load configuration
sys_name=$(parse_ini "system" "name" "$config_file")

# export the LFS variable
echo "Exporting LFS variable..."
export LFS="/mnt/${sys_name}"
echo "LFS variable exported as $LFS"

# Check the vm deps & packages versions
bash ./setup/install_deps.sh
bash ./setup/check_deps.sh

# Main script
if [ $? -eq 0 ]; then
    # Partition the disk
    bash ./setup/partition_disk.sh
    bash ./setup/mount_partition.sh
    # bash ./setup/build_kernel.sh
else
    echo "Error: not all dependencies are installed to build the kernel"
    exit 1
fi
