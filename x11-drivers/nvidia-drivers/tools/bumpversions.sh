
die() {
	[ $# -gt 0 ] && printf -- '%s\n' "${@}"
	exit 1
}

_chk_cp_digest() {
	dir="${1%/}"
	old="${2}"
	new="${3}"
	[ -d "${dir}" ] || die "Directory '${dir}' does not exist."
	[ -f "${dir}/${old}" ] || die "Source file '${dir}/${old}' does not exist."
	if [ -f "${dir}/${new}" ] ; then
		printf -- "Desitnation file '${dir}/${new}' already exists, skipping.\n"
	else
		printf -- "Copy '${dir}/${old}' -> '${dir}/${new}'\n"
		cp "${dir}/${old}" "${dir}/${new}" || die "Copy failed."
		printf -- "Updating manifest.\n"
		( cd "${dir}" && ebuild "${new}" digest ) || die "Could not update Manifest in '${dir}'."
	fi

}



if [ $# -ne 2 ] ; then
	printf -- "Usage: %s <old version> <new version>\n" "${0}"
else
	oldver="${1}"
	newver="${2}"
	_chk_cp_digest ../../x11-drivers/nvidia-drivers nvidia-drivers-{${oldver},${newver}}-r2.ebuild
	_chk_cp_digest ../../x11-drivers/nvidia-kernel-modules nvidia-kernel-modules-{${oldver},${newver}}.ebuild
	_chk_cp_digest ../../media-video/nvidia-settings nvidia-settings-{${oldver},${newver}}.ebuild
fi
