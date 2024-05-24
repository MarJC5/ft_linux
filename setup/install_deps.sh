#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}This script must be run as root${NC}" 1>&2
  exit 1
fi


echo -e "${YELLOW}Updating DNF cache...${NC}"
apt clean

echo -e "${YELLOW}Upgrading packages...${NC}"
apt upgrade -y

echo -e "${YELLOW}Installing necessary packages...${NC}"
apt install -y bzip2 git wget vim make autoconf libtool gcc g++ libncurses-dev flex bison bc cpio libelf-dev libssl-dev kmod grub-common gawk util-linux dwarves patch texinfo libisl-dev libgmp-dev libmpfr-dev libmpc-dev

# Ensure gawk is used as awk
if [ "$(readlink -f /usr/bin/awk)" != "/usr/bin/gawk" ]; then
    rm -f /usr/bin/awk
    ln -sf /usr/bin/gawk /usr/bin/awk
    echo -e "${GREEN}Symlink for awk set to gawk.${NC}"
fi

# Ensure sh points to bash
if [ "$(readlink -f /bin/sh)" != "/bin/bash" ]; then
    rm -f /bin/sh
    ln -sf /bin/bash /bin/sh
    echo -e "${GREEN}Symlink for sh set to bash.${NC}"
fi

# Ensure bison is used as yacc
if [ "$(readlink -f /usr/bin/yacc)" != "/usr/bin/bison" ]; then
    rm -f /usr/bin/yacc
    ln -sf /usr/bin/bison /usr/bin/yacc
    echo -e "${GREEN}Symlink for yacc set to bison.${NC}"
fi

echo -e "${GREEN}All dependencies installed and configurations set.${NC}"
