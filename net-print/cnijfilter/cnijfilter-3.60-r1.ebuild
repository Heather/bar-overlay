# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: bar-overlay/net-print/cnijfilter/cnijfilter-3.60-r1.ebuild,v 1.5 2012/05/30 10:27:11 -tclover Exp $

EAPI=4

inherit eutils autotools rpm flag-o-matic

DESCRIPTION="Canon InkJet Printer Driver for Linux (Pixus/Pixma-Series)."
HOMEPAGE="http://support-sg.canon-asia.com/contents/SG/EN/0100392802.html"
RESTRICT="nomirror confcache"

SRC_URI="http://gdlp01.c-wss.com/gds/8/0100003928/01/${PN}-source-${PV}-1.tar.gz"
LICENSE="UNKNOWN" # GPL-2 source and proprietary binaries

WANT_AUTOCONF=2.59
WANT_AUTOMAKE=1.9.6

SLOT="3.60"
KEYWORDS="~x86 ~amd64"
IUSE="+debug servicetools gtk net usb mg2100 mg3100 mg4100 mg5300 mg6200 mg8200 ip4900 e500"
REQUIRED_USE="servicetools? ( gtk )
	|| ( net usb )
"
DEPEND="gtk? ( >=x11-libs/gtk+-2.6.0:2 )
	app-text/ghostscript-gpl
	>=net-print/cups-1.1.14
	sys-libs/glibc
	>=dev-libs/popt-1.6
	>=media-libs/tiff-3.4
	>=media-libs/libpng-1.0.9
	servicetools? ( 
		>=gnome-base/libglade-0.6
		>=dev-libs/libxml2-2.7.3-r2
	)
	>=sys-devel/gettext-0.10.38
	dev-util/intltool
"

S="${WORKDIR}"/${PN}-source-${PV}-1

