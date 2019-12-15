#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/helpers/common_script.sh

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply rom directory or system/build.prop as arguement!"
    exit 1
fi

for var in "$@"; do
    unset BRAND_TEMP BRAND DEVICE DESCRIPTION FINGERPRINT MODEL SECURITY_PATCH VERSION FLAVOR ID INCREMENTAL TAGS
    # Dir or file handling
    if [ -d "$var" ]; then
        if [ -e "$var"/odm/etc/build.prop ]; then
            if grep -q "brand=" $var/odm/etc/build.prop; then
                BRAND_TEMP=$( cat "$var"/odm/etc/build.prop | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | head -n 1 )
                DEVICE=$( cat "$var"/odm/etc/build.prop | grep "ro.product" | grep "device=" | sed "s|.*=||g" | head -n 1 )
                BRAND=${BRAND_TEMP,,}
                DEVICE=${DEVICE,,}
            fi
        fi
        if [ -e "$var"/odm/build.prop ]; then
            if grep -q "brand=" $var/odm/build.prop; then
                BRAND_TEMP=$( cat "$var"/odm/build.prop | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | head -n 1 | tr -d '[:space:]' )
                DEVICE=$( cat "$var"/odm/build.prop | grep "ro.product" | grep "device=" | sed "s|.*=||g" | head -n 1 | tr -d '[:space:]' )
                BRAND=${BRAND_TEMP,,}
                DEVICE=${DEVICE,,}
            fi
        fi
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
    if [[ -z "$DEVICE" ]]; then
        if grep -q "brand=" "$CAT_FILE"; then
                BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | head -n 1 )
        elif grep -q "manufacturer=" "$CAT_FILE"; then
                BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "manufacturer=" | sed "s|.*=||g" | head -n 1 )
        fi
        BRAND=${BRAND_TEMP,,}
        if grep -q "ro.vivo.product.release.name" "$CAT_FILE"; then
                DEVICE=$( cat "$CAT_FILE" | grep "ro.vivo.product.release.name=" | sed "s|.*=||g" | head -n 1 )
        elif grep -q "device=" "$CAT_FILE" && [[ "$BRAND" != "google" ]]; then
                DEVICE=$( cat "$CAT_FILE" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | sed "s|ASUS_||g" | head -n 1 )
        elif grep -q "ro.product.system.name" "$CAT_FILE" && [[ "$BRAND" != "google" ]]; then
                DEVICE=$( cat "$CAT_FILE" | grep "ro.product.system.name=" | sed "s|.*=||g" | sed "s|ASUS_||g" | head -n 1 )
        fi
        [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "ro.build" | grep "product=" | sed "s|.*=||g" | sed "s|ASUS_||g" | head -n 1 )
        [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | head -n 1 | cut -d : -f1 | rev | cut -d / -f1 | rev )
        [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "ro.target_product=" | sed "s|.*=||g" | head -n 1 | cut -d - -f1 )
        [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "build.fota.version=" | sed "s|.*=||g" | sed "s|WW_||1" | head -n 1 | cut -d - -f1 )
    fi
    VERSION=$( cat "$CAT_FILE" | grep "build.version.release=" | sed "s|.*=||g" | head -c 2 | head -n 1 )
    re='^[0-9]+$'
    if ! [[ $VERSION =~ $re ]] ; then
        VERSION=$( cat "$CAT_FILE" | grep "build.version.release=" | sed "s|.*=||g" | head -c 1 | head -n 1 )
    fi
    FLAVOR=$( cat "$CAT_FILE" | grep "ro.build" | grep "flavor=" | sed "s|.*=||g" | head -n 1 )
    ID=$( cat "$CAT_FILE" | grep "ro.build" | grep "id=" | sed "s|.*=||g" | head -n 1 )
    INCREMENTAL=$( cat "$CAT_FILE" | grep "ro.build" | grep "incremental=" | sed "s|.*=||g" | head -n 1 )
    TAGS=$( cat "$CAT_FILE" | grep "ro.build" | grep "tags=" | sed "s|.*=||g" | head -n 1 )
    DESCRIPTION=$( cat "$CAT_FILE" | grep "ro." | grep "build.description=" | sed "s|.*=||g" | head -n 1 )
    [[ -z "$DESCRIPTION" ]] && DESCRIPTION="$FLAVOR $VERSION $ID $INCREMENTAL $TAGS"
    if grep -q "build.fingerprint=" "$CAT_FILE"; then
        FINGERPRINT=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "build.thumbprint=" "$CAT_FILE"; then
        FINGERPRINT=$( cat "$CAT_FILE" | grep "ro." | grep "build.thumbprint=" | sed "s|.*=||g" | head -n 1 )
    fi
    if [ -z "$FINGERPRINT" ]; then
        FINGERPRINT=$( echo $DESCRIPTION | tr ' ' '-' )
    fi
    if echo "$FINGERPRINT" | grep -iE "nokia"; then
        BRAND="nokia"
        DEVICE=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | head -n 1 | cut -d : -f1 | rev | cut -d / -f2 | rev | sed "s|_.*||g" )
    fi
    [[ -z "${BRAND}" ]] && BRAND=$(echo $FINGERPRINT | cut -d / -f1 )
    if grep -q "ro.oppo.market.name" "$CAT_FILE"; then
        MODEL=$( cat "$CAT_FILE" | grep "ro.oppo.market.name=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.display.series" "$CAT_FILE"; then
        MODEL=$( cat "$CAT_FILE" | grep "ro.display.series=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.product.display" "$CAT_FILE"; then
        MODEL=$( cat "$CAT_FILE" | grep "ro.product.display=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.semc.product.name" "$CAT_FILE"; then
        MODEL=$( cat "$CAT_FILE" | grep "ro.semc.product.name=" | sed "s|.*=||g" | head -n 1 )
    else
        MODEL=$( cat "$CAT_FILE" | grep "ro.product" | grep "model=" | sed "s|.*=||g" | head -n 1 )
    fi
    [[ -z "$MODEL" ]] && MODEL=$DEVICE
    SECURITY_PATCH=$( cat "$CAT_FILE" | grep "build.version.security_patch=" | sed "s|.*=||g" | head -n 1 )

    # Display var's
    declare -a arr=("BRAND" "DEVICE" "DESCRIPTION" "FINGERPRINT" "MODEL" "SECURITY_PATCH" "VERSION" "FLAVOR" "ID" "INCREMENTAL" "TAGS")
    for i in "${arr[@]}"; do printf "$i: ${!i}\n"; done
done
