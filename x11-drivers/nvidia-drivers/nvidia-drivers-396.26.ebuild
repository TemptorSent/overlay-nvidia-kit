# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit eutils flag-o-matic linux-info linux-mod multilib-minimal nvidia-driver \
	portability toolchain-funcs unpacker user udev

DESCRIPTION="NVIDIA Accelerated Graphics Driver"
HOMEPAGE="http://www.nvidia.com/ http://www.nvidia.com/Download/Find.aspx"

AMD64_FBSD_NV_PACKAGE="NVIDIA-FreeBSD-x86_64-${PV}"
AMD64_NV_PACKAGE="NVIDIA-Linux-x86_64-${PV}"
ARM_NV_PACKAGE="NVIDIA-Linux-armv7l-gnueabihf-${PV}"
X86_FBSD_NV_PACKAGE="NVIDIA-FreeBSD-x86-${PV}"
X86_NV_PACKAGE="NVIDIA-Linux-x86-${PV}"

NV_URI="http://us.download.nvidia.com/XFree86/"
SRC_URI=""
# No SRC_URI for nvidia-drivers from CUDA releases.
#	amd64-fbsd? ( ${NV_URI}FreeBSD-x86_64/${PV}/${AMD64_FBSD_NV_PACKAGE}.tar.gz )
#	amd64? ( ${NV_URI}Linux-x86_64/${PV}/${AMD64_NV_PACKAGE}.run )
#	tools? (
#		https://download.nvidia.com/XFree86/nvidia-settings/nvidia-settings-${PV}.tar.bz2
#	)
#"

LICENSE="GPL-2 NVIDIA-r2"
SLOT="0/${PV%.*}"
KEYWORDS="-* ~amd64 ~amd64-fbsd"
RESTRICT="bindist mirror strip"
EMULTILIB_PKG="true"

NV_PKG_USE="+opengl +egl +gpgpu +nvpd +nvifr +nvfbc +nvcuvid +nvml +encodeapi +vdpau +xutils +xdriver"
IUSE="+glvnd ${NV_PKG_USE} acpi compat +driver +opencl gtk3 kernel_FreeBSD kernel_linux +kms multilib pax_kernel static-libs +tools +uvm +wayland +X"

REQUIRED_USE="
	tools? ( X )
"

COMMON="
	opencl? (
		app-eselect/eselect-opencl
		dev-libs/ocl-icd
	)
	kernel_linux? ( >=sys-libs/glibc-2.6.1 )
	X? (
		>=app-eselect/eselect-opengl-1.0.9
		glvnd? ( >=media-libs/libglvnd-1.0.0.20180424 )
		app-misc/pax-utils
	)
"
DEPEND="
	${COMMON}
	kernel_linux? ( virtual/linux-sources )
	tools? ( sys-apps/dbus )
"
RDEPEND="
	${COMMON}
	acpi? ( sys-power/acpid )
	wayland? ( dev-libs/wayland[${MULTILIB_USEDEP}] )
	X? (
		<x11-base/xorg-server-1.20.99:=
		>=x11-libs/libX11-1.6.2[${MULTILIB_USEDEP}]
		>=x11-libs/libXext-1.3.2[${MULTILIB_USEDEP}]
		>=x11-libs/libvdpau-1.0[${MULTILIB_USEDEP}]
		sys-libs/zlib[${MULTILIB_USEDEP}]
	)
"
PDEPEND="tools? ( media-video/nvidia-settings )"




QA_PREBUILT="opt/* usr/lib*"
S=${WORKDIR}/

NV_ROOT="${EPREFIX}/opt/${P}"
NV_NATIVE_LIBDIR="${NV_ROOT%/}/lib64"
NV_COMPAT32_LIBDIR="${NV_ROOT%/}/lib32"

# Relative to $NV_ROOT
NV_BINDIR="bin"
NV_INCDIR="include"
NV_SHAREDIR="share"

