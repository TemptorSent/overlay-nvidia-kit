curl -s "https://download.nvidia.com/XFree86/${1-Linux-x86_64}/" \
	| awk '
		/<a href='"'"'[0-9]+\.[0-9]+/ {
			gsub(/[[:space:]]*<[^>]+>/,"");
			gsub(/\/.*/,"");
			ver=$0;
			gsub(/\..*/,"");
			driver[$0]=ver;
		};

		END {
			for(d in driver) {
				print driver[d];
			};
		};'

