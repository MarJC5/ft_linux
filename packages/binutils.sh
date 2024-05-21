#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure the script is run in bash for compatibility with bash-specific features
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

# Base directory for the script relative to where it's executed from
source "/media/share/utils/resolver.sh"

# Load the utilities script
source "${utils_path}/extract.sh"

package="binutils-2.42"
ext="tar.xz"

# Extract the packages
extract_package "${package}.${ext}" "sources"

# Change to the extracted directory
cd "${LFS}/sources/${package}" || exit 1

# Create a build directory
mkdir -v "${LFS}/sources/${package}/build"
cd "${LFS}/sources/${package}/build" || exit 1

# Configure the build
"${LFS}/sources/${package}/configure" --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-default-hash-style=gnu || exit 1

echo -e "Compiling the package ${YELLOW}${package}${NC}"
make

echo -e "Installing the package ${YELLOW}${package}${NC}"
make install

echo -e "Package ${GREEN}${package}${NC} installed successfully"
