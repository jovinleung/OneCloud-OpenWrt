# SPDX-License-Identifier: GPL-2.0-or-later

REQUIRE_IMAGE_METADATA=1

platform_check_image() {
	return 0
}

platform_do_upgrade() {
	default_do_upgrade "$1"
}

platform_copy_config() {
	return 0
}
