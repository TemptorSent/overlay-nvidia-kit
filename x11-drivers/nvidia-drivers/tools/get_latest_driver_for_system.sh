IFS="\n"
for pciid in $(sh get_system_pciids.sh  --with-class=03 10de) ; do
	sh get_latest_driver_for_pciid.sh "${pciid#* }";
done
