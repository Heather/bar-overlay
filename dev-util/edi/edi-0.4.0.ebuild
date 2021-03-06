# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: dev-util/edi/edi-9999.ebuild,v 1.1 2015/02/02 12:02:10 Exp $

EAPI=5
AUTOTOOLS_AUTORECONF=1

case "${PV}" in
	(*9999*)
	KEYWORDS=""
	VCS_ECLASS=git-2
	EGIT_REPO_URI="git://git.enlightenment.org/tools/${PN}.git"
	EGIT_PROJECT="${PN}.git"
	;;
	(*)
	KEYWORDS="~amd64 ~arm ~x86"
	SRC_URI="https://github.com/ajwillia-ms/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	;;
esac
inherit autotools-utils ${VCS_ECLASS}

DESCRIPTION="EFL based IDE"
HOMEPAGE="https://www.enlightenment.org/about-edi"

IUSE="clang doc test"
LICENSE="GPL-2 LGPL-2.1"
SLOT="0"

RDEPEND=">=dev-libs/efl-1.18.0"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	clang? ( sys-devel/clang )
	virtual/libintl"

DOCS=( AUTHORS ChangeLog NEWS README TODO )

src_configure()
{
	local -a myeconfargs=(
		${EXTRA_EFLETE_CONF}
		--with-tests=$(usex test regular coverage)
		$(use_enable clang libclang)
	)
	autotools-utils_src_configure
}
