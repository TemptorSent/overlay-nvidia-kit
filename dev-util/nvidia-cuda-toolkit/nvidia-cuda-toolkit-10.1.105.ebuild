# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit multilib-build check-reqs cuda toolchain-funcs unpacker versionator

CUDA_VERSION="$(get_version_component_range 1-2)"
PATCH_LEVEL="${PV##*_p}"
[ "${PV}" = "${PATCH_LEVEL}" ] && PATCH_LEVEL=0
MY_PV="${PV%_p*}"

# If these don't match, it means the bundled drivers are too old to use, so disable them.
DRIVER_PV="418.39"
DRIVER_MIN_PV="418.39"

# GCC versions officially supported and supported by gcc-version-hack.
CUDA_SUPPORTED_GCC="4.7 4.8 4.9 5.3 5.4 6.3 6.4 6.5 7.2 7.3 8.1 8.2 8.3"
CUDA_UNSUPPORTED_GCC="9.1"

CUDA_PKGNAME="cuda_${MY_PV}_${DRIVER_PV}_linux.run"

DESCRIPTION="NVIDIA CUDA Toolkit (compiler and friends)"
HOMEPAGE="https://developer.nvidia.com/cuda-zone"

# Set the base URI for fetching packages for this version of CUDA
CUDA_URI_BASE="https://developer.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod"
[ "${CUDA_VERSION}" = "9.2" ] && CUDA_URI_BASE="${CUDA_URI_BASE}2"

SRC_URI="${CUDA_URI_BASE}/local_installers/${CUDA_PKGNAME} -> ${CUDA_PKGNAME%.run}.run"

# Add patches to fetch based on PATCH_LEVEL
my_pl=${PATCH_LEVEL}
while [ ${my_pl} -gt 0 ] ; do
	SRC_URI="${SRC_URI} ${CUDA_URI_BASE}/patches/${my_pl}/cuda_${MY_PV}.${my_pl}_linux -> cuda_${MY_PV}.${my_pl}_linux.run"
	my_pl=$((my_pl-1))
done
unset my_pl


SLOT="${CUDA_VERSION}/${MY_PV}"
LICENSE="NVIDIA-CUDA"
KEYWORDS="-* ~amd64 ~amd64-linux"
IUSE="+debugger +doc +eclipse +profiler +copy-bundled-samples gcc-version-hack"
[ "${DRIVER_PV}" = "${DRIVER_MIN_PV}" ] && IUSE="${IUSE} copy-bundled-drivers"

