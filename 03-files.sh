#!/bin/bash

## Exit immediately if something breaks
set -e

############
# This script copies pre-made files to the build.
# Some sed lines will customize the files to this specific build.
############

copy_files() {
  # A helper function to copy files with verbosity
  cp -v "$@"
}

create_symlinks() {
  # A helper function to create symlinks
  ln -sf "$@"
}

##########
# Systemd
##########
copy_files $SOV_FILES/10-dhcp.network $SOV_FILES/20-wifi.network $SOV_DIR/etc/systemd/network/
copy_files $SOV_FILES/networkd.conf $SOV_DIR/etc/systemd/
rm -vf $SOV_DIR/etc/resolv.conf
copy_files $SOV_FILES/hosts $SOV_DIR/etc/
copy_files $SOV_FILES/10-usr.conf $SOV_FILES/30-efi.conf $SOV_DIR/etc/sysupdate.d/
copy_files $SOV_FILES/soviet.preset $SOV_DIR/etc/systemd/system-preset/

##########
# UKIs and Boot
##########
copy_files $SOV_FILES/cmdline $SOV_FILES/cmdline-installer $SOV_DIR/etc/kernel/
copy_files $SOV_FILES/loader.conf $SOV_DIR/efi/loader/
echo type2 >> $SOV_DIR/efi/loader/entries.srel
copy_files $SOV_FILES/logo-soviet-boot.bmp $SOV_DIR/efi

##########
# ZRAM (Commented out for now)
##########
# copy_files $SOV_FILES/zramswap.conf $SOV_DIR/etc/
# copy_files $SOV_FILES/zramctl $SOV_DIR/etc/systemd/system/
# copy_files $SOV_FILES/zramswap.service $SOV_DIR/usr/lib/systemd/system/zramswap.service

##########
# LVM
##########
copy_files $SOV_FILES/11-dm-initramfs.rules $SOV_DIR/etc/udev/rules.d/

##########
# /etc Files
##########
# Commented out as unsure about necessity
# copy_files $SOV_FILES/fstab-install $SOV_DIR/etc/
copy_files $SOV_FILES/profile $SOV_DIR/etc/
copy_files $SOV_FILES/shells $SOV_DIR/etc/
copy_files $SOV_FILES/inputrc $SOV_DIR/etc/
copy_files $SOV_FILES/locale.conf $SOV_DIR/etc/

# PAM
copy_files $SOV_FILES/system-{account,auth,password,session,user} $SOV_DIR/etc/pam.d/
copy_files $SOV_FILES/{other,login,systemd-user} $SOV_DIR/etc/pam.d/

# P11-kit fixes
copy_files $SOV_FILES/trust-extract-compat $SOV_DIR/usr/libexec/p11-kit/trust-extract-compat

# Log files
# touch /var/log/{btmp,lastlog,faillog,wtmp}
# chgrp -v utmp /var/log/lastlog
# chmod -v 664 /var/log/lastlog
# chmod -v 600 /var/log/btmp

# Update os-release
copy_files $SOV_FILES/os-release $SOV_DIR/usr/lib/
sed -i "s/xxxxxx/$BUILD/" $SOV_DIR/usr/lib/os-release
(
  cd $SOV_DIR/etc
  rm -f os-release localtime
  create_symlinks ../usr/lib/os-release os-release
  create_symlinks ../usr/share/zoneinfo/UTC localtime
  rm -vf lsb-release
)

# Installer script
copy_files $SOV_FILES/soviet-install.sh $SOV_DIR/etc/
copy_files $SOV_FILES/soviet-final.sh $SOV_DIR/etc/
chmod +x $SOV_DIR/etc/soviet-{install,final}.sh

# CCCP
copy_files $SOV_FILES/cccp.conf $SOV_DIR/etc/

# Stage 4 preparation
copy_files 04-config.sh $SOV_DIR/
chmod +x $SOV_DIR/04-config.sh
copy_files build $SOV_DIR/

# Set root password
echo 'root:sovietlinux' | chpasswd -P $SOV_DIR

# Completion
touch 03-complete
