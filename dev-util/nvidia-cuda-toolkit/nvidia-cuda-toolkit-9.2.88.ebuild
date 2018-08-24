# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit multilib-build check-reqs cuda toolchain-funcs unpacker versionator

CUDA_VERSION="$(get_version_component_range 1-2)"
DRIVER_PV="396.26"

CUDA_PKGNAME="cuda_${PV}_${DRIVER_PV}_linux"
CUDA_PATCH1="cuda_${PV}.1_linux"

DESCRIPTION="NVIDIA CUDA Toolkit (compiler and friends)"
HOMEPAGE="https://developer.nvidia.com/cuda-zone"
SRC_URI="
	https://developer.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod/local_installers/${CUDA_PKGNAME} -> ${CUDA_PKGNAME}.run
	https://developer.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod/patches/1/${CUDA_PATCH1} -> ${CUDA_PATCH1}.run
"
SLOT="${CUDA_VERSION}/${PV}"
LICENSE="NVIDIA-CUDA"
KEYWORDS="-* ~amd64 ~amd64-linux"
IUSE="debugger doc eclipse profiler drivers samples +gcc-version-hack"

DEPEND=""
RDEPEND="${DEPEND}
	>=sys-devel/gcc-4.7[cxx]
	!gcc-version-hack? ( <sys-devel/gcc-8[cxx] )
	gcc-version-hack? ( <sys-devel/gcc-9[cxx] )
	>=x11-drivers/nvidia-drivers-${DRIVER_PV}[X,uvm]
	debugger? (
		sys-libs/libtermcap-compat
		sys-libs/ncurses:5/5[tinfo]
		)
	eclipse? ( >=virtual/jre-1.6 )
	profiler? ( >=virtual/jre-1.6 )"

S="${WORKDIR}/myroot"
DRIVER_S="${WORKDIR}/nvidia-drivers-${DRIVER_PV}"
DRIVER_RUN="NVIDIA-Linux-x86_64-${DRIVER_PV}.run"

CHECKREQS_DISK_BUILD="3500M"
CUDA_DIR="/opt/cuda-${CUDA_VERSION}"
ECUDA_DIR="${EPREFIX}${CUDA_DIR}"
EDCUDA_DIR="${D%/}${ECUDA_DIR}"
QA_PREBUILT="${CUDA_DIR#/}/*"

pkg_setup() {
	# We don't like to run cuda_pkg_setup as it depends on us
	check-reqs_pkg_setup
}

src_unpack() {
	mkdir -p "${S}"
	unpacker "${DISTDIR}/${CUDA_PKGNAME}.run"
	rm run_files/getpass
	CUDA_INST_PL="${WORKDIR}/cuda-installer.pl"

	# Delete unneeded runfiles
	if	use drivers ; then
		mkdir "${DRIVER_S}" || die
		pushd "${DRIVER_S}" > /dev/null
			unpacker ../run_files/${DRIVER_RUN}
		popd > /dev/null
	fi
	
	rm "${WORKDIR}/run_files/${DRIVER_RUN}" || die

	use samples || $(set +f ; rm "${WORKDIR}/run_files"/cuda-samples.${PV}-*-linux.run) || die

	pushd "${S}" > /dev/null
		unpacker ../run_files/*.run || die
		rm -f ../run_files/*.run || die
	popd > /dev/null

	_nv_cuda_unpack_patch "${CUDA_PATCH1}"
}

_nv_cuda_unpack_patch() {
	mkdir -p "${1}"
	pushd "${1}" > /dev/null
		unpacker "${DISTDIR}/${1}.run"
	popd > /dev/null
}

src_prepare() {
	local cuda_supported_gcc

	cuda_supported_gcc="4.7 4.8 4.9 5.3 5.4 6.3 6.4 7.2 7.3"

	# Remove bailout version check to support gcc 8.1
	if use gcc-version-hack ; then 
		cuda_supported_gcc+=" 8.1"
		sed -e 's|#error -- unsupported GNU version.*|/* GCC version check removed */\n/*&*/|' -i "include/crt/host_config.h"
	fi

	sed \
		-e "s:CUDA_SUPPORTED_GCC:${cuda_supported_gcc}:g" \
		"${FILESDIR}"/cuda-config.in > "${T}"/cuda-config || die

	default
}

_nv_cuda_install_patch() {
	local op src destbase dest mydest cmd 
	while read -r op src destbase dest
	do
		case "${op}" in
			copy ) cmd="cp -r" ;;
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

	if use doc; then
		DOCS+=( doc/pdf/. )
		HTML_DOCS+=( doc/html/. )
	else
		remove+=( doc )
	fi
	einstalldocs

	mv doc/man/man3/{,cuda-}deprecated.3 || die
	doman doc/man/man*/*

	use debugger || remove+=( bin/cuda-gdb extras/Debugger extras/cuda-gdb-${PV}.src.tar.gz )

	if use profiler; then
		# hack found in install-linux.pl
		for i in nvvp nsight; do
			cat > bin/${i} <<- EOF || die
				#!/usr/bin/env sh
				LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:${ECUDA_DIR}/lib:${ECUDA_DIR}/lib64 \
					UBUNTU_MENUPROXY=0 LIBOVERLAY_SCROLLBAR=0 \
					${ECUDA_DIR}/lib${i}/${i} -vm ${EPREFIX}/usr/bin/java
			EOF
			chmod a+x bin/${i} || die
		done
	else
		use eclipse || remove+=( libnvvp libnsight )
		remove+=( extras/CUPTI )
	fi

	for i in "${remove[@]}"; do
		ebegin "Cleaning ${i}..."
		rm -rf "${i}" || die
		eend
	done

	dodir ${CUDA_DIR}
	mv * "${EDCUDA_DIR}" || die

	cat > "${T}"/99cuda <<- EOF || die
		PATH=${ECUDA_DIR}/bin$(usex profiler ":${ECUDA_DIR}/libnvvp" "")
		ROOTPATH=${ECUDA_DIR}/bin
		LDPATH=${ECUDA_DIR}/lib64:${ECUDA_DIR}/lib:${ECUDA_DIR}/nvvm/lib64
	EOF
	doenvd "${T}"/99cuda

	use profiler && \
		make_wrapper nvprof "${ECUDA_DIR}/bin/nvprof" "." "${ECUDA_DIR}/lib64:${ECUDA_DIR}/lib"


	if [ -d "${WORKDIR}/${CUDA_PATCH1}" ] ; then
		pushd "${WORKDIR}/${CUDA_PATCH1}" > /dev/null
			_nv_cuda_install_patch
		popd > /dev/null
	fi

	_nv_cuda_make_pc_files

	dobin "${T}"/cuda-config
}

pkg_postinst_check() {
	local a b
	a="$(version_sort $(cuda-config -s))"; a=( $a )
	# greatest supported version
	b="${a[${#a[@]}-1]}"

	# if gcc and if not gcc-version is at least greatest supported
	if tc-is-gcc && \
		! version_is_at_least gcc-version ${b}; then
			ewarn ""
			ewarn "gcc >= ${b} will not work with CUDA"
			ewarn "Make sure you set an earlier version of gcc with gcc-config"
			ewarn "or append --compiler-bindir= pointing to a gcc bindir like"
			ewarn "--compiler-bindir=${EPREFIX}/usr/*pc-linux-gnu/gcc-bin/gcc${b}"
			ewarn "to the nvcc compiler flags"
			ewarn ""
	fi
}

pkg_postinst() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		pkg_postinst_check
	fi
}

