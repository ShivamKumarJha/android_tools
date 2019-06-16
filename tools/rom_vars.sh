#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/tools/colors.sh

# Exit if no arguements
if [ -z "$1" ] ; then
	echo -e "${bold}${red}Supply rom directory or system/build.prop as arguement!${nocol}"
	exit
fi

# Set variables
if [ -d "$1" ]; then
	if [ -e "$1"/system/system/build.prop ]; then
		SYSTEM_PATH="system/system"
	elif [ -e "$1"/system/build.prop ]; then
		SYSTEM_PATH="system"
	fi
	BRAND_TEMP=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | sort -u | head -n 1 )
	BRAND=${BRAND_TEMP,,}
	if [ "$BRAND" = "vivo" ]; then
		DEVICE=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.vivo.product.release.name=" | sed "s|ro.vivo.product.release.name=||g" | sort -u | head -n 1 )
	else
		DEVICE=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.product" | grep "device=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.build" | grep "product=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=target
	fi
	DESCRIPTION=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro." | grep "build.description=" | sed "s|.*=||g" | sort -u | head -n 1 )
	FINGERPRINT=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | sort -u | head -n 1 )
	if [ -z "$FINGERPRINT" ]; then
		FINGERPRINT=$DESCRIPTION
	fi
	if [ "$BRAND" = "oppo" ] || [ "$BRAND" = "realme" ]; then
		MODEL=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.oppo.market.name=" | sed "s|ro.oppo.market.name=||g" | sort -u | head -n 1 )
	fi
	if [ -z "$MODEL" ]; then
		MODEL=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.product" | grep "model=" | sed "s|.*=||g" | sort -u | head -n 1 )
	fi
	VERSION=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "build.version.release=" | sed "s|.*=||g" | head -c 2 | sort -u | head -n 1 )
else
	BRAND_TEMP=$( cat "$1" | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | sort -u | head -n 1 )
	BRAND=${BRAND_TEMP,,}
	if [ "$BRAND" = "vivo" ]; then
		DEVICE=$( cat "$1" | grep "ro.vivo.product.release.name=" | sed "s|ro.vivo.product.release.name=||g" | sort -u | head -n 1 )
	else
		DEVICE=$( cat "$1" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=$( cat "$1" | grep "ro.build" | grep "product=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=target
	fi
	DESCRIPTION=$( cat "$1" | grep "ro." | grep "build.description=" | sed "s|.*=||g" | sort -u | head -n 1 )
	FINGERPRINT=$( cat "$1" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | sort -u | head -n 1 )
	if [ -z "$FINGERPRINT" ]; then
		FINGERPRINT=$DESCRIPTION
	fi
	if [ "$BRAND" = "oppo" ] || [ "$BRAND" = "realme" ]; then
		MODEL=$( cat "$1" | grep "ro.oppo.market.name=" | sed "s|ro.oppo.market.name=||g" | sort -u | head -n 1 )
	fi
	if [ -z "$MODEL" ]; then
		MODEL=$( cat "$1" | grep "ro.product" | grep "model=" | sed "s|.*=||g" | sort -u | head -n 1 )
	fi
	VERSION=$( cat "$1" | grep "build.version.release=" | sed "s|.*=||g" | head -c 2 | sort -u | head -n 1 )
fi
echo -e "${bold}${cyan}BRAND: ${BRAND} ${nocol}"
echo -e "${bold}${cyan}DEVICE: ${DEVICE} ${nocol}"
echo -e "${bold}${cyan}DESCRIPTION: ${DESCRIPTION} ${nocol}"
echo -e "${bold}${cyan}FINGERPRINT: ${FINGERPRINT} ${nocol}"
echo -e "${bold}${cyan}MODEL: ${MODEL} ${nocol}"
echo -e "${bold}${cyan}VERSION: ${VERSION} ${nocol}"
