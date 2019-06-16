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
	echo -e "${bold}${red}Supply dir's as arguements!${nocol}"
	exit
fi

# Set variables
if [ -e "$1"/system/system/build.prop ]; then
	SYSTEM_PATH="system/system"
elif [ -e "$1"/system/build.prop ]; then
	SYSTEM_PATH="system"
fi
BRAND_TEMP=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.product.brand=" | sed "s|ro.product.brand=||g" | sort -u | head -n 1 )
BRAND=${BRAND_TEMP,,}
if [ "$BRAND" = "vivo" ]; then
	DEVICE=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.vivo.product.release.name=" | sed "s|ro.vivo.product.release.name=||g" | sort -u | head -n 1 )
else
	DEVICE=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.product.device=" | sed "s|ro.product.device=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
fi
if [ -z "$DEVICE" ]; then
	DEVICE=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.build.product=" | sed "s|ro.build.product=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
fi
if [ -z "$DEVICE" ]; then
	DEVICE=target
fi
DESCRIPTION=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.build.description=" | sed "s|ro.build.description=||g" | sort -u | head -n 1 )
FINGERPRINT=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.build.fingerprint=" | sed "s|ro.build.fingerprint=||g" | sort -u | head -n 1 )
if [ -z "$FINGERPRINT" ]; then
	FINGERPRINT=$DESCRIPTION
fi
if [ "$BRAND" = "oppo" ] || [ "$BRAND" = "realme" ]; then
	MODEL=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.oppo.market.name=" | sed "s|ro.oppo.market.name=||g" | sort -u | head -n 1 )
else
	MODEL=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.product.model=" | sed "s|ro.product.model=||g" | sort -u | head -n 1 )
fi
VERSION=$( cat "$1"/"$SYSTEM_PATH"/build*.prop | grep "ro.build.version.release=" | sed "s|ro.build.version.release=||g" | head -c 1 | sort -u | head -n 1 )

echo -e "${bold}${cyan}BRAND: ${BRAND} ${nocol}"
echo -e "${bold}${cyan}DEVICE: ${DEVICE} ${nocol}"
echo -e "${bold}${cyan}DESCRIPTION: ${DESCRIPTION} ${nocol}"
echo -e "${bold}${cyan}FINGERPRINT: ${FINGERPRINT} ${nocol}"
echo -e "${bold}${cyan}MODEL: ${MODEL} ${nocol}"
echo -e "${bold}${cyan}VERSION: ${VERSION} ${nocol}"
