# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: bar/sys-kernel/spl/spl-9999.ebuild,v 1.13 2013/02/07 13:55:48 -tclover Exp $

EAPI="5"

AT_M4DIR="config"
AUTOTOOLS_AUTORECONF="1"
AUTOTOOLS_IN_SOURCE_BUILD="1"

inherit eutils flag-o-matic git-2 linux-mod autotools-utils

DESCRIPTION="The Solaris Porting Layer is a Linux kernel module which provides many of the Solaris kernel APIs"
HOMEPAGE="http://zfsonlinux.org/"
EGIT_REPO_URI="git://github.com/ryao/spl.git"
EGIT_BRANCH="${EGIT_BRANCH:-gentoo}"
EGIT_COMMIT="${EGIT_COMMIT:-02d25048d293a44001de6967872476f7d78e2397}"

LICENSE="|| ( GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS="~alpha ~amd64-fbsd ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~powerpc ~s390 ~sh ~sparc-fbsd ~sparc ~x86-fbsd ~x86"
IUSE="custom-cflags debug"

RDEPEND="!sys-devel/spl"

pkg_setup() {
	CONFIG_CHECK="
		!DEBUG_LOCK_ALLOC
		MODULES
		KALLSYMS
		ZLIB_DEFLATE
		ZLIB_INFLATE
	"
	kernel_is ge 2 6 26 || die "Linux 2.6.26 or newer required"
	check_extra_config
}

src_prepare() {
	# Workaround for hard coded path
	sed -i "s|/sbin/lsmod|/bin/lsmod|" scripts/check.sh || die

	# Apply user patches
	epatch_user

	autotools-utils_src_prepare
}

src_configure() {
	use custom-cflags || strip-flags
	set_arch_to_kernel
	local myeconfargs=(
		--bindir="${EPREFIX}/bin"
		--sbindir="${EPREFIX}/sbin"
		--with-config=all
		--with-linux="${KV_DIR}"
		--with-linux-obj="${KV_OUT_DIR}"
		$(use_enable debug)
	)
	autotools-utils_src_configure
}

src_test() {
	if [[ ! -e /proc/modules ]]
	then
		die  "Missing /proc/modules"
	elif [[ $UID -ne 0 ]]
	then
		ewarn "Cannot run make check tests with FEATURES=userpriv."
		ewarn "Skipping make check tests."
	elif grep -q '^spl ' /proc/modules
	then
		ewarn "Cannot run make check tests with module spl loaded."
		ewarn "Skipping make check tests."
	else
		autotools-utils_src_test
	fi
}

pkg_postinst() {
	eerror "This ebuild is from the zfs-overlay, which is meant strictly for"
	eerror "development. Everyone who has not spoken directly to ryao should NOT use"
	eerror "it. If you have not spoken to ryao, please delete the overlay and"
	eerror "rebuild ${P} from the main tree."
}
