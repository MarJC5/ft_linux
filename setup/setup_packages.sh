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

# Load configuration
disk=$(parse_ini "partition" "disk" "$config_file")
sys_name=$(parse_ini "system" "name" "$config_file")
LFS="/mnt/${sys_name}"

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

# Download the packages from the wget-list
wget --input-file="${BASE_DIR}/../config/wget-list-sysv" --continue --directory-prefix=$LFS/sources

# Verify the packages
pushd $LFS/sources
  md5sum -c "${BASE_DIR}/../config/md5sums"
popd

# Echo the success message
echo -e "${GREEN}Packages downloaded successfully${NC}"