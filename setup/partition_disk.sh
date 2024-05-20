#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Set the base directory for the script
BASE_DIR=$(dirname "$(realpath "$0")")

# Define the path to the configuration file
config_file="${BASE_DIR}/../config/disk.conf"

# Define color codes for output
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

# Create a partition on the disk to be used for the OS
echo -e "${YELLOW}Partitioning the disk...${NC}"


# Load configuration
disk=$(parse_ini "partition" "disk" "$config_file")
boot=$(parse_ini "partition" "boot" "$config_file")
root=$(parse_ini "partition" "root" "$config_file")
swap=$(parse_ini "partition" "swap" "$config_file")

# Confirm loaded configurations
echo "Disk to be partitioned: $disk"
echo "Boot Partition Size: $boot"
echo "Root Partition Size: ${root:-'all remaining space'}"
echo "Swap Partition Size: $swap"

# Define the disk to be partitioned
DISK="$disk"

# Unmount any mounted partitions that might be on the disk
echo "Unmounting any mounted partitions on $DISK..."
umount ${DISK}1 2> /dev/null || true
umount ${DISK}2 2> /dev/null || true
umount ${DISK}3 2> /dev/null || true

# Warning before wiping the disk
echo -e "${YELLOW}WARNING: This will wipe all data on $DISK. Proceed? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Wipe the disk
echo "Wiping $DISK..."
wipefs -a $DISK || { echo "${RED}Failed to wipe $DISK.${NC}"; exit 1; }

# Partition the disk
echo "Partitioning $DISK..."
{
    echo g # Create a new empty GPT partition table
    echo n # Add a new partition (/boot)
    echo 1 # Partition number 1
    echo   # First sector (Accept default: 2048 or whatever fdisk suggests)
    echo "+${boot}" # Last sector (Size of the boot partition)
    echo n # Add a new partition (swap)
    echo 2 # Partition number 2
    echo   # First sector (Accept default: automatically calculated)
    echo "+${swap}" # Last sector (Size of the swap partition)
    echo n # Add a new partition (root)
    echo 3 # Partition number 3
    echo   # First sector (Accept default: automatically calculated)
    echo   # Last sector (Accept default: uses remaining space)
    echo t # Change the partition type
    echo 2 # Select partition 2
    echo 82 # Set type to Linux swap
    echo w # Write changes
} | fdisk $DISK || { echo "${RED}Partitioning failed.${NC}"; exit 1; }

# Format the partitions
echo "Formatting partitions..."
mkfs.ext2 ${DISK}1 -L boot || { echo "${RED}Failed to format /boot partition.${NC}"; exit 1; }
mkfs.ext4 ${DISK}2 -L root || { echo "${RED}Failed to format root partition.${NC}"; exit 1; }
mkswap ${DISK}3 || { echo "${RED}Failed to initialize swap partition.${NC}"; exit 1; }
swapon ${DISK}3 || { echo "${RED}Failed to enable swap.${NC}"; exit 1; }

# Display the filesystems created
echo "Filesystems created:"
blkid | grep ${DISK}

echo "${GREEN}Partitioning and formatting completed successfully.${NC}"
