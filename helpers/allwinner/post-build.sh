#!/bin/sh

BINARIES_DIR=$1

PARTUUID="$(uuidgen)"

sed -i "s/%PARTUUID%/$PARTUUID/g" "$BINARIES_DIR/extlinux.conf"
sed -i "s/%PARTUUID%/$PARTUUID/g" "$BINARIES_DIR/genimage.cfg"
