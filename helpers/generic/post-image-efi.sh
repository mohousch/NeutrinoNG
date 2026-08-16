#!/bin/sh

set -e

BINARIES_DIR=$1

UUID=$(dumpe2fs "$BINARIES_DIR/rootfs.ext2" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p')
sed -i "s/UUID_TMP/$UUID/g" "$BINARIES_DIR/efi-part/EFI/BOOT/grub.cfg"
sed -i "s/UUID_TMP/$UUID/g" "$BINARIES_DIR/genimage-efi.cfg"

