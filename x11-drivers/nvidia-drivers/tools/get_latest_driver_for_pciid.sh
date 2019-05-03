
get_latest_driver_for_pciid_from_supported_pciids() {
	awk '
		BEGIN {
			FS="\t";
			device="'"${1}"'";
			subvendor="'"${2}"'";
			subdevice="'"${3}"'";
			devid="devid" device;
			devid_full=devid;
			if (subvendor != "") {
				devid_full=devid "_" subvendor "_" subdevice;
			};
		};

		$2 == devid {
			if(!driver) { driver=$1; }
		};

		$2 == devid_full { driver=$1 ; exit};
		
		END { print driver; };'
}

sh get_driver_supported_pciids.sh $(sh list_latest_drivers_per_branch.sh | tail -1) \
	| get_latest_driver_for_pciid_from_supported_pciids "${@}"
