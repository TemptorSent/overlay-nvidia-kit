
get_latest_driver_for_pciid_from_supported_pciids() {
	awk '
		BEGIN {
			FS="\t";
			device="'"${1}"'";
			subvendor="'"${2}"'";
			subdevice="'"${3}"'";
			devid="devid" device;
			devid_full=devid;
			devidex="^" devid;
			if (! subvendor == "" ) {
				devid_full=devid "_" subvendor "_" subdevice;
			};
		};

		$2 == devid_full { driver=$1 ; exit};
		$2 ~devidex {
			if(!driver) { driver=$1; }
		};
		
		END { print driver; };'
}
latest="$(sh list_latest_drivers_per_branch.sh | tail -1)"
if [ "${1}" == "--stable" ] ; then stable="$(sh get_latest_stable.sh)" ; shift ; fi
sh get_driver_supported_pciids.sh ${stable:-${latest}} \
	| get_latest_driver_for_pciid_from_supported_pciids "${@}"