# Relative to $NV_ROOT/lib{32,64}
NV_LIBDIR="/"
NV_OPENGL_VEND_DIR="opengl/nvidia"
NV_OPENCL_VEND_DIR="OpenCL/nvidia"
NV_X_MODDIR="xorg/modules"

# Check if we should use a given nvidia MODULE:<arg>
# Convert module names to use-flags as appropriate
nv_use() {
	local mymodule
	case "$1" in 
		installer) return 0;;
		compiler) mymodule="gpgpu" ;;
		*) mymodule="$1" ;;
	esac

	use "$mymodule" || return 1
	return 0
}

# Determine whether we should install GLVND, NON_GLVND, or neither version.
_nv_glvnd() {
	case "$1" in 
		GLVND) use glvnd && return 1 ;; # We want to use the system libglvnd, so skip installing from packaging.
		NON_GLVND) ! use glvnd && return 0 ;;
	esac
	return 1
}

# Check tls type
_nv_tls() {
	# Always install both.
	case "$1" in
		CLASSIC|NEW) return 0 ;;
	esac
	return 1
}

# <dir> <file> <perms> <MODULE:>
nv_install() {
	local mydir="${1#${NV_ROOT}}"
	mydir="${NV_ROOT}/${mydir#/}"
	local myfile="${2#/}"
	local myperms="$3"
	local mymodule="${4#MODULE:}"

	nv_use "${mymodule}" || return 0
	einfo "[${mymodule}] Installing '${myfile}' with perms ${myperms} to '${mydir%/}'."

	if ! [ -e "${myfile}" ] ; then
		ewarn "File '${myfile}' specified in manifest does not exist!"
		return 1
	fi

	insinto "${mydir%/}"
	insopts "-m${myperms}"
	doins "${myfile}"
}

# <dir> <file> <perms> <arch> <MODULE:>
nv_install_lib_arch() {
	local libdir
	case "${4}" in
		NATIVE) libdir="${NV_NATIVE_LIBDIR}" ;;
		COMPAT32) libdir="${NV_COMPAT32_LIBDIR}" ;;
		*) die "nv_install_lib_arch called with something other than NATIVE or COMPAT32 arch" ;;
	esac
	nv_install "${libdir}/${1#/}" "$2" "$3" "$5"
}

# <dir> <target> <source> <MODULE:>
nv_symlink() {
	local mydir="${1#${NV_ROOT}}"
	mydir="${NV_ROOT}/${mydir#/}"
	local mytgt="${2#/}"
	local mysrc="$3"
	local mymodule="${4#MODULE:}"
	nv_use "${mymodule}" || return 0
	einfo "[${mymodule}] Linking '${mysrc}' to '${mytgt}' in '${mydir%/}'."
	dosym "${mysrc}" "${mydir%/}/${mytgt#/}"
}

# <dir> <target> <arch> <source> <MODULE:>
nv_symlink_lib_arch() {
	local libdir
	case "${3}" in
		NATIVE) libdir="${NV_NATIVE_LIBDIR}" ;;
		COMPAT32) libdir="${NV_COMPAT32_LIBDIR}" ;;
		*) die "nv_install_lib_arch called with something other than NATIVE or COMPAT32 arch" ;;
	esac
	nv_symlink "${libdir%/}/${1#/}" "$2" "$4" "$5"
}

