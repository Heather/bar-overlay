# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: www-misc/browser-home-profile/browser-home-profile-1.0.ebuild,v 1.1 2015/05/14 Exp $

EAPI=5

inherit eutils

DESCRIPTION="Web-Browser Home Profile Utility"
HOMEPAGE="https://github.com/tokiclover/browser-home-profile"
SRC_URI="https://github.com/tokiclover/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="sys-apps/sed"
RDEPEND="${DEPEND}"

src_install()
{
	sed '/.*COPYING.*$/d' -i Makefile
	emake PREFIX=/usr DESTDIR="${ED}" install
}
