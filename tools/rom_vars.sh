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

for var in "$@"; do
	unset BRAND_TEMP BRAND DEVICE DESCRIPTION FINGERPRINT MODEL SECURITY_PATCH VERSION
	# Dir or file handling
	if [ -d "$var" ]; then
		if [ -e "$var"/system/system/build.prop ]; then
			SYSTEM_PATH="system/system"
		elif [ -e "$var"/system/build.prop ]; then
			SYSTEM_PATH="system"
		fi
		rm -rf $PROJECT_DIR/working/system_build.prop
		find "$var/$SYSTEM_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/system_build.prop \;
		CAT_FILE="$PROJECT_DIR/working/system_build.prop"
	elif echo "$var" | grep "https" ; then
		wget -O $PROJECT_DIR/working/system_build.prop $var
		CAT_FILE="$PROJECT_DIR/working/system_build.prop"
	else
		CAT_FILE="$var"
	fi

	# Set variables
	if grep -q "brand=" "$CAT_FILE"; then
		BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | head -n 1 )
	elif grep -q "manufacturer=" "$CAT_FILE"; then
		BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "manufacturer=" | sed "s|.*=||g" | head -n 1 )
	fi
	BRAND=${BRAND_TEMP,,}
	if grep -q "ro.vivo.product.release.name" "$CAT_FILE"; then
		DEVICE=$( cat "$CAT_FILE" | grep "ro.vivo.product.release.name=" | sed "s|ro.vivo.product.release.name=||g" | head -n 1 )
	elif grep -q "ro.product.system.name" "$CAT_FILE"; then
		DEVICE=$( cat "$CAT_FILE" | grep "ro.product.system.name=" | sed "s|ro.product.system.name=||g" | head -n 1 )
	elif grep -q "# from vendor/oneplus/config/" "$CAT_FILE"; then
		DEVICE=$( cat "$CAT_FILE" | grep "# from vendor/oneplus/config/" | sed "s|# from vendor/oneplus/config/||g" | sed "s|/system.prop||g" | head -n 1 )
	elif grep -q "ro.build.fota.version" "$CAT_FILE"; then
		DEVICE=$( cat "$CAT_FILE" | grep "ro.build.fota.version=" | sed "s|.*=||g" | head -n 1 | cut -d - -f1 )
	else
		DEVICE=$( cat "$CAT_FILE" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | sed "s|ASUS_||g" | head -n 1 )
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=$( cat "$CAT_FILE" | grep "ro.build" | grep "product=" | sed "s|.*=||g" | sed "s|ASUS_||g" | head -n 1 )
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | head -n 1 | cut -d : -f1 | rev | cut -d / -f1 | rev )
	fi
	DESCRIPTION=$( cat "$CAT_FILE" | grep "ro." | grep "build.description=" | sed "s|.*=||g" | head -n 1 )
	if grep -q "build.fingerprint=" "$CAT_FILE"; then
		FINGERPRINT=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | head -n 1 )
	elif grep -q "build.thumbprint=" "$CAT_FILE"; then
		FINGERPRINT=$( cat "$CAT_FILE" | grep "ro." | grep "build.thumbprint=" | sed "s|.*=||g" | head -n 1 )
	fi
	if [ -z "$FINGERPRINT" ] && [ ! -z "$DESCRIPTION" ]; then
		FINGERPRINT=$DESCRIPTION
	fi
	if grep -q "ro.oppo.market.name" "$CAT_FILE"; then
		MODEL=$( cat "$CAT_FILE" | grep "ro.oppo.market.name=" | sed "s|ro.oppo.market.name=||g" | head -n 1 )
	elif [ "$BRAND" == "oneplus" ]; then
		MODEL=$( cat "$CAT_FILE" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | head -n 1 )
	elif grep -q "ro.product.display" "$CAT_FILE"; then
		MODEL=$( cat "$CAT_FILE" | grep "ro.product.display=" | sed "s|.*=||g" | head -n 1 )
	elif grep -q "ro.semc.product.name" "$CAT_FILE"; then
		MODEL=$( cat "$CAT_FILE" | grep "ro.semc.product.name=" | sed "s|.*=||g" | head -n 1 )
	else
		MODEL=$( cat "$CAT_FILE" | grep "ro.product" | grep "model=" | sed "s|.*=||g" | head -n 1 )
	fi
	if [ -z "$MODEL" ]; then
		MODEL=$DEVICE
	fi
	SECURITY_PATCH=$( cat "$CAT_FILE" | grep "build.version.security_patch=" | sed "s|.*=||g" | head -n 1 )
	VERSION=$( cat "$CAT_FILE" | grep "build.version.release=" | sed "s|.*=||g" | head -c 2 | head -n 1 )
	re='^[0-9]+$'
	if ! [[ $VERSION =~ $re ]] ; then
		VERSION=$( cat "$CAT_FILE" | grep "build.version.release=" | sed "s|.*=||g" | head -c 1 | head -n 1 )
	fi

	# Display var's
	printf "${bold}${cyan}BRAND: ${BRAND}\nDEVICE: ${DEVICE}\nDESCRIPTION: ${DESCRIPTION}\nFINGERPRINT: ${FINGERPRINT}\nMODEL: ${MODEL}\nSECURITY PATCH: ${SECURITY_PATCH}\nVERSION: ${VERSION}\n${nocol}"
done