DEPEND=""
RDEPEND="${DEPEND}
	>=sys-devel/gcc-4.7[cxx]
	!gcc-version-hack? ( <=sys-devel/gcc-${CUDA_SUPPORTED_GCC##* }[cxx] )
	gcc-version-hack? ( <=sys-devel/gcc-${CUDA_UNSUPPORTED_GCC##* }[cxx] )
	>=x11-drivers/nvidia-drivers-${DRIVER_MIN_PV}[X,uvm]
	debugger? (
		sys-libs/libtermcap-compat
		sys-libs/ncurses:5/5[tinfo]
		)
	eclipse? ( >=virtual/jre-1.6 )
	profiler? ( >=virtual/jre-1.6 )"

S="${WORKDIR}"

DRIVER_RUN="NVIDIA-Linux-x86_64-${DRIVER_PV}.run"

CHECKREQS_DISK_BUILD="3500M"

OPT_NVIDIA_DIR="${EPREFIX}/opt/nvidia"
OPT_NVIDIA_DISTFILES="${EPREFIX}/opt/nvidia/distfiles"
CUDA_DIR="${OPT_NVIDIA_DIR}/cuda-${CUDA_VERSION}"
ECUDA_DIR="${EPREFIX}${CUDA_DIR}"
EDCUDA_DIR="${D%/}${ECUDA_DIR}"
QA_PREBUILT="*"
RESTRICT="strip"
pkg_setup() {
	# We don't like to run cuda_pkg_setup as it depends on us
	check-reqs_pkg_setup
}
src_prepare() {
	eapply_user
}

src_unpack() {
	mkdir -p "${S}"

	# Unpack our runfile
	unpacker "${A}"
}

_nv_cuda_read_manifest() {

	# Tweak names for packages we want to install that don't have short names.
	( set +f; cat "${WORKDIR}/manifests"/cuda_*.xml ) | sed \
		-e 's/CUDA Misc Headers 10.1/cuda-misc-headers/' \
		-e 's/CUDA Samples 10.1/cuda-samples/' \
		-e 's/CUDA Demo Suite 10.1/cuda-demo-suite/' \
		-e 's/CUDA Documentation 10.1/cuda-documentation/' \
		-e 's|\(<file>targets/x86_64-linux/include\)\(npp\.\*</file>\)|\1/\2|'

}

_nv_cuda_install_package_from_manifest() {
	local mysrcpath mydestpath mydir myfile myfiles mylib mylibs mydescription myfilename mylibname myname mycategories mykeywords

	read -r mysrcpath mydestpath <<-EOF
		$(_nv_cuda_get_paths_for_package "${1}")
	EOF

	mysrcpath="${mysrcpath%/}"
	mydestpath="${mydestpath%/}"

	if [ "${mydestpath}" = "/usr/local/cuda-${CUDA_VERSION}" ] || [ -z "${mydestpath}" ] ; then mydestpath="${CUDA_DIR}" ; fi

	pushd "${S}/${mysrcpath#./}" > /dev/null
	einfo "Installing ${1}..."
	_nv_cuda_get_manifest_for_package "${1}" | while read -r line
	do
		case "${line}" in
			"<dir>"*)
				mydir="$(echo "${line}" | sed -e 's|\(<dir>\)\(.*\)\(</dir>\)|\2|' )"
				dodir "${mydestpath}/${mydir}"
			;;
			"<file"*)
				case "${line}" in
					"<file dir="*)
						mydir="$(echo "${line}" | sed -e 's|\(<file dir=\)\(.*\)\(>\)\(.*\)\(</file>\)|\2|' -e 's/"//g' -e 's/\$//' )"
						myfiles="$(echo "${line}" | sed -e 's|\(<file dir=\)\(.*\)\(>\)\(.*\)\(</file>\)|\4|' -e 's/.\*/\*/g' )"
					;;
					*)
						mydir=""
						myfiles="$(echo "${line}" | sed -e 's|\(<file.*>\)\(.*\)\(</file>\)|\2|' -e 's/.\*/\*/g')"
					;;
				esac

				case "${myfiles}" in
					*/*) mydestdir="${mydir:+${mydir%/}/}${myfiles%/*}" ;;
					*) mydestdir="${mydir}" ;;
				esac

				insinto "${mydestpath}${mydestdir:+/${mydestdir}}"

				if [ -d "${myfiles}" ] ; then
					doins -r ${myfiles%/}
				else
					for myfile in ${myfiles} ; do
						doins ${myfile}
					done
				fi

			;;
			"<libDir>"*)
				mydir="lib64/$(echo "${line}" | sed -e 's|\(<libDir>\)\(.*\)\(</libDir>\)|\2|' )"
				dodir "${mydestpath}/${mydir}"
			;;
			"<libFile"*)
				case "${line}" in
					"<libFile dir="*)
						mydir="$(echo "${line}" | sed -e 's|\(<libFile dir=\)\(.*\)\(>\)\(.*\)\(</libFile>\)|\2|' -e 's/"//g' -e 's/\$//' )"
						mylibs="$(echo "${line}" | sed -e 's|\(<libFile dir=\)\(.*\)\(>\)\(.*\)\(</libFile>\)|\4|' -e 's/.\*/\*/g' )"
					;;
					*)
						mydir=""
						mylibs="$(echo "${line}" | sed -e 's|\(<libFile.*>\)\(.*\)\(</libFile>\)|\2|' -e 's/.\*/\*/g')"
					;;
				esac
				if [ -d "${mylibs}" ] ; then
					case "${mylibs}" in
						*/*) mydestdir="${mydir:+${mydir%/}/}${mylibs%/*}" ;;
						*) mydestdir="${mydir}";;
					esac
					insinto "${mydestpath}${mydestdir:+/${mydestdir}}"
					doins -r ${mylibs%/}
				else
					mydestdir="lib64${mydir:+/${mydir%/}}"
					insinto "${mydestpath}${mydestdir:+/${mydestdir}}"
					for mylib in ${mylibs} ; do
						doins ${mylib}
					done
				fi
			;;
			"<pcfile "*)
				mydescription="$(echo "${line}" | sed -e 's|\(<pcfile.* description="\)\([^"]*\)\(">\)\(.*\)\(</pcfile>\)|\2|' )"
				myfilename="$(echo "${line}" | sed -e 's|\(<pcfile.* description="\)\([^"]*\)\(">\)\(.*\)\(</pcfile>\)|\4|' )"
				dodir "${CUDA_DIR}/pkgconfig"
				mylibname="${myfilename%-${CUDA_VERSION}.pc}"
				einfo "Creating pkgconfig file '${myfilename}'"
				cat > "${EDCUDA_DIR}/pkgconfig/${myfilename}" <<-EOF
					cudaroot=${ECUDA_DIR}
					libdir=\${cudaroot}/lib64
					includedir=\${cudaroot}/include
					Name: ${mylibname}
					Description: ${mydescription}
					Version: ${CUDA_VERSION}
					Libs: -L\${libdir} -l${mylibname}
					Cflags: -I\${includedir}
				EOF
			;;
			"<desktopFile "*)
				myfilename="$(echo "${line}" | sed -e 's|\(<desktopFile.* filename="\)\([^"]*\)".*/>|\2|')"
				myname="$(echo "${line}" | sed -e 's|\(<desktopFile.* name="\)\([^"]*\)".*/>|\2|')"
				mycategories="$(echo "${line}" | sed -e 's|\(<desktopFile.* categories="\)\([^"]*\)".*/>|\2|')"
				mykeywords="$(echo "${line}" | sed -e 's|\(<desktopFile.* keywords="\)\([^"]*\)".*/>|\2|')"
				mkdir -p "${ED%/}/usr/share/applications"
				einfo "Creating desktop file '${myfilename}'"
				cat > "${ED%/}/usr/share/applications/${myfilename}-${CUDA_VERSION}.desktop" <<-EOF
					[Desktop Entry]
					Type=Application
					Name=${myname} ${CUDA_VERSION}
					GenericName=${myfilename}
					Icon=${ECUDA_DIR}/lib${myfilename}/icon.xpm
					Exec=${ECUDA_DIR}/bin/${myfilename}
					TryExec=${ECUDA_DIR}/bin/${myfilename}
					Keywords=${mykeywords}
					X-AppInstall-Keywords=${mykeywords}
					X-GNOME-Keywords=${mykeywords}
					Terminal=false
					Categories=${mycategories}
				EOF
			;;
		esac
	done

	# Cleanups for broken install locations for cublas:
	for mydir in /usr/include /usr/src /usr/share ; do
		[ -d "${mydir}" ] || continue
		for myfile in "${ED%/}/${mydir}"/* ; do
			if [ -f "${myfile}" ] ; then
				mkdir -p "${ED%/}/${mydir}/${1}"
				mv "${myfile}" "${ED%/}/${mydir}/${1}"
			fi
		done
	done
	popd > /dev/null
}

_nv_cuda_get_manifest_for_package() {
	_nv_cuda_read_manifest | awk '/<package/ { getline; if ( $0 ~ /<name>'"${1}"'<\/name>/) { printem=1;}; }; printem==1 && /<\/package>/ { exit; }; printem==1 {print;};' | sed -e 's/^[[:space:]]\+//'
}

_nv_cuda_get_paths_for_package() {
	_nv_cuda_read_manifest \
	| awk 'BEGIN { depth=0; buildpath[0]=""; installpath[0]=""; };
		/<package/ { buildpath[depth+1]=buildpath[depth]; installpath[depth+1]=installpath[depth]; depth++; };
		/<buildPath>/ { gsub(/<[\/]?buildPath>/, ""); buildpath[depth]=$0; };
		/<installPath>/ { gsub(/<[\/]?installPath>/,""); installpath[depth]=$0; };
		/<name>'"${1}"'<\/name>/ { found=1; };
		found==1 && /<\/package>/ { print buildpath[depth] installpath[depth]; exit; };
		/<\/package>/ { depth--; buildpath[depth+1]=buildpath[depth]; installpath[depth+1]=installpath[depth]; };
		' | sed -e  's/^[[:space:]]\+//'
}

src_install() {
	local mypkgs=(
		cuda-gdb
		cuda-gdb-src
		cuda-nvprof
		cuda-memcheck
		cuda-nvdisasm
		cuda-cupti
		cuda-sanitizer-api
		cuda-gpu-library-advisor
		cuda-nvtx
		cuda-nsight
		cuda-nsight-compute
		cuda-nsight-systems
		cuda-nvvp
		cuda-cusolver
		cuda-cufft
		cuda-curand
		cuda-cusparse
		cuda-nvgraph
		cuda-npp
		cuda-cudart
		cuda-nvrtc
		cuda-nvjpeg
		cuda-cusolver-dev
		cuda-cufft-dev
		cuda-curand-dev
		cuda-cusparse-dev
		cuda-driver-dev
		cuda-nvgraph-dev
		cuda-npp-dev
		cuda-cudart-dev
		cuda-nvrtc-dev
		cuda-nvml-dev
		cuda-nvjpeg-dev
		cuda-nvcc
		cuda-cuobjdump
		cuda-nvprune

		libcublas10
		libcublas-dev

		cuda-misc-headers
		cuda-samples
		cuda-demo-suite
		cuda-documentation
	)

	for mypkg in "${mypkgs[@]}" ; do
		[ -n "${mypkg}" ] && _nv_cuda_install_package_from_manifest "${mypkg}"
	done

}

xsrc_install() {
	local i remove=( jre install-linux.pl )

	dodir "${CUDA_DIR}"

	use doc || remove+=( doc )

	mv doc/man/man3/{,cuda-}deprecated.3 || die

	use debugger || remove+=( bin/cuda-gdb extras/Debugger extras/cuda-gdb-${MY_PV}.src.tar.gz )

	use profiler || use eclipse || remove+=( libnvvp libnsight )
	use profiler || remove+=( extras/CUPTI )

	for i in "${remove[@]}"; do
		ebegin "Cleaning ${i}..."
		rm -rf "${i}" || die
		eend
	done

	[ -d distfiles ] && mv distfiles "${D}${OPT_NVIDIA_DISTFILES}"
	mv * "${EDCUDA_DIR}" || die

	cat > "${T}"/99cuda <<- EOF || die
		PATH=${ECUDA_DIR}/bin$(usex profiler ":${ECUDA_DIR}/libnvvp" "")
		ROOTPATH=${ECUDA_DIR}/bin
		LDPATH=${ECUDA_DIR}/lib64:${ECUDA_DIR}/lib:${ECUDA_DIR}/nvvm/lib64
	EOF
	newenvd "${T}/99cuda" "99cuda-${MY_PV}"


	local my_pl=${PATCH_LEVEL}
	while [ ${my_pl} -gt 0 ] ; do
		my_patch="cuda_${MY_PV}.${my_pl}_linux"
		if [ -d "${WORKDIR}/${my_patch}" ] ; then
			pushd "${WORKDIR}/${my_patch}" > /dev/null
				_nv_cuda_install_patch
			popd > /dev/null
		fi
		my_pl=$((my_pl-1))
	done

	if use profiler ; then
		# hack found in install-linux.pl
		for i in nvvp nsight; do
			cat > "${EDCUDA_DIR}/bin/${i}" <<- EOF || die
				#!/usr/bin/env sh
				LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:${ECUDA_DIR}/lib:${ECUDA_DIR}/lib64 \
					UBUNTU_MENUPROXY=0 LIBOVERLAY_SCROLLBAR=0 \
					${ECUDA_DIR}/lib${i}/${i} -vm ${EPREFIX}/usr/bin/java
			EOF
			fperms a+x "${CUDA_DIR}/bin/${i}" || die
		done
		( cd "${EDCUDA_DIR}/bin" && mv nvprof nvprof.bin )
		make_wrapper nvprof "${ECUDA_DIR}/bin/nvprof.bin" "." "${ECUDA_DIR}/lib64:${ECUDA_DIR}/lib" "${ECUDA_DIR}/bin"
	fi

	_nv_cuda_make_pc_files
	exeinto "${CUDA_DIR}/bin"
	doexe "${T}"/cuda-config
}

pkg_postinst_check() {
	local a b
	a="$(version_sort $(cuda-config -s))"
	# greatest supported version
	b="${a##* }"

	# if gcc and if not gcc-version is at least greatest supported
	if tc-is-gcc && \
		! version_is_at_least gcc-version ${b}; then
			ewarn ""
			ewarn "gcc >= ${b} will not work with CUDA"
			ewarn "Make sure you set an earlier version of gcc with gcc-config"
			ewarn "or append --compiler-bindir= pointing to a gcc bindir like"
			ewarn "--compiler-bindir=<${EPREFIX}/usr/*pc-linux-gnu/gcc-bin/gcc${b}.?> "
			ewarn "to the nvcc compiler flags"
			ewarn ""
	fi
}

pkg_postinst() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		pkg_postinst_check
	fi
}

