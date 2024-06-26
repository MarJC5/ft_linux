#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Set the base directory for the script
source "/media/share/utils/resolver.sh"

# Define the path to the configuration file
config_file="${config_path}/disk.conf"

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

source "${utils_path}/parser.sh"

# Create a partition on the disk to be used for the OS
echo -e "${YELLOW}Partitioning the disk...${NC}"

# Load configuration
disk=$(parse_ini "partition" "disk" "$config_file")
boot=$(parse_ini "partition" "boot" "$config_file")
root=$(parse_ini "partition" "root" "$config_file")
swap=$(parse_ini "partition" "swap" "$config_file")
sys_name=$(parse_ini "system" "name" "$config_file")

# Confirm loaded configurations
echo "Disk to be partitioned: $disk"
echo "Boot Partition Size: $boot"
echo "Root Partition Size: ${root:-'all remaining space'}"
echo "Swap Partition Size: $swap"

# Check if necessary partitions already exist
if lsblk -no NAME,TYPE $disk | grep -q "part"; then
  echo "Disk $disk already partitioned."
  exit 0
fi

# Define the disk to be partitioned
DISK="$disk"

# Unmount any mounted partitions that might be on the disk
echo "Unmounting any mounted partitions on $DISK..."
for part in $(ls ${DISK}* 2>/dev/null); do
  umount -l $part 2>/dev/null || true
done

# Check if the disk is still in use after attempting to unmount
if lsof | grep -q "$DISK"; then
  echo "Some processes are still using $DISK. Attempting to kill..."
  lsof | grep "$DISK" | awk '{print $2}' | xargs kill -9
fi

# Wait a bit to let the system release resources
sleep 2

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
    echo o # Create a new empty GPT partition table
    echo n # Add a new partition (/boot)
    echo p # Primary partition
    echo 1 # Partition number 1
    echo   # First sector (Accept default: 2048 or whatever fdisk suggests)
    echo "+${boot}" # Last sector (Size of the boot partition)
    echo n # Add a new partition (swap)
    echo p # Primary partition
    echo 2 # Partition number 2
    echo   # First sector (Accept default: automatically calculated)
    echo "+${swap}" # Last sector (Size of the swap partition)
    echo t # Change the partition type
    echo 2 # Select partition 2
    echo 82 # Set type to Linux swap
    echo n # Add a new partition (root)
    echo p # Primary partition
    echo 3 # Partition number 3
    echo   # First sector (Accept default: automatically calculated)
    echo   # Last sector (Accept default: uses remaining space)
    echo w # Write changes
} | fdisk $DISK || { echo "${RED}Partitioning failed.${NC}"; exit 1; }

# Format the partitions
echo "Formatting partitions..."
mkfs.ext2 ${DISK}1 -L boot || { echo "${RED}Failed to format /boot partition.${NC}"; exit 1; }
mkswap ${DISK}2 || { echo "${RED}Failed to initialize swap partition.${NC}"; exit 1; }
swapon ${DISK}2 || { echo "${RED}Failed to enable swap.${NC}"; exit 1; }
mkfs.ext4 ${DISK}3 -L root || { echo "${RED}Failed to format root partition.${NC}"; exit 1; }

# Display the filesystems created
echo "Filesystems created:"
blkid | grep ${DISK}

echo "${GREEN}Partitioning and formatting completed successfully.${NC}"