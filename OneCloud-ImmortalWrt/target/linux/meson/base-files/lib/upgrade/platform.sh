# SPDX-License-Identifier: GPL-2.0-or-later

REQUIRE_IMAGE_METADATA=1

platform_check_image() {
	local magic

	# Verify MBR signature (0x55AA) for eMMC disk image
	magic=$(get_image "$1" | dd bs=1 count=2 skip=510 2>/dev/null | hexdump -v -n 2 -e '1/1 "%02x"')
	[ "$magic" = "55aa" ] && return 0

	# Also accept standard sysupgrade tarball
	magic=$(get_image "$1" | tar -tzf - 2>/dev/null | head -1)
	[ -n "$magic" ] && return 0

	echo "Invalid image format. Expected eMMC disk image (MBR) or sysupgrade tarball."
	return 1
}

platform_do_upgrade() {
	default_do_upgrade "$1"
}

platform_copy_config() {
	local partdev

	# Mount rootfs partition and copy configuration
	if export_partdevice partdev 1; then
		mkdir -p /mnt
		mount -o rw,noatime "/dev/$partdev" /mnt 2>/dev/null
		if [ -f /mnt/etc/openwrt_release ] || [ -f /mnt/etc/config/system ]; then
			cp -af /tmp/sysupgrade.conf /mnt/ 2>/dev/null
			cp -af /etc/config /mnt/etc/ 2>/dev/null
			sync
		fi
		umount /mnt 2>/dev/null
	fi
	return 0
}
