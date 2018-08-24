# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: nvidia-driver.eclass
# @MAINTAINER:
# Jeroen Roovers <jer@gentoo.org>
# @AUTHOR:
# Original author: Doug Goldstein <cardoe@gentoo.org>
# @BLURB: Provide useful messages for nvidia-drivers based on currently installed Nvidia card
# @DESCRIPTION:
# Provide useful messages for nvidia-drivers based on currently installed Nvidia
# card. It inherits versionator.

inherit readme.gentoo-r1 versionator

DEPEND="sys-apps/pciutils"

# Variables for readme.gentoo.eclass:
DISABLE_AUTOFORMATTING="yes"
DOC_CONTENTS="You must be in the video group to use the NVIDIA device
For more info, read the docs at
https://www.gentoo.org/doc/en/nvidia-guide.xml#doc_chap3_sect6

This ebuild installs a kernel module and X driver. Both must
match explicitly in their version. This means, if you restart
X, you must modprobe -r nvidia before starting it back up

To use the NVIDIA GLX, run \"eselect opengl set nvidia\"

To use the NVIDIA CUDA/OpenCL, run \"eselect opencl set nvidia\"

NVIDIA has requested that any bug reports submitted have the
output of nvidia-bug-report.sh included.
"

# the data below is derived from
# http://us.download.nvidia.com/XFree86/Linux-x86_64/396.24/README/supportedchips.html

drv_396_xx_pciids="0FC0 0FC1 0FC2 0FC6 0FC8 0FC9 0FCD 0FCE 0FD1 0FD2 0FD3 0FD4 0FD5 0FD8 0FD9 0FDF 0FE0 0FE1 0FE2 0FE3 0FE4 0FE9 0FEA 0FEC 0FED 0FEE 0FF3 0FF6 0FF8 0FF9 0FFA 0FFB 0FFC 0FFD 0FFE 0FFF 1001 1004 1005 1007 1008 100A 100C 1021 1022 1023 1024 1026 1027 1028 1029 102A 102D 103A 103C 1180 1183 1184 1185 1187 1188 1189 118A 118E 118F 1193 1194 1195 1198 1199 119A 119D 119E 119F 11A0 11A1 11A2 11A3 11A7 11B4 11B6 11B7 11B8 11BA 11BC 11BD 11BE 11C0 11C2 11C3 11C4 11C5 11C6 11C8 11CB 11E0 11E1 11E2 11E3 11FA 11FC 1280 1281 1282 1284 1286 1287 1288 1289 128B 1290 1291 1292 1293 1295 1296 1298 1299 129A 12B9 12BA 1340 1341 1344 1346 1347 1348 1349 134B 134D 134E 134F 137A 137B 137D 1380 1381 1382 1390 1391 1392 1393 1398 1399 139A 139B 139C 139D 13B0 13B1 13B2 13B3 13B4 13B6 13B9 13BA 13BB 13BC 13C0 13C2 13D7 13D8 13D9 13DA 13F0 13F1 13F2 13F3 13F8 13F9 13FA 13FB 1401 1402 1406 1407 1427 1430 1431 1436 15F0 15F7 15F8 15F9 1617 1618 1619 161A 1667 174D 174E 179C 17C2 17C8 17F0 17F1 17FD 1B00 1B02 1B06 1B30 1B38 1B80 1B81 1B82 1B84 1B87 1BA0 1BA1 1BB0 1BB1 1BB3 1BB4 1BB5 1BB6 1BB7 1BB8 1BB9 1BBB 1BC7 1BE0 1BE1 1C02 1C03 1C04 1C06 1C07 1C09 1C20 1C21 1C22 1C30 1C60 1C61 1C62 1C81 1C82 1C8C 1C8D 1CB1 1CB2 1CB3 1CB6 1CBA 1CBB 1CBC 1D01 1D10 1D12 1D33 1D81 1DB1 1DB3 1DB4 1DB5 1DB6 1DB7 1DBA"

