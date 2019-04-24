
if [ -f nvidia-drivers-xxx.xx-r2.template ] ; then
	for eb in *-r2.ebuild ; do
		cp nvidia-drivers-xxx.xx-r2.template "${eb}"
		case "${eb}" in
			# Latest beta supporting GF600+
			*-430.09-*) mymaxkv="5.1" ;;
			# Latest long-lived branch supporting GF600+
			*-418.56-*) mymaxkv="5.1" ;;
			# Current short-lived branch supporting GF600+
			*-415.27-*) mymaxkv="4.20" ;;
			# Previous long-lived branch supporting GF600+
			*-410.104-*) mymaxkv="5.0" ;;
			# Legacy branch supporting GF400+
			*-390.116-*) mymaxkv="5.0" ;;
		esac
		sed -e 's/\(: "${NV_MAX_KERNEL_VERSION:=\)\(.*\)\(}"\)/\1'"${mymaxkv:-5.0}"'\3/' -i "${eb}"
	done
else
	printf 'Could not find "nvidia-drivers-xxx.xx-r2.template" in current directory.\n'
	printf 'Please run tools/'"$0"' from x11-drivers/nvidia-drivers directory.\n'
fi
