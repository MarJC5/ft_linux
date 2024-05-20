#!/bin/bash

# SETUP SCRIPT
# - Check the vm deps & packages versions
# - Partition the disk (boot, root, swap)
# - Mount the partitions
# - Download the packages & verify them
# - Build layouts
# - Create the user and set the password
# TOOLCHAIN SCRIPT
# - Extract the packages


# Exit on error
set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Check the vm deps & packages versions
bash ./setup.sh
bash ./setup/install_deps.sh
bash ./setup/check_deps.sh

# Main script
if [ $? -eq 0 ]; then
    # Run the setup scripts
    bash ./setup/partition_disk.sh
    bash ./setup/mount_partition.sh
    bash ./setup/setup_packages.sh
    bash ./setup/setup_layout.sh
    bash ./setup/setup_user.sh
    # Run the toolchain scripts
    bash ./toolchain/extract_packages.sh
else
    echo "Error: not all dependencies are installed to build the kernel"
    exit 1
fi
