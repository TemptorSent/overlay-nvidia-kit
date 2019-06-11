die() {
	[ $# -gt 0 ] && printf -- '%s\n' "${@}"
	exit 1
}

_get_eb_max_kv() {
	local mymaxkv=5.0
	case "${1}" in
		# Latest stable supporting GF600+
		*-430.14-*|*-430.26-*) mymaxkv="5.1" ;;
		# Beta supporting GF600+
		*-430.09-*) mymaxkv="5.1" ;;
		# Latest long-lived branch supporting GF600+
		*-418.74-*) mymaxkv="5.1" ;;
		*-418.56-*) mymaxkv="5.1" ;;
		# Previous short-lived branch supporting GF600+
		*-415.27-*) mymaxkv="4.20" ;;
		# Previous long-lived branch supporting GF600+
		*-410.104-*) mymaxkv="5.0" ;;
		# Legacy branch supporting GF400+
		*-390.116-*) mymaxkv="5.0" ;;
		# Legacy branch supporting GeForce 8+ to GeForce 700/800M/GTX-TITAN
		*-340.107-*) mymaxkv="4.20" ;;
	esac
	printf -- '%s' "${mymaxkv}"
}

update_ebuilds_from_template() {
	local dir="${1}"
	local template="${2}"
	local rev="${3}"
	local suffix="${rev:+-r${rev}}.ebuild"
	local maxkv

	[ -d "${dir}" ] || die "Directory '${dir}' does not exist\nPlease run 'sh tools/${0##*/}' from the x11-drivers/nvidia-drivers directory."
	[ -f "${dir}/${template}" ] || die "Template '${dir}/${template}' does not exist\nPlease run 'sh tools/${0##*/}' from the x11-drivers/nvidia-drivers directory."
	(
		cd "${dir}" || die "Could not change to '${dir}'."
		for eb in *${suffix} ; do
			maxkv="$(_get_eb_max_kv "${eb}")"
			[ -n "${eb}" ] && [ "${eb}" != "*${suffix}" ] || continue
			printf -- "Copying template '${template}' to '${eb}'.\n"
			cp "${template}" "${eb}" || die "Could not copy '${template}' -> '${eb}' in '${dir}'."
			printf -- "Setting max kernel version to '${maxkv}' for '${eb}'.\n"
			sed -e 's/\(: "${NV_MAX_KERNEL_VERSION:=\)\(.*\)\(}"\)/\1'"${maxkv}"'\3/' -i "${eb}" || die "sed command to update max kernel version failed for '${eb}' in '${dir}'."
		done
	)
}

update_ebuilds_from_template "../../x11-drivers/nvidia-drivers" "nvidia-drivers-xxx.xx-r2.template" "2"
update_ebuilds_from_template "../../x11-drivers/nvidia-kernel-modules" "nvidia-kernel-modules-xxx.xx.template"

