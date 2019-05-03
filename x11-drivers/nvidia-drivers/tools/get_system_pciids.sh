


extract_lscpi_pciids() {

	local slot class vendor device subvendor subdevice
	local show_slot show_class
	while [ $# -gt 0 ] ; do
		opt="${1}"
		opt="$(printf -- "${opt}" | tr 'A-Z' 'a-z')"
		case "${opt}" in
			--show-slot) local show_slot="1" ;;
			--with-slot*) local slot="${opt#--with-slot=}" ;;
			--show-class) local show_class="1" ;;
			--with-class*) local class="${opt#--with-class=}" ;;
			--*) : ;;
			*)  if [ -z "${vendor}" ] ; then vendor="${opt}"
				elif [ -z "${device}" ] ; then device="${opt}"
				elif [ -z "${subvendor}" ] ; then subvendor="${opt}"
				elif [ -z "${subdevice}" ] ; then subdevice="${opt}"
				fi
			;;
		esac
		shift
	done

	awk '
		{
			gsub(/-[^[:space:]]+[[:space:]]/, "");
			gsub(/"/,"");
			slot=$1
			class=$2
			vendor=$3
			device=$4
			subvendor=$5
			subdevice=$6

		};
		slot ~ /^'"${slot}"'/ && class ~ /^'"${class}"'/ && vendor ~/^'"${vendor}"'/ && device ~/^'"${device}"'/ && subvendor ~ /^'"${subvendor}"'/ && subdevice ~ /^'"${subdevice}"'/ {
			print '"${show_slot:+slot,}${show_class:+class,}"'vendor,device,subvendor,subdevice;
		};'
}

PATH="${PATH}:/usr/sbin:/sbin" lspci -mm -n | extract_lscpi_pciids "${@}"

# '"${myslot:+slot ~ /${myslot}/${vendor:+ && }}${vendor:+vendor ~/${vendor}/${device:+ && device ~/${device}/${subvendor:+ && subvendor ~ /${subvendor}/${subdevice:+ && subdevice ~ /${subdevice}/}}}}"' {
