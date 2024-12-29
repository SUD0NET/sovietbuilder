#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

###########
# Minimum filesystem setup
###########

# Ensure the SOV_DIR variable is set
if [[ -z "$SOV_DIR" ]]; then
  echo "Error: SOV_DIR is not set."
  exit 1
fi

# Create the base directories
BASE_DIRS=("mnt" "opt")
SUBDIRS=(
  "efi/loader"
  "efi/EFI/BOOT"
  "efi/EFI/Linux"
  "efi/EFI/systemd"
  "etc/kernel"
  "etc/pam.d"
  "etc/systemd/network"
  "etc/systemd/system"
  "etc/systemd/system-preset"
  "etc/sysupdate.d"
  "etc/udev/rules.d"
  "usr/bin"
  "usr/etc"
  "usr/include"
  "usr/lib"
  "usr/libexec"
  "usr/local"
  "usr/share"
  "usr/src"
  "var/cache"
  "var/lib/confexts"
  "var/lib/extensions"
  "var/local"
  "var/log"
  "var/mail"
  "var/opt"
  "var/spool"
  "var/tmp"
)

# Create directories
mkdir -pv "$SOV_DIR"
for dir in "${BASE_DIRS[@]}"; do
  mkdir -pv "$SOV_DIR/$dir"
done

for dir in "${SUBDIRS[@]}"; do
  mkdir -pv "$SOV_DIR/$dir"
done

# Create symbolic links
ln -sv usr/bin "$SOV_DIR/bin"
ln -sv usr/bin "$SOV_DIR/sbin"
ln -sv usr/lib "$SOV_DIR/lib"
ln -sv usr/lib "$SOV_DIR/lib64"
ln -sv lib "$SOV_DIR/usr/lib64"
ln -sv bin "$SOV_DIR/usr/sbin"

# Indicate completion
touch "$SOV_DIR/01-complete"

echo "Filesystem setup complete!"
