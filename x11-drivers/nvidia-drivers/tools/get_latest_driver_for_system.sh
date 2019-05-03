OIFS=$IFS
IFS="\n"; for pciid in $(sh get_system_pciids.sh  --with-class=03 10de) ; do
	IFS=$OIFS
	mydriver="$(sh get_latest_driver_for_pciid.sh ${pciid#* })"
	[ -n "${mydriver}" ] && printf -- '%s\n' "${mydriver}"
done
