#!/bin/sh

BINARIES_DIR=$1
HOST_DIR=$2

PARTUUID="$($HOST_DIR/bin/uuidgen)"

#sed -e "default" \
#	-e "s/%LINUXIMAGE%/zImage/g" \
#	-e "s/%PARTUUID%/$PARTUUID/g" \
#	"$BINARIES_DIR/extlinux.conf"

sed -i "s/%PARTUUID%/$PARTUUID/g" "$BINARIES_DIR/genimage.cfg"
