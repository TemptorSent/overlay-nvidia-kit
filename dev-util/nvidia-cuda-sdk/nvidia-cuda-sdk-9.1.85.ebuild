# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cuda eutils flag-o-matic portability toolchain-funcs unpacker versionator

CUDA_VERSION="$(get_version_component_range 1-2)"

DESCRIPTION="NVIDIA CUDA Software Development Kit"
HOMEPAGE="https://developer.nvidia.com/cuda-zone"
SRC_URI=""

LICENSE="CUDPP"
SLOT="${CUDA_VERSION}/${PV}"
KEYWORDS="~amd64 ~amd64-linux"
IUSE="+cuda debug +doc +examples +opencl mpi"

RDEPEND="
	=dev-util/nvidia-cuda-toolkit-${PV}*
	media-libs/freeglut
	examples? (
		media-libs/freeimage
		media-libs/glew:0=
		mpi? ( virtual/mpi )
	)
"
DEPEND="${RDEPEND}"

OPT_NVIDIA_DIR="${EPREFIX}/opt/nvidia"
OPT_NVIDIA_DISTFILES="${EPREFIX}/opt/nvidia/distfiles"
CUDA_DIR="${OPT_NVIDIA_DIR}/cuda-${CUDA_VERSION}"
ECUDA_DIR="${EPREFIX}${CUDA_DIR}"
EDCUDA_DIR="${D%/}${ECUDA_DIR}"

RESTRICT="test"

S=${WORKDIR}/samples

QA_EXECSTACK=(
	${CUDA_DIR#/}/sdk/0_Simple/cdpSimplePrint/cdpSimplePrint
	${CUDA_DIR#/}/sdk/0_Simple/cdpSimpleQuicksort/cdpSimpleQuicksort
	${CUDA_DIR#/}/sdk/bin/x86_64/linux/release/cdpSimplePrint
	${CUDA_DIR#/}/sdk/bin/x86_64/linux/release/cdpSimpleQuicksort
	)

src_unpack() {
	# We first need to unpack the cuda_${PV}_linux.run file
	# which includes the cuda-samples*run file.
 
	unpacker "$(ls -1v "${OPT_NVIDIA_DISTFILES}"/cuda-samples.${PV}-*-linux.run | tail -1)"
}

pkg_setup() {
	if use cuda || use opencl; then
		cuda_pkg_setup
	fi
}

src_prepare() {
	export RAWLDFLAGS="$(raw-ldflags)"
#	epatch "${FILESDIR}"/${P}-asneeded.patch

	local file
	while IFS="" read -d $'\0' -r file; do
		sed \
			-e 's:-O[23]::g' \
			-e "/LINK/s:gcc:$(tc-getCC) ${LDFLAGS}:g" \
			-e "/LINK/s:g++:$(tc-getCXX) ${LDFLAGS}:g" \
			-e "/CC/s:gcc:$(tc-getCC):g" \
			-e "/GCC/s:g++:$(tc-getCXX):g" \
			-e "/NVCC /s|\(:=\).*|:= ${ECUDA_DIR}/bin/nvcc|g" \
			-e "/ CFLAGS/s|\(:=\)|\1 ${CFLAGS}|g" \
			-e "/ CXXFLAGS/s|\(:=\)|\1 ${CXXFLAGS}|g" \
			-e "/NVCCFLAGS/s|\(:=\)|\1 ${NVCCFLAGS} |g" \
			-e 's:-Wimplicit::g' \
			-e "s|../../common/lib/linux/\$(OS_ARCH)/libGLEW.a|$($(tc-getPKG_CONFIG) --libs glew)|g" \
			-e "s|../../common/lib/\$(OSLOWER)/libGLEW.a|$($(tc-getPKG_CONFIG) --libs glew)|g" \
			-e "s|../../common/lib/\$(OSLOWER)/\$(OS_ARCH)/libGLEW.a|$($(tc-getPKG_CONFIG) --libs glew)|g" \
			-i "${file}" || die
			# -e "/ALL_LDFLAGS/s|:=|:= ${RAWLDFLAGS} |g" \
	done < <(find . -type f -name 'Makefile' -print0)

	rm -rf common/inc/GL || die
	find . -type f -name '*.a' -delete || die

	eapply_user
}

src_compile() {
	use examples || return
	local myopts=("verbose=1")
	use debug && myopts+=("dbg=1")
	export FAKEROOTKEY=1 # Workaround sandbox issue in #462602
	emake \
		cuda-install="${ECUDA_DIR}" \
		CUDA_PATH="${ECUDA_DIR}" \
		MPI_GCC=10 \
		"${myopts[@]}"
}

src_test() {
	addwrite /dev/nvidiactl
	addwrite /dev/nvidia0

	local i
	for i in {0..9}*/*; do
		emake -C "${i}" run
	done
}

src_install() {
	local f t
	if ! use doc ; then
		ebegin "Removing pdf docs due to '-doc' USE flag."
			find -type f -name '*.pdf' -delete || die
		eend
	fi

	ebegin "Cleaning before installation..."
		find -type f -name '*.o' -delete || die
	eend

	ebegin "Moving files..."
		while IFS="" read -d $'\0' -r f; do
			t="$(dirname ${f})"
			if [[ ${t/obj\/} != ${t} || ${t##*.} == a ]]; then
				continue
			fi
			if [[ -x ${f} ]]; then
				exeinto "${CUDA_DIR}/sdk/${t}"
				doexe "${f}"
			else
				insinto "${CUDA_DIR}/sdk/${t}"
				doins "${f}"
			fi
		done < <(find . -type f -print0)
	eend
}