_pruse=("mg2100" "mg3100" "mg4100" "mg5300" "mg6200" "mg8200" "ip4900" "e500")
_prname=(${_pruse[@]})
_prid=("386" "387" "388" "389" "390" "391" "392" "393")
_prcomp=("mg2100series" "mg3100series" "mg4100series" "mg5300series" "mg6200series" "mg8200series" "ip400series" "e500series")
_max=$((${#_pruse[@]}-1))

pkg_setup() {
	if [ -z "$LINGUAS" ]; then
		ewarn "You didn't specify 'LINGUAS' in your make.conf. Assuming"
		ewarn "english localisation, i.e. 'LINGUAS=\"en\"'."
		LINGUAS="en"
	fi

	[ -n "$(uname -m | grep 64)" ] && _arch=64 || _arch=32
	_src=cngpij
	_src=cnijfilter
	use usb && _src+=" backend"
	use net && _src+=" backendnet"
	use gtk && _src+=" cngpijmon"
	use gtk && use net && _src+=" cngpijmon/cnijnpr"
	use servicetools && _src+=" printui lgmon"
	
	_autochoose="true"
	for i in $(seq 0 ${_max}); do
		einfo " ${_pruse[$i]}\t${_prcomp[$i]}"
		if (use ${_pruse[$i]}); then
			_autochoose="false"
		fi
	done
	einfo ""
	if (${_autochoose}); then
		ewarn "You didn't specify any driver model (set it's USE-flag)."
		einfo ""
		einfo "As example:\tbasic MG2100 support without maintenance tools"
		einfo "\t\t -> USE=\"mg2100\""
		einfo ""
		einfo "Press Ctrl+C to abort"
		echo
		ebeep

		n=10
		while [[ $n -gt 0 ]]; do
			echo -en "  Waiting $n seconds...\r"
			sleep 1
			(( n-- ))
		done
	fi
}

src_prepare() {
	epatch ${FILESDIR}/${P%*-r}-4-cups_ppd.patch || die
	epatch ${FILESDIR}/${PN}-${PV/60/50}-1-ldl.patch || die
	epatch ${FILESDIR}/${P%*-r}-4-libpng15.patch || die

	for dir in libs ${_src} pstocanonij; do
		pushd ${dir} || die
		[ -d po ] && intltoolize --copy --force --automake
		autotools_run_tool libtoolize --copy --force --automake
		eaclocal
		eautoheader
		eautomake --gnu
		eautoreconf
		pushd
	done

	for i in $(seq 0 ${_max}); do
		if use ${_pruse[$i]} || ${_autochoose}; then
			_pr=${_prname[$i]} _prid=${_prid[$i]}
			src_prepare_pr
		fi
	done
}

src_configure() {
	for dir in libs ${_src} pstocanonij; do
		pushd ${dir} || die
		econf 
		pushd
	done

	for i in $(seq 0 ${_max}); do
		if use ${_pruse[$i]} || ${_autochoose}; then
			_pr=${_prname[$i]} _prid=${_prid[$i]}
			src_configure_pr
		fi
	done
}

src_compile() {
	for dir in libs ${_src} pstocanonij; do
		pushd ${dir} || die
		emake
		pushd
	done

	for i in $(seq 0 ${_max}); do
		if use ${_pruse[$i]} || ${_autochoose}; then
			_pr=${_prname[$i]} _prid=${_prid[$i]}
			src_compile_pr
		fi
	done
}

src_install() {
	local _libdir=/usr/$(get_libdir) _ppddir=/usr/share/cups/model
	local _cupsdir=/usr/libexec/cups/filter _cupsodir=/usr/lib/cups/backend
	mkdir -p "${D}${_libdir}"/cups/filter || die
	mkdir -p "${D}${_libdir}"/cnijlib || die
	mkdir -p "${D}${_cupsdir}" || die
	mkdir -p "${D}${_ppddir}"
	for dir in libs ${_src} pstocanonij; do
		pushd ${dir} || die
		emake DESTDIR="${D}" install || die
		pushd
	done

	for i in $(seq 0 ${_max}); do
		if use ${_pruse[$i]} || ${_autochoose}; then
			_pr=${_prname[$i]} _prid=${_prid[$i]}
			src_install_pr
		fi
	done

	mv "${D}${_libdir}"/cups/filter/pstocanonij \
		"${D}${_cupsdir}/pstocanonij${SLOT}" && rm -fr "${D}${_libdir}"/cups || die
	mv "${D}"/usr/bin/cngpij{,${SLOT}} || die
	use usb && mv "${D}${_cupsodir}"/cnijusb "${D}${_cupsdir}"/cnijusb${SLOT} || die
	if use net; then
		mv "${D}"/usr/bin/cnijnetprn{,${SLOT}} || die
		mv "${D}${_cupsodir}"/cnijnet "${D}${_cupsdir}"/cnijnet${SLOT} || die
		use gtk && cp -a com/libs_bin${_arch}/* "${D}${_libdir}" || die
	fi
	rm -fr "${D}"/usr/lib/cups/backend
}

pkg_postinst() {
	einfo ""
	einfo "For installing a printer:"
	einfo " * Restart CUPS: /etc/init.d/cupsd restart"
	einfo " * Go to http://127.0.0.1:631/"
	einfo "   -> Printers -> Add Printer"
	einfo ""
	einfo "If you experience any problems, please visit:"
	einfo " http://forums.gentoo.org/viewtopic-p-3217721.html"
	einfo "https://bugs.gentoo.org/show_bug.cgi?id=258244"
}

src_prepare_pr() {
	mkdir ${_pr}
	for dir in ${_prid} ${_prsrc}; do
		cp -a ${dir} ${_pr} || die
	done

	for dir in ${_prsrc}; do
		cd ${dir} || die
		[ -d po ] && intltoolize --copy --force --automake
		autotools_run_tool libtoolize --copy --force --automake
		eaclocal
		eautoheader
		eautomake --gnu
		eautoreconf
		cd ..
	done
}

src_configure_pr() {
	for dir in ${_prsrc}; do
		cd ${dir} || die
		econf --program-suffix=${_pr}
		cd ..
	done
}

src_compile_pr() {
	for dir in ${_prsrc}; do
		cd ${dir} || die
		emake || die "${dir}: emake failed"
		cd ..
	done
}

src_install_pr() {
	for dir in ${_prsrc}; do
		cd ${dir} || die
		emake DESTDIR="${D}" install || die "${dir}: emake install failed"
		cd ..
	done

	cp -a ${_prid}/libs_bin/* "${D}${_libdir}" || die
	cp -a ${_prid}/database/* "${D}${_libdir}"/cnijlib || die
	cp -a ppd/canon${_pr}.ppd "${D}${_ppddir}" || die
}
