# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils multilib

DESCRIPTION="NVIDIA Linux X11 Settings Utility"
HOMEPAGE="http://www.nvidia.com/"
SRC_URI="https://download.nvidia.com/XFree86/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
IUSE="dbus +gtk3 vdpau +system-jansson"

RDEPEND="x11-drivers/nvidia-drivers
        system-jansson? ( >=dev-libs/jansson-2.2 )
        x11-libs/gdk-pixbuf[X]
        x11-libs/libX11
        x11-libs/libXext
        x11-libs/libXrandr
        x11-libs/libXv
        x11-libs/libXxf86vm
        gtk3? ( x11-libs/gtk+:3 )
        !gtk3? ( x11-libs/gtk+:2 )
        dbus? ( sys-apps/dbus )
        vdpau? ( x11-libs/libvdpau )"
DEPEND="${RDEPEND}"

src_prepare() {
    epatch "${FILESDIR}/nvidia-settings-gtk-independence.patch"
    default
	# Don't forecfully strip non-debug builds
	sed -e 's/\([[:space:]]*DO_STRIP[[:space:]]*?=\)[[:space:]]*1/\1/' \
		-i utils.mk -i src/libXNVCtrl/utils.mk
}

src_compile() {
    emake PREFIX="/usr" NV_USE_BUNDLED_LIBJANSSON=$(use !system-jansson | echo $?)
}

src_install() {
    emake PREFIX="/usr" DESTDIR="${D}" NV_USE_BUNDLED_LIBJANSSON=$(use !system-jansson | echo $?) install

	dodoc doc/nvidia-settings.png doc/FRAMELOCK.txt doc/NV-CONTROL-API.txt

	dodir "/usr/share/applications"
	sed -e 's|__UTILS_PATH__|'"${EPREFIX}/usr/bin"'|' \
		-e 's|__PIXMAP_PATH__|'"${EPREFIX}/usr/share/doc/${PF}/"'|' \
		-e 's|__NVIDIA_SETTINGS_DESKTOP_CATEGORIES__|Settings;HardwareSettings;|' \
		"${S}/doc/nvidia-settings.desktop" > "${ED}/usr/share/applications/nvidia-settings.desktop"

}

