# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: media-sound/ladish/ladish-1.ebuild,v 1.5 2014/10/10 12:14:19 -tclover Exp $

EAPI=5

PYTHON_COMPAT=( python2_7 )

PLOCALES="de fr ru"

inherit l10n python-single-r1 waf-utils multilib-minimal

DESCRIPTION="LADI Session Handler - a session management system for JACK applications"
HOMEPAGE="http://ladish.org/"
SRC_URI="https://github.com/LADI/archive/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug doc gtk lash nls python"
REQUIRED_USE="python? ( lash ) ${PYTHON_REQUIRED_USE}"

RDEPEND="lash? ( !media-sound/lash )
	media-sound/jack-audio-connection-kit[dbus,${MULTILIB_USEDEP}]
	dev-libs/expat[${MULTILIB_USEDEP}]
	gtk? ( 
		dev-libs/boost[${MULTILIB_USEDEP}]
		>=x11-libs/gtk+-2.20.0:2[${MULTILIB_USEDEP}]
		>=x11-libs/flowcanvas-0.6.4
		>=dev-libs/glib-2.20.3[${MULTILIB_USEDEP}]
		>=dev-libs/dbus-glib-0.74[${MULTILIB_USEDEP}]
		>=gnome-base/libglade-2.6.2[${MULTILIB_USEDEP}]
	)
	sys-apps/dbus[${MULTILIB_USEDEP}]
	${PYTHON_DEPS}"

DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	virtual/pkgconfig
	nls? ( virtual/libintl )"

DOCS=( AUTHORS README NEWS )

PATCHES=(
	"${FILESDIR}"/${P}-include.patch
	"${FILESDIR}"/${P}-libdir.patch
)

src_unpack()
{
	default
	mv {${PN}-,}${P} || die
}

src_prepare()
{
	epatch "${PATCHES[@]}"
	epatch_user

	local linguas
	use nls && linguas="$(l10n_get_locales)"
	echo "${linguas}" >po/LINGUAS

	multilib_copy_sources
}

multilib_src_configure()
{
	local -a mywafconfargs=(
		$(usex debug --debug '')
		$(usex doc --doxygen '')
		$(use_enable lash liblash)
		$(use_enable python pylash)
	)
	NO_WAF_LIBDIR=1 PREFIX="${EPREFIX}/usr" LIBDIR="${EPREFIX}/usr/$(get_libdir)" \
		WAF_BINARY="${BUILD_DIR}"/waf waf-utils_src_configure "${mywafconfargs[@]}"
}

multilib_src_compile()
{
	WAF_BINARY="${BUILD_DIR}"/waf waf-utils_src_install
}

multilib_src_install()
{
	WAF_BINARY="${BUILD_DIR}"/waf waf-utils_src_install
	dosym /usr/$(get_libdir)/liblash.so{.1,}

	multilib_is_native_abi && use doc && dohtml -r build/default/html/*
}

multilib_src_install_all()
{
	rm -f "${ED}"/usr/share/${PN}/{AUTHORS,COPYING,NEWS,README}
	python_fix_shebang "${ED}"
}

