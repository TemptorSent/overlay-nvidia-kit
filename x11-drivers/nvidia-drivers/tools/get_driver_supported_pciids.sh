
fetch_supported_chips_for_driver() {
	local driver_ver=${1}
	local driver_arch=${2-Linux-x86_64}
	curl -s "https://download.nvidia.com/XFree86/${driver_arch}/${driver_ver}/README/supportedchips.html" \
		| extract_driver_compat_from_supportedchips_html \
		| sed -e 's/^current/'"${driver_ver%.*}"'/'
}


extract_driver_compat_from_supportedchips_html() {
	awk 'BEGIN { driver="current"; };
		/a name="legacy_/ {
			gsub(/.*legacy_/,"");
			gsub(/.xx".*/,"");
			driver=$0;
		};
		/devid/ {
			gsub(/<tr id="/, "");
			gsub(/">/,"");
			devid=$0;

			getline;
			gsub(/<\/?td>/,"");
			name=$0;

			getline;
			gsub(/<\/?td>/,"");
			pciid=$0;
			printf("%s\t%s\t%s\t%s\n",driver, devid, pciid, name);
		};'
}

fetch_supported_chips_for_driver "${@}"
