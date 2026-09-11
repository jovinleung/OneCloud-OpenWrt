# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2013 OpenWrt.org

include $(TOPDIR)/rules.mk

ARCH:=arm
BOARD:=meson
BOARDNAME:=Amlogic Meson family
FEATURES:=boot-part ext4 fpu legacy-sdcard squashfs usbgadget
SUBTARGETS:=meson8b

KERNEL_PATCHVER:=6.18

define Target/Description
	Build firmware image for Amlogic Meson SoC devices.
	Currently produces Amlogic Burn Image.
endef

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += \
	e2fsprogs \
	kmod-usb-hid \
	kmod-usb-net \
	kmod-usb-net-rtl8152 \
	kmod-usb-net-asix-ax88179 \
	kmod-usb-net-smsc95xx \
	kmod-usb-net-cdc-ether \
	losetup \
	mkf2fs \
	automount \
	parted \
	partx-utils \
	resize2fs \
	zram-swap \
	ethtool \
	htop \
	curl \
	wget \
	ca-certificates \
	ca-bundle \
	kmod-sched-cake \
	kmod-sched-core \
	kmod-ifb \
	kmod-nf-conntrack-netlink \
	kmod-nft-offload \
	kmod-tun \
	kmod-nft-tproxy \
	kmod-nft-socket \
	kmod-inet-diag \
	nftables-json \
	conntrack \
	ip-full \
	irqbalance

KERNELNAME:=Image dtbs

$(eval $(call BuildTarget))
