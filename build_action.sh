#!/usr/bin/env bash

VERSION=$(grep 'Kernel Configuration' < config | awk '{print $3}')

# add deb-src to sources.list
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
apt update
apt install -y wget xz-utils make gcc flex bison dpkg-dev bc rsync kmod cpio libssl-dev git libelf-dev initramfs-tools-core
apt build-dep -y linux

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

# download kernel source
wget http://www.kernel.org/pub/linux/kernel/v6.x/linux-"$VERSION".tar.xz
tar -xf linux-"$VERSION".tar.xz
cd linux-"$VERSION" || exit

# copy config file
cp ../config .config

# disable DEBUG_INFO to speedup build
scripts/config --disable DEBUG_INFO

# apply patches
# shellcheck source=src/util.sh
source ../patch.d/*.sh

# build deb packages
CPU_CORES=$(($(grep -c processor < /proc/cpuinfo)*2))
make  defconfig 
make -j"$CPU_CORES"
cd linux-"$VERSION"/arch/x86/boot/
mkinitramfs -o initrd.img-"$VERSION"

# move deb packages to artifact dir
cd ..
mkdir "artifact"
cp linux-"$VERSION"/arch/x86/boot/bzImage ./artifact/
cp linux-"$VERSION"/arch/x86/boot/initrd.img-"$VERSION" ./artifact/
