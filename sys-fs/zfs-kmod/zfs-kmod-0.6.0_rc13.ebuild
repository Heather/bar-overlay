# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: bar/sys-fs/zfs-kmod/zfs-kmod-9999.ebuild,v 1.1 2013/02/07 13:55:31 -tclover Exp $

EAPI="5"

AT_M4DIR="config"
AUTOTOOLS_AUTORECONF="1"
AUTOTOOLS_IN_SOURCE_BUILD="1"

inherit bash-completion-r1 flag-o-matic git-2 linux-mod toolchain-funcs autotools-utils

DESCRIPTION="Linux ZFS kernel module for sys-fs/zfs"
HOMEPAGE="http://zfsonlinux.org/"
EGIT_REPO_URI="git://github.com/ryao/zfs.git"
EGIT_BRANCH="${EGIT_BRANCH:-gentoo}"
EGIT_COMMIT="${EGIT_COMMIT:-10b75496bb0cb7a7b8146c263164adc37f1d176a}"

LICENSE="BSD-2 CDDL MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64-fbsd ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~powerpc ~s390 ~sh ~sparc-fbsd ~sparc ~x86-fbsd ~x86"
IUSE="custom-cflags debug +rootfs"
RESTRICT="test"

DEPEND="
	=sys-kernel/spl-${PV}*
"

RDEPEND="${DEPEND}
	!sys-fs/zfs-fuse
"

pkg_setup() {
	CONFIG_CHECK="!DEBUG_LOCK_ALLOC
		BLK_DEV_LOOP
		EFI_PARTITION
		MODULES
		!PAX_KERNEXEC_PLUGIN_METHOD_OR
		ZLIB_DEFLATE
		ZLIB_INFLATE"
	use rootfs && \
		CONFIG_CHECK="${CONFIG_CHECK} BLK_DEV_INITRD
			DEVTMPFS"
	kernel_is ge 2 6 26 || die "Linux 2.6.26 or newer required"
	check_extra_config
}

src_prepare() {
	autotools-utils_src_prepare
}

src_configure() {
	use custom-cflags || strip-flags
	set_arch_to_kernel
	local myeconfargs=(
		--bindir="${EPREFIX}/bin"
		--sbindir="${EPREFIX}/sbin"
		--with-config=kernel
		--with-linux="${KV_DIR}"
		--with-linux-obj="${KV_OUT_DIR}"
		$(use_enable debug)
	)
	autotools-utils_src_configure
}

src_test() {
	if [ $UID -ne 0 ]
	then
		ewarn "Cannot run make check tests with FEATURES=userpriv."
		ewarn "Skipping make check tests."
	else
		autotools-utils_src_test
	fi
}

src_install() {
	autotools-utils_src_install
}

pkg_postinst() {
	linux-mod_pkg_postinst

	use x86 && ewarn "32-bit kernels are unsupported by ZFSOnLinux upstream. Do not file bug reports."

	eerror "This ebuild is from the zfs-overlay, which is meant strictly for"
	eerror "development. Everyone who has not spoken directly to ryao should NOT use"
	eerror "it. If you have not spoken to ryao, please delete the overlay and"
	eerror "rebuild ${P} from the main tree."

}
