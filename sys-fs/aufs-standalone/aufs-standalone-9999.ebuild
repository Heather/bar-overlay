# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: sys-fs/aufs-standalone/aufs-standalone-9999.ebuild v1.12 2015/03/09 23:23:44 -tclover Exp $

EAPI=5

inherit flag-o-matic linux-mod toolchain-funcs git-2

DESCRIPTION="An entirely re-designed and re-implemented Unionfs"
HOMEPAGE="http://aufs.sourceforge.net/"
EGIT_REPO_URI="git://git.code.sf.net/p/aufs/aufs3-standalone.git"
EGIT_NONBARE=yes

DEPEND="dev-util/patchutils"
RDEPEND="!sys-fs/aufs2 !sys-fs/aufs3 =sys-fs/${P/standalone/util}"

LICENSE="GPL-2"
IUSE="debug doc fhsm fuse pax_kernel hfs inotify +kernel-patch nfs ramfs +xattr"
SLOT="0/${PV}"

KV_SUPPORT=(
	4.0
	3.1{0,1,2,3,4,5,6,7,8,9}
)

MODULE_NAMES="aufs(misc:${S})"

pkg_setup()
{
	CONFIG_CHECK="!AUFS_FS"
	use inotify && CONFIG_CHECK+=" ~FSNOTIFY"
	use nfs && CONFIG_CHECK+=" ~EXPORTFS"
	use fuse && CONFIG_CHECK+=" ~FUSE_FS"
	use hfs && CONFIG_CHECK+=" ~HFSPLUS_FS"
	use pax_kernel && CONFIG_CHECK+=" PAX"
 
	# this is needed so merging a binpkg aufs-standalone is possible
	# w/out a kernel unpacked on the system
	[[ -n "$PKG_SETUP_HAS_BEEN_RAN" ]] && return

	get_version

	local PATCHES branch=${KV_MINOR} patch n=/dev/null
	[[ ${KV_MAJOR}  != ${KV_SUPPORT[1]%.*} ]] && die "kernel is not supported"
	[[ ${KV_MINOR} -lt ${KV_SUPPORT[1]#*.} ]] && die "kernel is too old"
	[[ ${KV_MAJOR} -gt ${KV_SUPPORT[0]%.*} ]] &&
	[[ ${KV_MINOR} -gt ${KV_SUPPORT[0]#*.} ]] && die "kernel is too new"
	case ${KV_MINOR} in
		(10) branch+=.x;;
		(12) (( ${KV_MAJOR} >= 31 )) && branch+=.31+ ||
			die "Unsupported minor version/kernel";;
		(14) (( ${KV_MAJOR} >= 21 )) && branch+=.21+ ||
			die "Unsupported minor version/kernel";;
		(${KV_SUPPORT[0]#*.}) branch=x-rcN;;
	esac
	export EGIT_BRANCH=aufs${KV_MAJOR}.${branch}
	export EGIT_PROJECT=${PN/-/${KV_MAJOR}-}.git

	PATCHES=( "${FILESDIR}"/aufs-{base,mmap,standalone}-${branch}.patch )

	linux-mod_pkg_setup
	if ! ( pushd "${KV_DIR}"
		for patch in "${PATCHES[@]}"; do
			patch -p1 --dry-run --force -R "${patch}" >${n} || return 1
		done ); then
		if use kernel-patch; then
			ewarn "Patching your kernel..."
			for patch in "${PATCHES[@]}"; do
				patch --no-backup-if-mismatch --force -p1 -R -d "${patch}" >${n}
			done
			popd
			epatch "${PATCHES[@]}"
			ewarn "You need to compile your kernel with the applied patch"
			ewarn "to be able to load and use the aufs kernel module"
		else
			eerror "Apply patches to your kernel to compile and run the aufs${KV_MAJOR} module;"
			eerror "Either enable the kernel-patch USEflag to do it with this ebuild, or apply:"
			eerror "patch -p1 \"${PATCHES[0]}\";"
			eerror "patch -p1 \"${PATCHES[0]}\";"
			eerror "patch -p1 \"${PATCHES[0]}\";"
			die "missing kernel patch, please apply it first"
		fi
	fi
	export PKG_SETUP_HAS_BEEN_RAN=1
}

src_prepare()
{
	if use pax_kernel; then
		kernel_is ge 3.11 && epatch "${FILESDIR}"/pax-3.11.patch ||
		epatch "${FILESDIR}"/pax-3.patch
	fi

	sed -e 's:aufs.ko usr/include/linux/aufs_type.h:aufs.ko:g' \
		-e "s:/lib/modules/${KV_FULL}/build:${KV_OUT_DIR}:g" \
	 	-i Makefile || die

	epatch "${FILESDIR}"/aufs_type.h.patch
}

src_configure()
{
	local -a config=(
		${EXTRA_AUFS_CONF}
		$(use debug && echo DEBUG MAGIC_SYSRQ)
		$(use fhsm && echo FHSM)
		$(use fuse && echo BR_FUSE POLL)
		$(use hfs && echo BR_HFSPLUS)
		$(use inotify && echo HNOTIFY HFSNOTIFY)
		$(use nfs && echo EXPORT)
		$(use ramfs && echo BR_RAMFS)
		$(use xattr && echo XATTR)
	)
	case "${ARCH}" in
		(amd64|ppc64) use nfs && config+=INO_T_64;;
	esac
	for option in ${config[@]} RDU SBILIST; do
		grep -q "^CONFIG_AUFS_${option} =" config.mk ||
			die "CONFIG_AUFS_${option} is not a valid config option"
		sed -e "/^CONFIG_AUFS_${option}/s:=:= y:g" -i config.mk || die
	done
}

src_compile()
{
	local ARCH=x86

	emake \
		CC=$(tc-getCC) \
		LD=$(tc-getLD) \
		LDFLAGS="$(raw-ldflags)" \
		ARCH=$(tc-arch-kernel) \
		CONFIG_AUFS_FS=m \
		KDIR="${KV_OUT_DIR}"
}

src_install()
{
	linux-mod_src_install

	insinto /usr/include/linux
	doins include/linux/aufs_type.h

	insinto /usr/share/doc/${PF}
	use doc && doins -r Documentation/*
}
