#!/bin/bash

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

# Mount the partitions
echo -e "${YELLOW}Mounting the partitions...${NC}"

# Load configuration
disk=$(parse_ini "partition" "disk" "$config_file")
sys_name=$(parse_ini "system" "name" "$config_file")

# Confirm loaded configurations
echo "Partition to be mounted: $disk"

# Define the disk to be partitioned
DISK="$disk"
SWAP="${DISK}2"
PARTITION="${DISK}3"
MOUNT_POINT="/mnt/${sys_name}"

# Create the mount point and mount
mkdir -pv $MOUNT_POINT
mount -v -t ext4 $PARTITION $MOUNT_POINT

# Check if the partition is already in fstab
if grep -qs "$MOUNT_POINT" /etc/fstab; then
  echo "$MOUNT_POINT already exists in /etc/fstab."
else
  # Add the partition to fstab
  echo "# Entry for LFS partition" >> /etc/fstab
  echo "$PARTITION $MOUNT_POINT ext4 defaults 1 1" >> /etc/fstab
  echo "Added $PARTITION to /etc/fstab for mounting at $MOUNT_POINT."
fi

# Optional: mount the partition immediately without reboot
if mount | grep -qs "$MOUNT_POINT"; then
  echo "$MOUNT_POINT is already mounted."
else
  mkdir -p $MOUNT_POINT
  mount $PARTITION $MOUNT_POINT
  echo "Mounted $PARTITION at $MOUNT_POINT."
fi

# Create the mount point for swap
/sbin/swapon -v "${SWAP}"
echo "Swap partition mounted at ${SWAP}."