# <dir> <name> <perms> <MODULE:>
nv_install_modprobe() {
	# install nvidia-modprobe setuid and symlink in /usr/bin (bug #505092)
	nv_install "${1}" "${2}" "${3}" "${4}"
	fowners root:video ${NV_ROOT}/${1%/}/nvidia-modprobe
	fperms 4710 ${NV_ROOT}/${1%/}/nvidia-modprobe
	dosym /{${NV_ROOT#/}/${1%/},usr/bin}/nvidia-modprobe
}

# <dir> <template> <perms> <MODULE:>
nv_install_vulkan_icd() {
	rm -f "nvidia_icd.json" || die
	cp nvidia_icd.json.template nvidia_icd.json || die
	sed -i -e 's:__NV_VK_ICD__:libGLX_nvidia.so.0:g' nvidia_icd.json || die
	nv_install "$1" "nvidia_icd.json" "$3" "$4"
}

# <dir> <file> <perms> <MODULE:>
nv_install_outputclass_config() {
	nv_install "${1}" "$name" "$perms" "$f4"
	sed -e '/EndSection/ i\    ModulePath "'"${NV_ROOT}/$(get_libdir)/${NV_X_MODDIR}"'"\n    ModulePath "'"${NV_ROOT}/$(get_libdir)/${NV_OPENGL_VEND_DIR}"'"' \
	-i "${D}${NV_ROOT}/${1#/}/${name}"
}

# Run from root of extracted nvidia-drivers package.
nv_parse_manifest() {
	[ -r .manifest ] || die "Can not read .manifest!"
	local name perms type f4 f5 f6 f7
	while read -r name perms type f4 f5 f6 f7; do
		#einfo "Manifest entry: '$name' '$perms' '$type' '$f4' '$f5' '$f6' '$f7'"
		case "$type" in

			#<libname> <perms> <type> <NATIVE/COMPAT32> MODULE:<module>
			#<libname> <perms> OPENGL_LIB <NATIVE/COMPAT32> MODULE:<module>
			#<libname> <perms> LIBGL_LA <NATIVE/COMPAT32> MODULE:<module>
			#<libname> <perms> GLVND_LIB <NATIVE/COMPAT32> MODULE:<module>
			#<libname> <perms> NVCUVID_LIB <NATIVE/COMPAT32> MODULE:<module>
			#<libname> <perms> ENCODEAPI_LIB <NATIVE/COMPAT32> MODULE:<module>
			#<libname> <perms> NVIFR_LIB <NATIVE/COMPAT32> MODULE:<module>
			#<libname> <perms> UTILITY_LIB <NATIVE/COMPAT32> MODULE:<module>
			GLVND_LIB) _nv_glvnd "GLVND" && nv_install_lib_arch "${NV_OPENGL_VEND_DIR}/lib" "$name" "$perms" "$f4" "$f5" ;;
			OPENGL_LIB|LIBGL_LA|NVCUVID_LIB|ENCODEAPI_LIB|NVIFR_LIB|UTILITY_LIB) nv_install_lib_arch "${NV_LIBDIR}" "$name" "$perms" "$f4" "$f5" ;;

			#<libname> <perms> <type> <NATIVE/COMPAT32> <subdir> MODULE:<module>
			#<libname> <perms> CUDA_LIB <NATIVE/COMPAT32> <subdir> MODULE:<module>
			#<libname> <perms> OPENCL_LIB <NATIVE/COMPAT32> <subdir> MODULE:<module>
			#<libname> <perms> OPENCL_WRAPPER_LIB <NATIVE/COMPAT32> <subdir> MODULE:<module>
			#<libname> <perms> VDPAU_LIB <NATIVE/COMPAT32> <subdir> MODULE:<module>
			OPENCL_LIB|CUDA_LIB|VDPAU_LIB) nv_install_lib_arch "${NV_LIBDIR}/${f5%/}" "$name" "$perms" "$f4" "$f6" ;;
			OPENCL_WRAPPER_LIB) nv_install_lib_arch "${NV_OPENCL_VEND_DIR}/lib/${f5%/}" "$name" "$perms" "$f4" "$f6" ;;

			#<libname> <perms> <type> <NATIVE/COMPAT32> <GLVND/NON_GLVND> MODULE:<module>
			#<libname> <perms> GLX_CLIENT_LIB <NATIVE/COMPAT32> <GLVND/NON_GLVND> MODULE:<module>
			#<libname> <perms> EGL_CLIENT_LIB <NATIVE/COMPAT32> <GLVND/NON_GLVND> MODULE:<module>
			GLX_CLIENT_LIB|EGL_CLIENT_LIB) _nv_glvnd "$f5" && nv_install_lib_arch "${NV_OPENGL_VEND_DIR}/lib" "$name" "$perms" "$f4" "$f6" ;;


			#<libname> <perms> <type> <NATIVE/COMPAT32> <CLASSIC/NEW> <subdir> MODULE:<module>
			#<libname> <perms> TLS_LIB <NATIVE/COMPAT32> <CLASSIC/NEW> <subdir> MODULE:<module>
			TLS_LIB) _nv_tls "$f5" && nv_install_lib_arch "${NV_LIBDIR}/${f6%/}" "$name" "$perms" "$f4" "$f7" ;;

			#<libname-tgt> <perms> <type> <NATIVE/COMPAT32> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> OPENGL_SYMLINK <NATIVE/COMPAT32> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> GLVND_SYMLINK <NATIVE/COMPAT32> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> NVCUVID_LIB_SYMLINK <NATIVE/COMPAT32> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> ENCODEAPI_LIB_SYMLINK <NATIVE/COMPAT32> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> NVIFR_LIB_SYMLINK <NATIVE/COMPAT32> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> UTILITY_LIB_SYMLINK <NATIVE/COMPAT32> <libname-src> MODULE:<module>
			GLVND_SYMLINK)_nv_glvnd "GLVND" && nv_symlink_lib_arch "${NV_OPENGL_VEND_DIR}/lib" "$name" "$f4" "$f5" "$f6" ;;
			OPENGL_SYMLINK|NVCUVID_LIB_SYMLINK|ENCODEAPI_LIB_SYMLINK|NVIFR_LIB_SYMLINK|UTILITY_LIB_SYMLINK) nv_symlink_lib_arch "${NV_LIBDIR}" "$name" "$f4" "$f5" "$f6" ;;

			#<libname-tgt> <perms> <type> <NATIVE/COMPAT32> <subdir> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> CUDA_SYMLINK <NATIVE/COMPAT32> <subdir> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> OPENCL_LIB_SYMLINK <NATIVE/COMPAT32> <subdir> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> OPENCL_WRAPPER_SYMLINK <NATIVE/COMPAT32> <subdir> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> VDPAU_SYMLINK <NATIVE/COMPAT32> <subdir> <libname-src> MODULE:<module>
			OPENCL_LIB_SYMLINK|CUDA_SYMLINK|VDPAU_SYMLINK) nv_symlink_lib_arch "${NV_LIBDIR}/${f5%/}" "$name" "$f4" "$f6" "$f7" ;;
			OPENCL_WRAPPER_SYMLINK) nv_symlink_lib_arch "${NV_OPENCL_VEND_DIR}/lib/${f5%/}" "$name" "$f4" "$f6" "$f7" ;;

			#<libname-tgt> <perms> <type> <NATIVE/COMPAT32> <libname-src> <GLVND/NON_GLVND> MODULE:<module>
			#<libname-tgt> <perms> GLX_CLIENT_SYMLINK <NATIVE/COMPAT32> <libname-src> <GLVND/NON_GLVND> MODULE:<module>
			#<libname-tgt> <perms> EGL_CLIENT_SYMLINK <NATIVE/COMPAT32> <libname-src> <GLVND/NON_GLVND> MODULE:<module>
			GLX_CLIENT_SYMLINK|EGL_CLIENT_SYMLINK) _nv_glvnd "$f6" && nv_symlink_lib_arch "${NV_OPENGL_VEND_DIR}/lib" "$name" "$f4" "$f5" "$f7" ;;

			#<libname> <perms> <type> <subdir> MODULE:<module>
			#<libname> <perms> X_MODULE_SHARED_LIB <subdir> MODULE:<module>
			#<libname> <perms> GLX_MODULE_SHARED_LIB <subdir> MODULE:<module>
			XMODULE_SHARED_LIB) nv_install "$(get_libdir)/${NV_X_MODDIR}/${f4%/}" "$name" "$perms" "$f5";;
			GLX_MODULE_SHARED_LIB) nv_install "$(get_libdir)/${NV_OPENGL_VEND_DIR}/${f4%/}" "$name" "$perms" "$f5" ;;

			#<libname-tgt> <perms> <type> <subdir> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> XMODULE_SYMLINK <subdir> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> XMODULE_NEWSYM <subdir> <libname-src> MODULE:<module>
			#<libname-tgt> <perms> GLX_MODULE_SYMLINK <subdir> <libname-src> MODULE:<module>
			XMODULE_SYMLINK|XMODULE_NEWSYM) nv_symlink "$(get_libdir)/${NV_X_MODDIR}/${f4%/}" "$name" "$f5" "$f6";;
			GLX_MODULE_SYMLINK) nv_symlink "$(get_libdir)/${NV_OPENGL_VEND_DIR}/${f4%/}" "$name" "$f5" "$f6" ;;

			#<file> <perms> <type> <subdir> MODULE:<module>
			#<header> <perms> OPENGL_HEADER <subdir> MODULE:<module>
			#<profile> <perms> APPLICATION_PROFILE <subdir> MODULE:<module>
			#<file> <perms> DOCUMENTATION <subdir> MODULE:<module>
			#<file> <perms> DOT_DESKTOP <subdir> MODULE:<module>
			#<file> <perms> MANPAGE <subdir> MODULE:<module>
			#<binary> <perms> NVIDIA_MODPROBE <subdir> MODULE:<module>
			#<file> <perms> NVIDIA_MODPROBE_MANPAGE <subdir> MODULE:<module>
			OPENGL_HEADER) nv_install "${NV_INCDIR}/${f4%/}" "$name" "$perms" "$f5" ;;
			APPLICATION_PROFILE) nv_install "${NV_SHAREDIR}/nvidia/${f4%/}" "$name" "$perms" "$f5" ;;
			DOT_DESKTOP) nv_install "${NV_SHAREDIR}/applications/${f4%/}" "$name" "$perms" "$f5" ;;
			NVIDIA_MODPROBE) nv_install_modprobe "${NV_BINDIR}" "$name" "$perms" "$f5" ;;
			NVIDIA_MODPROBE_MANPAGE|MANPAGE) nv_install "${NV_SHAREDIR}/man/${f4%/}" "$name" "$perms" "$f5" ;;
			DOCUMENTATION) nv_install "${NV_SHAREDIR}/doc/${f4%/}" "$name" "$perms" "$f5" ;;

			#<file> <perms> <type> MODULE:<module>
			#<binary> <perms> INSTALLER_BINARY MODULE:<module>
			#<binary> <perms> UTILITY_BINARY MODULE:<module>
			#<conf-file> <perms> XORG_OUTPUTCLASS_CONFIG MODULE:<module>
			#<file> <perms> CUDA_ICD MODULE:<module>
			#<file> <perms> VULKAN_ICD_JSON MODULE:<module>
			#<file> <perms> GLVND_EGL_ICD_JSON MODULE:<module>
			#<file> <perms> EGL_EXTERNAL_PLATFORM_JSON MODULE:<module>
			INSTALLER_BINARY) [ "x${name}" = "xnvidia-installer" ] || nv_install "${NV_BINDIR}" "$name" "$perms" "$f4" ;;
			UTILITY_BINARY) nv_install "${NV_BINDIR}" "$name" "$perms" "$f4" ;;
			XORG_OUTPUTCLASS_CONFIG) nv_install_outputclass_config "${NV_SHAREDIR}/X11/xorg.conf.d/" "$name" "$perms" "$f4" ;;
			CUDA_ICD) nv_install "${NV_SHAREDIR}/OpenCL/vendors/" "$name" "$perms" "$f4" ;;
			VULKAN_ICD_JSON) nv_install_vulkan_icd "${NV_SHAREDIR}/vulkan/icd.d/" "$name" "$perms" "$f4" ;;
			GLVND_EGL_ICD_JSON) nv_install "${NV_SHAREDIR}/glvnd/egl_vendor.d/" "$name" "$perms" "$f4" ;;
			EGL_EXTERNAL_PLATFORM_JSON) nv_install "${NV_SHAREDIR}/egl/egl_external_platform.d/" "$name" "$perms" "$f4" ;;

			#<bin-tgt> <perms> <type> <bin-src> MODULE:<module>
			#<bin-tgt> <perms> UTILITY_BIN_SYMLINK <bin-src> MODULE:<module>
			UTILITY_BIN_SYMLINK) [ "x${f4}" = "xnvidia-installer" ] || nv_symlink "${NV_BINDIR}" "$name" "$f4" "$f5" ;;

		esac
		
	done <<-EOF
		$(tail -n +9 .manifest)
	EOF
}

