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

# Dir or file handling
if [ -d "$1" ]; then
	if [ -e "$1"/system/system/build.prop ]; then
		SYSTEM_PATH="system/system"
	elif [ -e "$1"/system/build.prop ]; then
		SYSTEM_PATH="system"
	fi
	CAT_FILE=""$1"/"$SYSTEM_PATH"/build.prop"
else
	CAT_FILE="$1"
fi

# Set variables
BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | sort -u | head -n 1 )
BRAND=${BRAND_TEMP,,}
if [ "$BRAND" = "vivo" ]; then
	DEVICE=$( cat "$CAT_FILE" | grep "ro.vivo.product.release.name=" | sed "s|ro.vivo.product.release.name=||g" | sort -u | head -n 1 )
else
	DEVICE=$( cat "$CAT_FILE" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
fi
if [ -z "$DEVICE" ]; then
	DEVICE=$( cat "$CAT_FILE" | grep "ro.build" | grep "product=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
fi
if [ -z "$DEVICE" ]; then
	DEVICE=target
fi
DESCRIPTION=$( cat "$CAT_FILE" | grep "ro." | grep "build.description=" | sed "s|.*=||g" | sort -u | head -n 1 )
FINGERPRINT=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | sort -u | head -n 1 )
if [ -z "$FINGERPRINT" ]; then
	FINGERPRINT=$DESCRIPTION
fi
if [ "$BRAND" = "oppo" ] || [ "$BRAND" = "realme" ]; then
	MODEL=$( cat "$CAT_FILE" | grep "ro.oppo.market.name=" | sed "s|ro.oppo.market.name=||g" | sort -u | head -n 1 )
fi
if [ -z "$MODEL" ]; then
	MODEL=$( cat "$CAT_FILE" | grep "ro.product" | grep "model=" | sed "s|.*=||g" | sort -u | head -n 1 )
fi
VERSION=$( cat "$CAT_FILE" | grep "build.version.release=" | sed "s|.*=||g" | head -c 2 | sort -u | head -n 1 )

# Display var's
printf "${bold}${cyan}BRAND: ${BRAND}\nDEVICE: ${DEVICE}\nDESCRIPTION: ${DESCRIPTION}\nFINGERPRINT: ${FINGERPRINT}\nMODEL: ${MODEL}\nVERSION: ${VERSION}\n${nocol}"
