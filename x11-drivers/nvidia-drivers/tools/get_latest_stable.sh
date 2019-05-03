curl -s "https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt" \
	| awk '{ print $1; };'
