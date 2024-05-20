#!/bin/bash

# Base directory for the script relative to where it's executed from
BASE_DIR=$(dirname "$(realpath "$0")")

source "${BASE_DIR}/../utils/extract.sh"

# Extract the packages
extract_package "binutils-2.35.tar.xz" "sources"

mkdir -v build

cd build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-default-hash-style=gnu

make

make install