#!/bin/bash

# Exit immediately if something breaks
set -euo pipefail

log() {
  echo "[INFO] $1"
}

error_exit() {
  echo "[ERROR] $1"
  exit 1
}

cleanup() {
  log "Cleaning up temporary directories and unmounting loop devices..."
  umount loop-efi 2>/dev/null || true
  umount loop-install 2>/dev/null || true
  losetup -d "$LOOP" 2>/dev/null || true
  rm -rf loop-efi loop-install
}

trap cleanup EXIT

# Ensure required variables are set
: "${SOV_BUILD:?Environment variable SOV_BUILD is not set!}"
: "${SOV_DIR:?Environment variable SOV_DIR is not set!}"
: "${BUILD:?Environment variable BUILD is not set!}"

# Create the SOV_BUILD directory
mkdir -p "$SOV_BUILD"

###########
# Clean Up Build Directory
###########

log "Cleaning up build directory..."
rm -v "$SOV_DIR"/efi/EFI/Linux/sovietlinux-* || true
mv "$SOV_DIR"/efi/sovietlinux-* "$SOV_BUILD"

rm -rv "$SOV_DIR"/{04-config.sh,build,04-complete} || true
rm -rfv "$SOV_DIR"/root/.bash_history "$SOV_DIR"/usr/share/doc/* "$SOV_DIR"/tmp/* "$SOV_DIR"/var/log/journal/[0-9]* || true
echo "uninitialized" > "$SOV_DIR"/etc/machine-id

###########
# Create Deliverables
###########

log "Creating squashfs image..."
cd "$SOV_DIR"
mksquashfs ./* "$SOV_BUILD/squashfs.img" -b 1M -noappend

log "Generating tar files..."
tar -cf "$SOV_BUILD/sovietlinux-$BUILD-core.tar" ./*
tar -cf "$SOV_BUILD/usr-$BUILD.tar" ./usr/*

log "Compressing tar files with multi-threading..."
xz -T0 "$SOV_BUILD/sovietlinux-$BUILD-core.tar"
xz -T0 "$SOV_BUILD/usr-$BUILD.tar"

###########
# Create Installer Image
###########

log "Calculating installer image size..."
SQUASH_SIZE=$(du -b "$SOV_BUILD/squashfs.img" | cut -f1 | numfmt --to-unit=M)
EFI_SIZE=$(du -b "$SOV_BUILD/sovietlinux-$BUILD-installation.efi" | cut -f1 | numfmt --to-unit=M)
EFI_20=$((EFI_SIZE + 20))
COMBINED_SIZE=$((SQUASH_SIZE + EFI_20))
FIVE_PERCENT=$((COMBINED_SIZE / 20))
IMG_SIZE=$((COMBINED_SIZE + FIVE_PERCENT))

log "Creating installation image of size ${IMG_SIZE}M..."
truncate -s "${IMG_SIZE}M" "$SOV_BUILD/sovietlinux-$BUILD-installation.img"
LOOP=$(losetup -fP "$SOV_BUILD/sovietlinux-$BUILD-installation.img" --show)

log "Creating partitions..."
sgdisk -n 1:0:+"${EFI_20}"M -c 1:"SOV-EFI" -t 1:ef00 -n 2:0:0 -c 2:"soviet-install" -t 2:8304 "$LOOP"
mkfs.vfat -F 32 -n SOV-EFI "${LOOP}p1"
mkfs.ext4 -m 2 -L soviet-install "${LOOP}p2"

log "Mounting partitions..."
mkdir -p loop-efi loop-install
mount -o loop "${LOOP}p1" loop-efi/
mount -o loop "${LOOP}p2" loop-install/

log "Copying files to partitions..."
cp -Rv "$SOV_DIR"/efi/* loop-efi/
rm -v loop-efi/EFI/Linux/sovietlinux*.efi
cp -v "$SOV_BUILD/sovietlinux-$BUILD-installation.efi" loop-efi/EFI/Linux/
mkdir -p loop-install/LiveOS
cp -v "$SOV_BUILD/squashfs.img" loop-install/LiveOS/squashfs.img

log "Unmounting and finalizing image..."
umount loop-efi
umount loop-install
losetup -d "$LOOP"

###########
# Final Steps
###########

log "Marking build as complete..."
cd "$SOV_DIR"
touch 05-complete

log "All tasks completed successfully!"
