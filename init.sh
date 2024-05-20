#!/bin/bash

# - Partition the disk (boot, root, swap)
# - Check the vm deps & packages versions
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

# Partition the disk
bash ./setup/partition_disk.sh

# Check the vm deps & packages versions
bash ./setup/install_deps.sh
bash ./setup/check_deps.sh

# Build the kernel
if [ $? -eq 0 ]; then
    # bash ./setup/build_kernel.sh
else
    echo "Error: not all dependencies are installed to build the kernel"
    exit 1
fi