drv_390_xx_pciids="06C0 06C4 06CA 06CD 06D1 06D2 06D8 06D9 06DA 06DC 06DD 06DE 06DF 0DC0 0DC4 0DC5 0DC6 0DCD 0DCE 0DD1 0DD2 0DD3 0DD6 0DD8 0DDA 0DE0 0DE1 0DE2 0DE3 0DE4 0DE5 0DE7 0DE8 0DE9 0DEA 0DEB 0DEC 0DED 0DEE 0DEF 0DF0 0DF1 0DF2 0DF3 0DF4 0DF5 0DF6 0DF7 0DF8 0DF9 0DFA 0DFC 0E22 0E23 0E24 0E30 0E31 0E3A 0E3B 0F00 0F01 0F02 0F03 1040 1042 1048 1049 104A 104B 104C 1050 1051 1052 1054 1055 1056 1057 1058 1059 105A 105B 107C 107D 1080 1081 1082 1084 1086 1087 1088 1089 108B 1091 1094 1096 109A 109B 1140 1200 1201 1203 1205 1206 1207 1208 1210 1211 1212 1213 1241 1243 1244 1245 1246 1247 1248 1249 124B 124D 1251"

drv_367_xx_pciids="0FEF 0FF2 11BF"

drv_340_xx_pciids="0191 0193 0194 0197 019D 019E 0400 0401 0402 0403 0404 0405 0406 0407 0408 0409 040A 040B 040C 040D 040E 040F 0410 0420 0421 0422 0423 0424 0425 0426 0427 0428 0429 042A 042B 042C 042D 042E 042F 05E0 05E1 05E2 05E3 05E6 05E7 05EA 05EB 05ED 05F8 05F9 05FD 05FE 05FF 0600 0601 0602 0603 0604 0605 0606 0607 0608 0609 060A 060B 060C 060D 060F 0610 0611 0612 0613 0614 0615 0617 0618 0619 061A 061B 061C 061D 061E 061F 0621 0622 0623 0625 0626 0627 0628 062A 062B 062C 062D 062E 0630 0631 0632 0635 0637 0638 063A 0640 0641 0643 0644 0645 0646 0647 0648 0649 064A 064B 064C 0651 0652 0653 0654 0655 0656 0658 0659 065A 065B 065C 06E0 06E1 06E2 06E3 06E4 06E5 06E6 06E7 06E8 06E9 06EA 06EB 06EC 06EF 06F1 06F8 06F9 06FA 06FB 06FD 06FF 0840 0844 0845 0846 0847 0848 0849 084A 084B 084C 084D 084F 0860 0861 0862 0863 0864 0865 0866 0867 0868 0869 086A 086C 086D 086E 086F 0870 0871 0872 0873 0874 0876 087A 087D 087E 087F 08A0 08A2 08A3 08A4 08A5 0A20 0A22 0A23 0A26 0A27 0A28 0A29 0A2A 0A2B 0A2C 0A2D 0A32 0A34 0A35 0A38 0A3C 0A60 0A62 0A63 0A64 0A65 0A66 0A67 0A68 0A69 0A6A 0A6C 0A6E 0A6F 0A70 0A71 0A72 0A73 0A74 0A75 0A76 0A78 0A7A 0A7C 0CA0 0CA2 0CA3 0CA4 0CA5 0CA7 0CA8 0CA9 0CAC 0CAF 0CB0 0CB1 0CBC 10C0 10C3 10C5 10D8"

drv_304_xx_pciids="0040 0041 0042 0043 0044 0045 0046 0047 0048 004E 0090 0091 0092 0093 0095 0098 0099 009D 00C0 00C1 00C2 00C3 00C8 00C9 00CC 00CD 00CE 00F1 00F2 00F3 00F4 00F5 00F6 00F8 00F9 0140 0141 0142 0143 0144 0145 0146 0147 0148 0149 014A 014C 014D 014E 014F 0160 0161 0162 0163 0164 0165 0166 0167 0168 0169 016A 01D0 01D1 01D2 01D3 01D6 01D7 01D8 01DA 01DB 01DC 01DD 01DE 01DF 0211 0212 0215 0218 0221 0222 0240 0241 0242 0244 0245 0247 0290 0291 0292 0293 0294 0295 0297 0298 0299 029A 029B 029C 029D 029E 029F 02E0 02E1 02E2 02E3 02E4 038B 0390 0391 0392 0393 0394 0395 0397 0398 0399 039C 039E 03D0 03D1 03D2 03D5 03D6 0531 0533 053A 053B 053E 07E0 07E1 07E2 07E3 07E5"

drv_173_14_xx_pciids="00FA 00FB 00FC 00FD 00FE 0301 0302 0308 0309 0311 0312 0314 031A 031B 031C 0320 0321 0322 0323 0324 0325 0326 0327 0328 032A 032B 032C 032D 0330 0331 0332 0333 0334 0338 033F 0341 0342 0343 0344 0347 0348 034C 034E"

