#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/tools/common_script.sh

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
	rm -rf $PROJECT_DIR/working/system_build.prop
	find "$1/$SYSTEM_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/system_build.prop \;
	CAT_FILE="$PROJECT_DIR/working/system_build.prop"
elif echo "$1" | grep "https" ; then
	wget -O $PROJECT_DIR/working/system_build.prop $1
	CAT_FILE="$PROJECT_DIR/working/system_build.prop"
else
	CAT_FILE="$1"
fi

# Set variables
if grep -q "brand=" "$CAT_FILE"; then
	BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | sort -u | head -n 1 )
elif grep -q "manufacturer=" "$CAT_FILE"; then
	BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "manufacturer=" | sed "s|.*=||g" | sort -u | head -n 1 )
fi
BRAND=${BRAND_TEMP,,}
if grep -q "ro.vivo.product.release.name" "$CAT_FILE"; then
	DEVICE=$( cat "$CAT_FILE" | grep "ro.vivo.product.release.name=" | sed "s|ro.vivo.product.release.name=||g" | sort -u | head -n 1 )
elif grep -q "ro.product.system.name" "$CAT_FILE"; then
	DEVICE=$( cat "$CAT_FILE" | grep "ro.product.system.name=" | sed "s|ro.product.system.name=||g" | sort -u | head -n 1 )
elif grep -q "# from vendor/oneplus/config/" "$CAT_FILE"; then
	DEVICE=$( cat "$CAT_FILE" | grep "# from vendor/oneplus/config/" | sed "s|# from vendor/oneplus/config/||g" | sed "s|/system.prop||g" | sort -u | head -n 1 )
else
	DEVICE=$( cat "$CAT_FILE" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
fi
if [ -z "$DEVICE" ]; then
	DEVICE=$( cat "$CAT_FILE" | grep "ro.build" | grep "product=" | sed "s|.*=||g" | sed "s|ASUS_||g" | sort -u | head -n 1 )
fi
if [ -z "$DEVICE" ]; then
	read -p "Enter device name manually: " DEVICE
fi
DESCRIPTION=$( cat "$CAT_FILE" | grep "ro." | grep "build.description=" | sed "s|.*=||g" | sort -u | head -n 1 )
if grep -q "build.fingerprint=" "$CAT_FILE"; then
	FINGERPRINT=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | sort -u | head -n 1 )
elif grep -q "build.thumbprint=" "$CAT_FILE"; then
	FINGERPRINT=$( cat "$CAT_FILE" | grep "ro." | grep "build.thumbprint=" | sed "s|.*=||g" | sort -u | head -n 1 )
fi
if [ -z "$FINGERPRINT" ]; then
	FINGERPRINT=$DESCRIPTION
fi
if grep -q "ro.oppo.market.name" "$CAT_FILE"; then
	MODEL=$( cat "$CAT_FILE" | grep "ro.oppo.market.name=" | sed "s|ro.oppo.market.name=||g" | sort -u | head -n 1 )
elif [ "$BRAND" = "oneplus" ]; then
	MODEL=$( cat "$CAT_FILE" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | sort -u | head -n 1 )
else
	MODEL=$( cat "$CAT_FILE" | grep "ro.product" | grep "model=" | sed "s|.*=||g" | sort -u | head -n 1 )
fi
if [ -z "$MODEL" ]; then
	MODEL=$DEVICE
fi
VERSION=$( cat "$CAT_FILE" | grep "build.version.release=" | sed "s|.*=||g" | head -c 2 | sort -u | head -n 1 )

# Display var's
printf "${bold}${cyan}BRAND: ${BRAND}\nDEVICE: ${DEVICE}\nDESCRIPTION: ${DESCRIPTION}\nFINGERPRINT: ${FINGERPRINT}\nMODEL: ${MODEL}\nVERSION: ${VERSION}\n${nocol}"
