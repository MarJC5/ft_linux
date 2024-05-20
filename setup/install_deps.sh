#!/bin/bash

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

echo "Cleaning old APT cache files..."
apt-get clean

echo "Updating APT cache..."
apt-get update -m

echo "Installing necessary packages..."
apt-get install -y bzip2 git wget vim make gcc g++ libncurses-dev flex bison bc cpio libelf-dev libssl-dev kmod grub2-common gawk texinfo fdisk dwarves

# Ensuring gawk is used as awk
if [ ! -L /usr/bin/awk ]; then
    rm -f /usr/bin/awk
fi
ln -sf /usr/bin/gawk /usr/bin/awk

# Making sure sh points to bash
if [ ! -L /bin/sh ]; then
    rm -f /bin/sh
fi
ln -sf /bin/bash /bin/sh

echo "All dependencies installed and configurations set."
