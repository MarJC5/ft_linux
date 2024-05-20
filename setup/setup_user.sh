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
sys_name=$(parse_ini "system" "name" "$config_file")
LFS="/mnt/${sys_name}"

# Create the group for the new user
if grep -q $sys_name /etc/group; then
    echo -e "${RED}Group $sys_name already exists.${NC}"
else
    groupadd $sys_name || { echo "${RED}Failed to add group $sys_name.${NC}"; exit 1; }
fi

# Check if the user already exists
if id "$sys_name" &>/dev/null; then
    echo -e "${RED}User $sys_name already exists.${NC}"
else 
    useradd -s /bin/bash -g $sys_name -m $sys_name || { echo "${RED}Failed to add user $sys_name.${NC}"; exit 1; }
    passwd $sys_name || { echo "${RED}Failed to set password for user $sys_name.${NC}"; exit 1; }
    echo -e "${GREEN}User $sys_name created successfully.${NC}"
fi

# Grant lfs full access to all the directories under $LFS by making lfs the owner
chown -v $sys_name $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v $sys_name $LFS/lib64 ;;
esac

# Setup bash profile for the new user
echo "Setting up bash profile for $sys_name"

cat > /home/$sys_name/.bash_profile << EOF
exec env -i HOME=\$HOME TERM=\$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > /home/$sys_name/.bashrc << EOF
set +h
umask 022
LFS=/mnt/$sys_name
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:\$PATH; fi
PATH=\$LFS/tools/bin:\$PATH
CONFIG_SITE=\$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

cat >> /home/$sys_name/.bashrc << EOF
export MAKEFLAGS=-j$(nproc)
EOF

[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

echo "Source the bash profile"

source /home/$sys_name/.bash_profile