nvidia_drivers_versions_check() {
	if use amd64 && has_multilib_profile && \
		[ "${DEFAULT_ABI}" != "amd64" ]; then
		eerror "This ebuild doesn't currently support changing your default ABI"
		die "Unexpected \${DEFAULT_ABI} = ${DEFAULT_ABI}"
	fi

	if use kernel_linux && kernel_is ge 4 17; then
		ewarn "Gentoo supports kernels which are supported by NVIDIA"
		ewarn "which are limited to the following kernels:"
		ewarn "<sys-kernel/gentoo-sources-4.17"
		ewarn "<sys-kernel/vanilla-sources-4.17"
		ewarn ""
		ewarn "You are free to utilize epatch_user to provide whatever"
		ewarn "support you feel is appropriate, but will not receive"
		ewarn "support as a result of those changes."
		ewarn ""
		ewarn "Do not file a bug report about this."
		ewarn ""
	fi

	# Since Nvidia ships many different series of drivers, we need to give the user
	# some kind of guidance as to what version they should install. This tries
	# to point the user in the right direction but can't be perfect. check
	# nvidia-driver.eclass
	nvidia-driver-check-warning

	# Kernel features/options to check for
	CONFIG_CHECK="~ZONE_DMA ~MTRR ~SYSVIPC ~!LOCKDEP"
	use x86 && CONFIG_CHECK+=" ~HIGHMEM"

	# Now do the above checks
	use kernel_linux && check_extra_config
}

