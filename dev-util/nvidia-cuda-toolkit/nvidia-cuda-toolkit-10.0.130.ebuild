# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit multilib-build check-reqs cuda toolchain-funcs unpacker versionator

CUDA_VERSION="$(get_version_component_range 1-2)"
PATCH_LEVEL="${PV##*_p}"
[ "${PV}" = "${PATCH_LEVEL}" ] && PATCH_LEVEL=0
MY_PV="${PV%_p*}"

# If these don't match, it means the bundled drivers are too old to use, so disable them.
DRIVER_PV="410.48"
DRIVER_MIN_PV="410.48"

# GCC versions officially supported and supported by gcc-version-hack.
CUDA_SUPPORTED_GCC="4.7 4.8 4.9 5.3 5.4 6.3 6.4 6.5 7.2 7.3"
CUDA_UNSUPPORTED_GCC="8.1 8.2 8.3"

CUDA_PKGNAME="cuda_${MY_PV}_${DRIVER_PV}_linux"

DESCRIPTION="NVIDIA CUDA Toolkit (compiler and friends)"
HOMEPAGE="https://developer.nvidia.com/cuda-zone"

# Set the base URI for fetching packages for this version of CUDA
CUDA_URI_BASE="https://developer.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod"
[ "${CUDA_VERSION}" = "9.2" ] && CUDA_URI_BASE="${CUDA_URI_BASE}2"

SRC_URI="${CUDA_URI_BASE}/local_installers/${CUDA_PKGNAME} -> ${CUDA_PKGNAME}.run"

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

S="${WORKDIR}/myroot"
DRIVER_RUN="NVIDIA-Linux-x86_64-${DRIVER_PV}.run"

CHECKREQS_DISK_BUILD="3500M"

OPT_NVIDIA_DIR="${EPREFIX}/opt/nvidia"
OPT_NVIDIA_DISTFILES="${EPREFIX}/opt/nvidia/distfiles"
CUDA_DIR="${OPT_NVIDIA_DIR}/cuda-${CUDA_VERSION}"
ECUDA_DIR="${EPREFIX}${CUDA_DIR}"
EDCUDA_DIR="${D%/}${ECUDA_DIR}"
QA_PREBUILT="${CUDA_DIR#/}/*"
RESTRICT="strip"
pkg_setup() {
	# We don't like to run cuda_pkg_setup as it depends on us
	check-reqs_pkg_setup
}

src_unpack() {
	mkdir -p "${S}"

	# Unpack our super-package
	unpacker "${DISTDIR}/${CUDA_PKGNAME}.run"
	rm run_files/getpass

	CUDA_INST_PL="${WORKDIR}/cuda-installer.pl"

	pushd "${WORKDIR}/run_files" > /dev/null

		# Move bundled .run files installed by other packages to ${OPT_NVIDIA_DISTFILES}
		if [ "${DRIVER_PV}" = "${DRIVER_MIN_PV}" ] && use copy-bundled-drivers ; then
			mkdir -p "${S}/distfiles"
			mv "${DRIVER_RUN}" "${S}/distfiles" || die
		else
			rm "${DRIVER_RUN}" || die
		fi

		# Remove undesired run files.
		if use copy-bundled-samples ; then
			mkdir -p "${S}/distfiles"
			(set +f; mv cuda-samples*${MY_PV}-*-linux.run "${S}/distfiles" )
		else
			(set +f; rm -f cuda-samples*${MY_PV}-*-linux.run )
		fi

	popd > /dev/null

	# Unpack remaining .run files for installation
	pushd "${S}" > /dev/null
		unpacker ../run_files/*.run || die
		rm -f ../run_files/*.run || die
	popd > /dev/null
	
	# Unpack all patchs up to our patchelevel
	local my_pl=${PATCH_LEVEL}
	while [ ${my_pl} -gt 0 ] ; do
		_nv_cuda_unpack_patch "cuda_${MY_PV}.${my_pl}_linux"
		my_pl=$((my_pl-1))
	done
}

_nv_cuda_unpack_patch() {
	mkdir -p "${1}"
	pushd "${1}" > /dev/null
		unpacker "${DISTDIR}/${1}.run"
	popd > /dev/null
}

src_prepare() {

	# Remove bailout version check to support newer gcc versions
	if use gcc-version-hack ; then 
		CUDA_SUPPORTED_GCC+=" ${CUDA_UNSUPPORTED_GCC}"
		sed -e 's|#error -- unsupported GNU version.*|/* GCC version check removed */\n/*&*/|' -i "include/crt/host_config.h"
	fi

	sed \
		-e "s:CUDA_SUPPORTED_GCC:${CUDA_SUPPORTED_GCC}:g" \
		-e "s:CUDA_ROOT:${ECUDA_DIR}:g" \
		"${FILESDIR}"/cuda-config.in > "${T}"/cuda-config || die

	default
}

_nv_cuda_install_patch() {
	local op src destbase dest mydest cmd 
	while read -r op src destbase dest
	do
		case "${op}" in
			copy ) cmd="cp -af --remove-destination" ;;
			*) ewarn "Don't know to handle install_manifest operation '$op'!" ; return 1 ;;
		esac

		case "${destbase}" in
			CUDADIR ) mydest="${CUDA_DIR}/${dest}" ;;
			*) ewarn "Don't know to handle install_manifest operation '$op'!" ; return 1 ;;
		esac
		
		( set +f ; $cmd "payload"/${src} "${ED%/}${mydest}" )

	done < payload/install_manifest
}

_nv_cuda_make_pc_files() {
	local libname desc stubbed

	local _pc_dir="${EDCUDA_DIR}/pkgconfig"
	mkdir -p "${_pc_dir}" || die

	while IFS=$'\t' read -r libname desc stubbed
	do
		[ "${stubbed}" = "1" ] && stubbed="/stubs" || stubbed=""
		sed \
			-e 's|$(NAME)|'"${libname}"'|g;' \
			-e 's|$(DESCRIPTION)|'"${desc}"'|g;' \
			-e 's|$(VERSION)|'"${CUDA_VERSION}"'|g;' \
			-e 's|$(CUDAPATH)|'"${ECUDA_DIR}"'|g;' \
			-e 's|$(LIBDIR)|${cudaroot}/'"$(get_libdir)${stubbed}"'|g;' \
			"${WORKDIR}/run_files/pc_template.pc" \
			> "${_pc_dir}/${libname}-${CUDA_VERSION}.pc" || die
	done <<-EOF
		$( cat "${CUDA_INST_PL}" | sed -ne '/^my @pc_files = (/,/^);/ { s/^[[:space:]]*\[ '"'"'// ; s/ \],\?$// ; s/'"', '"'/\t/ ; s/'"', "'/\t/p  }' )
		$( use abi_x86_64 && cat "${CUDA_INST_PL}" | sed -ne '/^if ($arch eq "x86_64")/,/^else/ { s/^[[:space:]]*push(@pc_files, \[ '"'"'// ; s/ \]);$// ; s/'"', '"'/\t/ ; s/'"', "'/\t/p  }' )
		$( ! use abi_x86_64 && cat "${CUDA_INST_PL}" | sed -ne '/^[[:space:]]\+@pc_files = (/,/^);/ { s/^[[:space:]]*\[ '"'"'// ; s/ \],\?$// ; s/'"', '"'/\t/ ; s/'"', "'/\t/p  }' )
	EOF
}


src_install() {
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

