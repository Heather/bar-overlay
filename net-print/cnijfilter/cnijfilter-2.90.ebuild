# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: net-print/cnijfilter-drivers/cnijfilter-driverss-2.90.ebuild,v 2.0 2014/08/04 06:45:32 -tclover Exp $

EAPI=5

MULTILIB_COMPAT=( abi_x86_32 )

PRINTER_USE=( "ip100" "ip2600" )
PRINTER_ID=( "303" "331" )

inherit ecnij

DESCRIPTION="Canon InkJet Printer Driver for Linux (Pixus/Pixma-Series)"
DOWNLOAD_URL="http://support-ph.canon-asia.com/contents/PH/EN/0100119202.html"
SRC_URI="http://gdlp01.c-wss.com/gds/2/0100001192/01/${PN}-common-${PV}-1.tar.gz"

SLOT="${PV:0:1}"

DEPEND=">=net-print/cups-1.1.14[${MULTILIB_USEDEP}]"
RDEPEND="${RDEPEND}"

RESTRICT="mirror"

S="${WORKDIR}"/${PN}-common-${PV}

PATCHES=(
	"${FILESDIR}"/${PN}-2.70-1-png_jmpbuf-fix.patch
	"${FILESDIR}"/${PN}-2.80-1-libexec-backend.patch
	"${FILESDIR}"/${PN}-3.20-4-ppd.patch
	"${FILESDIR}"/${PN}-3.70-1-libexec-cups.patch
)