drv_96_43_xx_pciids="0110 0111 0112 0113 0170 0171 0172 0173 0174 0175 0176 0177 0178 0179 017A 017C 017D 0181 0182 0183 0185 0188 018A 018B 018C 01A0 01F0 0200 0201 0202 0203 0250 0251 0253 0258 0259 025B 0280 0281 0282 0286 0288 0289 028C"

drv_71_86_xx_pciids="0020 0028 0029 002C 002D 00A0 0100 0101 0103 0150 0151 0152 0153"


mask_71_xx=">=x11-drivers/nvidia-drivers-72.0.0"
mask_96_xx=">=x11-drivers/nvidia-drivers-97.0.0"
mask_173_xx=">=x11-drivers/nvidia-drivers-177.0.0"
mask_304_xx=">=x11-drivers/nvidia-drivers-305.0.0"
mask_340_xx=">=x11-drivers/nvidia-drivers-341.0.0"
mask_367_xx=">=x11-drivers/nvidia-drivers-368.0.0"
mask_390_xx=">=x11-drivers/nvidia-drivers-391.0.0"

# @FUNCTION: nvidia-driver-get-card
# @DESCRIPTION:
# Retrieve the PCI device ID for each Nvidia video card you have
nvidia-driver-get-card() {
	local NVIDIA_CARD=$(
		[ -x /usr/sbin/lspci ] && /usr/sbin/lspci -d 10de: -n \
			| awk -F'[: ]' '/ 0300: /{print $6}'
	)

	if [ -n "${NVIDIA_CARD}" ]; then
		echo "${NVIDIA_CARD}"
	else
		echo 0000
	fi
}

nvidia-driver-get-mask() {
	local NVIDIA_CARDS="$(nvidia-driver-get-card)"
	local card drv

	for card in ${NVIDIA_CARDS}; do
		for drv in ${drv_71_86_xx_pciids}; do
			if [ "x${card}" = "x${drv}" ]; then
				echo "${mask_71_xx}"
				return 0
			fi
		done

		for drv in ${drv_96_43_xx_pciids}; do
			if [ "x${card}" = "x${drv}" ]; then
				echo "${mask_96_xx}"
				return 0
			fi
		done

		for drv in ${drv_173_14_xx_pciids}; do
			if [ "x${card}" = "x${drv}" ]; then
				echo "${mask_173_xx}"
				return 0
			fi
		done

		for drv in ${drv_304_xx_pciids}; do
			if [ "x${card}" = "x${drv}" ]; then
				echo "${mask_304_xx}"
				return 0
			fi
		done

		for drv in ${drv_340_xx_pciids}; do
			if [ "x${card}" = "x${drv}" ]; then
				echo "${mask_340_xx}"
				return 0
			fi
		done
		for drv in ${drv_367_xx_pciids}; do
			if [ "x${card}" = "x${drv}" ]; then
				echo "${mask_367_xx}"
				return 0
			fi
		done
		for drv in ${drv_390_xx_pciids}; do
			if [ "x${card}" = "x${drv}" ]; then
				echo "${mask_390_xx}"
				return 0
			fi
		done
	done

	echo ''
	return 1
}

# @FUNCTION: nvidia-driver-check-warning
# @DESCRIPTION:
# Prints out a warning if the driver does not work w/ the installed video card
nvidia-driver-check-warning() {
	local NVIDIA_MASK="$(nvidia-driver-get-mask)"

	if [ -n "${NVIDIA_MASK}" ]; then
		version_compare "${NVIDIA_MASK##*-}" "${PV}"
		if [ x"${?}" = x1 ]; then
			ewarn "***** WARNING *****"
			ewarn
			ewarn "You are currently installing a version of nvidia-drivers that is"
			ewarn "known not to work with a video card you have installed on your"
			ewarn "system. If this is intentional, please ignore this. If it is not"
			ewarn "please perform the following steps:"
			ewarn
			ewarn "Add the following mask entry to /etc/portage/package.mask by"
			if [ -d "${ROOT}/etc/portage/package.mask" ]; then
				ewarn "echo \"${NVIDIA_MASK}\" > /etc/portage/package.mask/nvidia-drivers"
			else
				ewarn "echo \"${NVIDIA_MASK}\" >> /etc/portage/package.mask"
			fi
			ewarn
			ewarn "Failure to perform the steps above could result in a non-working"
			ewarn "X setup."
			ewarn
			ewarn "For more information please read:"
			ewarn "http://www.nvidia.com/object/IO_32667.html"
		fi
	fi
}
