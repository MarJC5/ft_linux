# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure the script is run in bash for compatibility with bash-specific features
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

# Assuming $LFS is set to the root of your LFS system
# Example: export LFS=/mnt/lfs

source "/media/share/utils/resolver.sh"

# Load the utilities script
source "${utils_path}/extract.sh"

package="gcc-13.2.0"
deps=("gmp-6.3.0.tar.xz" "mpfr-4.2.1.tar.xz" "mpc-1.3.1.tar.gz")
ext="tar.xz"

# Extract the packages
extract_package "${package}.${ext}" "sources"

# Change to the extracted directory
cd "${LFS}/usr/src/sources/${package}" || exit 1

# Extract the dependencies
for dep in "${deps[@]}"; do
    extract_package "$dep" "sources/${package}"

    # Rename the extracted directory
    dep_dir=$(echo "$dep" | sed -e 's/.tar.*//')
    dep_dir_name=$(echo "$dep_dir" | sed -e 's/-[0-9].*//')
    mv "${LFS}/usr/src/sources/${package}/$dep_dir" "${LFS}/usr/src/sources/${package}/$dep_dir_name"
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

# Create a build directory
mkdir -v "${LFS}/usr/src/sources/${package}/build"
cd "${LFS}/usr/src/sources/${package}/build" || exit 1
LFS_TGT=$(uname -m)-lfs-linux-gnu

# Correct environmental variables setup
LD_LIBRARY_PATH=$LFS/tools/lib
LIBRARY_PATH=$LFS/tools/lib
C_INCLUDE_PATH=$LFS/tools/include
CPLUS_INCLUDE_PATH=$LFS/tools/include

# Configure the build
"${LFS}/usr/src/sources/${package}/configure" \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.39 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

echo -e "Compiling the package ${YELLOW}${package}${NC}"
make -j$(nproc)

echo -e "Installing the package ${YELLOW}${package}${NC}"
make install

echo -e "Package ${GREEN}${package}${NC} installed successfully"

# Navigate to the correct directory and create the limits.h header
cd "${LFS}/usr/src/sources/${package}"

echo -e "Creating a full version of the internal header ${YELLOW}limits.h${NC}"

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

echo -e "${GREEN}limits.h${NC} created successfully in $(dirname $(${LFS_TGT}-gcc -print-libgcc-file-name))/include"
