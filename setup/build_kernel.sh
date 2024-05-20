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
version=$(parse_ini "kernel" "version" "$config_file")
download_url=$(parse_ini "kernel" "download_url" "$config_file")
kernel_name=$(parse_ini "kernel" "name" "$config_file")

# Validate loaded configuration
if [ -z "$version" ] || [ -z "$download_url" ] || [ -z "$kernel_name" ]; then
    echo -e "${RED}Kernel configuration details are not fully specified in the configuration file.${NC}"
    exit 1
fi

echo -e "${YELLOW}Preparing to build Linux Kernel: $kernel_name Version $version...${NC}"

# Define the correct paths and filenames
kernel_archive_path="/usr/src/linux-$version.tar.xz"
kernel_extract_dir="/usr/src/kernel-$version"

# Check if the kernel source already exists
if [ -d "$kernel_extract_dir" ]; then
    echo -e "${RED}Kernel source already exists in $kernel_extract_dir.${NC}"
else
    # Download the kernel source code
    echo -e "${YELLOW}Downloading kernel from $download_url...${NC}"
    wget "$download_url" -O "$kernel_archive_path"

    # Check if the download was successful
    if [ ! -f "$kernel_archive_path" ]; then
        echo -e "${RED}Failed to download the kernel source.${NC}"
        exit 1
    fi

    # Create the directory for extraction
    mkdir -p "$kernel_extract_dir"

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
echo "CONFIG_SYSTEM_TRUSTED_KEYS=\"\"" >> .config

echo -e "${YELLOW}Compiling kernel...${NC}"
make -j$(nproc) || { echo -e "${RED}Failed to compile the kernel.${NC}"; exit 1; }

echo -e "${YELLOW}Installing kernel...${NC}"
make modules_install && make install || { echo -e "${RED}Failed to install the kernel.${NC}"; exit 1; }

# Update GRUB only if everything was successful
update-grub
echo -e "${GREEN}Kernel $kernel_name Version $version has been built and installed successfully.${NC}"
