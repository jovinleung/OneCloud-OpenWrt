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
	kmod-usb-storage \
	kmod-usb-storage-uas \
	kmod-macvlan \
	losetup \
	mkf2fs \
	automount \
	parted \
	partx-utils \
	resize2fs \
	zram-swap \
	liblz4 \
	ethtool \
	usbutils \
	iperf3 \
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
	wireguard-tools \
	kmod-nft-tproxy \
	kmod-nft-socket \
	kmod-inet-diag \
	nftables-json \
	conntrack \
	ip-full \
	irqbalance \
	luci-theme-argon \
	luci-app-ttyd \
	luci-app-diskman \
	luci-app-hd-idle \
	luci-app-nikki

KERNELNAME:=Image dtbs

$(eval $(call BuildTarget))
