
if [ -f nvidia-drivers-xxx.xx-r2.template ] ; then
	for eb in *-r2.ebuild ; do cp nvidia-drivers-xxx.xx-r2.template "${eb}" ; done
else
	printf 'Could not find "nvidia-drivers-xxx.xx-r2.template" in current directory.\n'
	printf 'Please run tools/'"$0"' from x11-drivers/nvidia-drivers directory.\n'
fi
