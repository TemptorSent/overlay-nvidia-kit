
latestdrivers="$(sh list_latest_drivers_per_branch.sh)"
lateststable="$(sh get_latest_stable.sh)"
newestdriver="$(printf -- '%s\n' ${latestdrivers} | tail -1)"
printf -- '%s\n' ${latestdrivers} ${lateststable} | grep -F "$( (sh get_driver_supported_pciids.sh ${newestdriver}; printf '%s\n' ${lateststable} ) | cut -f1 | sort -u)" | sort -uV
