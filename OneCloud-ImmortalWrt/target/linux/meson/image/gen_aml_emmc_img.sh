#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2017 OpenWrt.org

set -x
[ $# -eq 5 ] || {
    echo "SYNTAX: $0 <file> <bootfs image> <rootfs image> <bootfs size> <rootfs size>"
    exit 1
}

OUTPUT="$1"
BOOTFS="$2"
ROOTFS="$3"
BOOTFSSIZE="$4"
ROOTFSSIZE="$5"

head=4
sect=2048

set $(ptgen -o $OUTPUT -h $head -s $sect -l 4096 -t c -p ${BOOTFSSIZE}M -t 83 -p ${ROOTFSSIZE}M)

BOOTOFFSET="$(($1 / 512))"
BOOTSIZE="$(($2 / 512))"
ROOTFSOFFSET="$(($3 / 512))"
ROOTFSSIZE="$(($4 / 512))"

dd bs=512 if="$BOOTFS" of="$OUTPUT" seek="$BOOTOFFSET" conv=notrunc
dd bs=512 if="$ROOTFS" of="$OUTPUT" seek="$ROOTFSOFFSET" conv=notrunc

# Write U-Boot bootloader to sector 1 (after MBR)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/bootloader.bin" ]; then
    dd bs=512 if="$SCRIPT_DIR/bootloader.bin" of="$OUTPUT" seek=1 conv=notrunc
fi

# Write resource partition to sector 2049 (1MB offset, after bootloader region)
if [ -f "$SCRIPT_DIR/resource.bin" ]; then
    dd bs=512 if="$SCRIPT_DIR/resource.bin" of="$OUTPUT" seek=2049 conv=notrunc
fi
