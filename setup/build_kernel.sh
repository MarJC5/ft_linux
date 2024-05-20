#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Base directory for the script relative to where it's executed from
BASE_DIR=$(dirname "$(realpath "$0")")

# Path to the package configuration file
config_file="${BASE_DIR}/../config/kernel.conf"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if configuration file exists
if [ ! -f "$config_file" ]; then
    echo -e "${RED}Configuration file not found: $config_file${NC}"
    exit 1
fi

source "${BASE_DIR}/../utils/parser.sh"

# Load configuration
kernel_name=$(parse_ini "kernel" "name" "$config_file")
kernel_archive_path=$(find $LFS -type f -name "linux-*.tar.xz" | head -n 1)
version=$(echo $kernel_archive_path | sed -n 's/.*linux-\(.*\).tar.xz/\1/p')
kernel_extract_dir="${LFS}/usr/src/kernel-$version"

# Validate loaded configuration
if [ -z "$kernel_name" ]; then
    echo -e "${RED}Kernel configuration details are not fully specified in the configuration file.${NC}"
    exit 1
fi

echo -e "${YELLOW}Preparing to build Linux Kernel: $kernel_name${NC}"

# Check if the kernel source already exists
if [ -d "$kernel_extract_dir" ]; then
    echo -e "${RED}Kernel source already exists in $kernel_extract_dir.${NC}"
else
    # Extract the kernel source
    echo -e "${YELLOW}Extracting kernel source...${NC}"
    tar -xf "$kernel_archive_path" -C "$kernel_extract_dir" --strip-components=1

    # Check if extraction was successful
    if [ ! -d "$kernel_extract_dir" ]; then
        echo -e "${RED}Failed to extract kernel source to $kernel_extract_dir.${NC}"
        exit 1
    fi
fi

# Change directory to the kernel source
cd "$kernel_extract_dir" || exit

echo -e "${YELLOW}Configuring kernel...${NC}"
# Custom configuration setup
if [ -f "/boot/config-$(uname -r)" ]; then
    cp "/boot/config-$(uname -r)" .config
    yes '' | make oldconfig
else
    make defconfig
fi

# Append custom local version for identifying this build
echo "CONFIG_LOCALVERSION=\"-$kernel_name\"" >> .config

echo -e "${YELLOW}Compiling kernel...${NC}"
make -j$(nproc) || { echo -e "${RED}Failed to compile the kernel.${NC}"; exit 1; }

echo -e "${YELLOW}Installing kernel...${NC}"
make modules_install && make install || { echo -e "${RED}Failed to install the kernel.${NC}"; exit 1; }

# Update GRUB only if everything was successful
update-grub
echo -e "${GREEN}Kernel $kernel_name Version $version has been built and installed successfully.${NC}"