pkg_pretend() {
	nvidia_drivers_versions_check
}

pkg_setup() {
	nvidia_drivers_versions_check

	# set variables to where files are in the package structure
	if use kernel_FreeBSD; then
		NV_KMOD_SRC="${S}/src"
	elif use kernel_linux; then
		NV_KMOD_SRC="${S}/kernel"
	else
		die "Could not determine proper NVIDIA kernel modules' source path in package."
	fi
}

src_install() {
	nv_parse_manifest

	dodir "${NV_ROOT}/src/${P}-kmod"
	(set +f; cp -r "${NV_KMOD_SRC}"/* "${D}${NV_ROOT}/src/${P}-kmod" || return 1 ) || die "Could not copy kernel module sources!"


	if use X; then
		# Xorg DDX driver
		insinto /usr/$(get_libdir)/xorg/modules/drivers
		#doins ${NV_X11}/nvidia_drv.so

		# Xorg GLX driver
		#donvidia ${NV_X11}/libglx.so.${NV_SOVER} \
		#	/usr/$(get_libdir)/opengl/nvidia/extensions

		# Xorg nvidia.conf
		if has_version '>=x11-base/xorg-server-1.16'; then
			insinto /usr/share/X11/xorg.conf.d
		#	newins {,50-}nvidia-drm-outputclass.conf
		fi

		insinto /usr/share/glvnd/egl_vendor.d
		#doins ${NV_X11}/10_nvidia.json
	fi

	if use wayland; then
		insinto /usr/share/egl/egl_external_platform.d
		#doins ${NV_X11}/10_nvidia_wayland.json
	fi

	# OpenCL ICD for NVIDIA
	if use kernel_linux; then
		insinto /etc/OpenCL/vendors
		#doins ${NV_OBJ}/nvidia.icd
	fi

	# Documentation
	#if use kernel_FreeBSD; then
		#dodoc "${NV_DOC}/README"
		#use X && doman "${NV_MAN}"/nvidia-xconfig.1
		#use tools && doman "${NV_MAN}"/nvidia-settings.1
	#else
		# Docs
		#newdoc "${NV_DOC}/README.txt" README
		#dodoc "${NV_DOC}/NVIDIA_Changelog"
		#doman "${NV_MAN}"/nvidia-smi.1
		#use X && doman "${NV_MAN}"/nvidia-xconfig.1
		#use tools && doman "${NV_MAN}"/nvidia-settings.1
		#doman "${NV_MAN}"/nvidia-cuda-mps-control.1
	#fi

	docinto html
	#dodoc -r ${NV_DOC}/html/*

	# Helper Apps
	exeinto ${NV_ROOT}/bin/

	if use X; then
		#doexe ${NV_OBJ}/nvidia-xconfig

		insinto /etc/vulkan/icd.d
		doins nvidia_icd.json
	fi

	if use kernel_linux; then
		#doexe ${NV_OBJ}/nvidia-cuda-mps-control
		#doexe ${NV_OBJ}/nvidia-cuda-mps-server
		#doexe ${NV_OBJ}/nvidia-debugdump
		#doexe ${NV_OBJ}/nvidia-persistenced
		#doexe ${NV_OBJ}/nvidia-smi


		#doman nvidia-cuda-mps-control.1
		#doman nvidia-persistenced.1
		newinitd "${FILESDIR}/nvidia-smi.init" nvidia-smi
		newconfd "${FILESDIR}/nvidia-persistenced.conf" nvidia-persistenced
		newinitd "${FILESDIR}/nvidia-persistenced.init" nvidia-persistenced
	fi

	if use tools; then
		insinto /usr/share/nvidia/
		#doins nvidia-application-profiles-${PV}-key-documentation

		insinto /etc/nvidia
		#newins \
		#	nvidia-application-profiles-${PV}-rc nvidia-application-profiles-rc

		# There is no icon in the FreeBSD tarball.
		#use kernel_FreeBSD || \
		#	doicon ${NV_OBJ}/nvidia-settings.png

		#domenu "${FILESDIR}"/nvidia-settings.desktop

		exeinto /etc/X11/xinit/xinitrc.d
		#newexe "${FILESDIR}"/95-nvidia-settings-r1 95-nvidia-settings
	fi

	#dobin ${NV_OBJ}/nvidia-bug-report.sh


	is_final_abi || die "failed to iterate through all ABIs"

	readme.gentoo_create_doc
}


pkg_preinst() {

	# Clean the dynamic libGL stuff's home to ensure
	# we dont have stale libs floating around
	if [ -d "${ROOT}"/usr/lib/opengl/nvidia ]; then
		rm -rf "${ROOT}"/usr/lib/opengl/nvidia/*
	fi
	# Make sure we nuke the old nvidia-glx's env.d file
	if [ -e "${ROOT}"/etc/env.d/09nvidia ]; then
		rm -f "${ROOT}"/etc/env.d/09nvidia
	fi
}

pkg_postinst() {

	# Switch to the nvidia implementation
	use X && "${ROOT}"/usr/bin/eselect opengl set --use-old nvidia
	use opencl && "${ROOT}"/usr/bin/eselect opencl set --use-old ocl-icd

	readme.gentoo_print_elog

	if ! use X; then
		elog "You have elected to not install the X.org driver. Along with"
		elog "this the OpenGL libraries and VDPAU libraries were not"
		elog "installed. Additionally, once the driver is loaded your card"
		elog "and fan will run at max speed which may not be desirable."
		elog "Use the 'nvidia-smi' init script to have your card and fan"
		elog "speed scale appropriately."
		elog
	fi
	if ! use tools; then
		elog "USE=tools controls whether the nvidia-settings application"
		elog "is installed. If you would like to use it, enable that"
		elog "flag and re-emerge this ebuild. Optionally you can install"
		elog "media-video/nvidia-settings"
		elog
	fi
}

pkg_prerm() {
	use X && "${ROOT}"/usr/bin/eselect opengl set --use-old xorg-x11
}

pkg_postrm() {
	use X && "${ROOT}"/usr/bin/eselect opengl set --use-old xorg-x11
}
