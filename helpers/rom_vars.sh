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
    unset BRAND_TEMP BRAND DEVICE DESCRIPTION FINGERPRINT MODEL PLATFORM SECURITY_PATCH VERSION FLAVOR ID INCREMENTAL TAGS
    # Dir or file handling
    if [ -d "$var" ]; then
        DIR=$( realpath "$var" )
        rm -rf $PROJECT_DIR/working/system_build.prop
        [[ -f "$DIR/boot/root/prop.default" ]] && cat "$DIR/boot/root/prop.default" >> $PROJECT_DIR/working/system_build.prop
        find "$DIR/" -maxdepth 3 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/system_build.prop \;
        if [[ -d "$DIR/vendor/euclid/" ]]; then
            EUCLIST=`find "$DIR/vendor/euclid/" -name "*.img" | sort`
            for EUCITEM in $EUCLIST; do
                7z x -y $EUCITEM -o"$PROJECT_DIR/working/euclid" > /dev/null 2>&1
                [[ -d "$PROJECT_DIR/working/euclid" ]] && find "$PROJECT_DIR/working/euclid" -name "*prop" -exec cat {} >> $PROJECT_DIR/working/system_build.prop \;
                rm -rf "$PROJECT_DIR/working/euclid"
            done
        fi
        CAT_FILE="$PROJECT_DIR/working/system_build.prop"
    elif echo "$var" | grep "https" ; then
        if echo "$var" | grep "all_files.txt" ; then
            wget -O $PROJECT_DIR/working/all_files.txt $var
            DUMPURL=$( echo ${var} | sed "s|/all_files.txt||1" )
            file_lines=`cat $PROJECT_DIR/working/all_files.txt | grep -iE "build" | grep -iE "prop" | sort -uf`
            for line in $file_lines ; do
                ((OTA_NO++))
                wget ${DUMPURL}/${line} -O $PROJECT_DIR/working/${OTA_NO}.prop > /dev/null 2>&1
            done
            find $PROJECT_DIR/working/ -name "*prop" -exec cat {} >> $PROJECT_DIR/working/system_build \;
            CAT_FILE="$PROJECT_DIR/working/system_build"
        else
            wget -O $PROJECT_DIR/working/system_build.prop $var
            CAT_FILE="$PROJECT_DIR/working/system_build.prop"
        fi
    else
        CAT_FILE="$var"
    fi

    #build.prop cleanup
    sed -i "s|ro.*\=QUALCOMM||g" "$CAT_FILE"
    sed -i "s|ro.*\=qssi||g" "$CAT_FILE"
    sed -i "s|ro.*\=qti||g" "$CAT_FILE"
    sed -i '/^$/d' "$CAT_FILE"
    sort -u -o "$CAT_FILE" "$CAT_FILE"

    # Set variables
    if grep -q "ro.product.odm.manufacturer=" "$CAT_FILE"; then
        BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product.odm.manufacturer" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.product.product.manufacturer=" "$CAT_FILE"; then
        BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product.product.manufacturer" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "odm.brand=" "$CAT_FILE"; then
        BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "odm.brand=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "brand=" "$CAT_FILE"; then
        BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "brand=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "manufacturer=" "$CAT_FILE"; then
        BRAND_TEMP=$( cat "$CAT_FILE" | grep "ro.product" | grep "manufacturer=" | sed "s|.*=||g" | head -n 1 )
    fi
    BRAND=$(echo $BRAND_TEMP | tr '[:upper:]' '[:lower:]')
    if grep -q "ro.vivo.product.release.name" "$CAT_FILE"; then
        DEVICE=$( cat "$CAT_FILE" | grep "ro.vivo.product.release.name=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.vendor.product.oem=" "$CAT_FILE"; then
        DEVICE=$( cat "$CAT_FILE" | grep "ro.vendor.product.oem=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.product.vendor.device=" "$CAT_FILE"; then
        DEVICE=$( cat "$CAT_FILE" | grep "ro.product.vendor.device=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "odm.device=" "$CAT_FILE"; then
        DEVICE=$( cat "$CAT_FILE" | grep "odm.device=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "device=" "$CAT_FILE" && [[ "$BRAND" != "google" ]]; then
        DEVICE=$( cat "$CAT_FILE" | grep "ro.product" | grep "device=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.product.system.name" "$CAT_FILE" && [[ "$BRAND" != "google" ]]; then
        DEVICE=$( cat "$CAT_FILE" | grep "ro.product.system.name=" | sed "s|.*=||g" | head -n 1 )
    fi
    [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "ro.build" | grep "product=" | sed "s|.*=||g" | head -n 1 )
    [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "ro." | grep "build.fingerprint=" | sed "s|.*=||g" | head -n 1 | cut -d : -f1 | rev | cut -d / -f1 | rev )
    [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "ro.target_product=" | sed "s|.*=||g" | head -n 1 | cut -d - -f1 )
    [[ -z "$DEVICE" ]] && DEVICE=$( cat "$CAT_FILE" | grep "build.fota.version=" | sed "s|.*=||g" | sed "s|WW_||1" | head -n 1 | cut -d - -f1 )
    DEVICE=$( echo ${DEVICE} | sed "s|ASUS_||g" )
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
    [[ -z "$FINGERPRINT" ]] && FINGERPRINT=$( echo $DESCRIPTION | tr ' ' '-' )
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
    elif grep -q "ro.product.vendor.marketname" "$CAT_FILE"; then
        MODEL=$( cat "$CAT_FILE" | grep "ro.product.vendor.marketname=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.product.odm.model" "$CAT_FILE"; then
        MODEL=$( cat "$CAT_FILE" | grep "ro.product.odm.model=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.product.vendor.model" "$CAT_FILE"; then
        MODEL=$( cat "$CAT_FILE" | grep "ro.product.vendor.model=" | sed "s|.*=||g" | head -n 1 )
    else
        MODEL=$( cat "$CAT_FILE" | grep "ro.product" | grep "model=" | sed "s|.*=||g" | head -n 1 )
    fi
    [[ -z "$MODEL" ]] && MODEL=$DEVICE
    PLATFORM=$( cat "$CAT_FILE" | grep "ro.board.platform" | sed "s|.*=||g" | head -n 1 )
    SECURITY_PATCH=$( cat "$CAT_FILE" | grep "build.version.security_patch=" | sed "s|.*=||g" | head -n 1 )

    # Date
    if grep -q "ro.system.build.date=" "$CAT_FILE"; then
        DATE=$( cat "$CAT_FILE" | grep "ro.system.build.date=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.vendor.build.date=" "$CAT_FILE"; then
        DATE=$( cat "$CAT_FILE" | grep "ro.vendor.build.date=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.build.date=" "$CAT_FILE"; then
        DATE=$( cat "$CAT_FILE" | grep "ro.build.date=" | sed "s|.*=||g" | head -n 1 )
    elif grep -q "ro.bootimage.build.date=" "$CAT_FILE"; then
        DATE=$( cat "$CAT_FILE" | grep "ro.bootimage.build.date=" | sed "s|.*=||g" | head -n 1 )
    fi

    BRANCH=$(echo $DESCRIPTION $DATE | tr ' ' '-' | tr ':' '-')
    TOPIC1=$(echo $BRAND | tr '[:upper:]' '[:lower:]' | tr -dc '[[:print:]]' | tr '_' '-' | cut -c 1-35)
    TOPIC2=$(echo $PLATFORM | tr '[:upper:]' '[:lower:]' | tr -dc '[[:print:]]' | tr '_' '-' | cut -c 1-35)
    TOPIC3=$(echo $DEVICE | tr '[:upper:]' '[:lower:]' | tr -dc '[[:print:]]' | tr '_' '-' | cut -c 1-35)

    # Display var's
    declare -a arr=("BRAND" "DEVICE" "DESCRIPTION" "FINGERPRINT" "MODEL" "PLATFORM" "SECURITY_PATCH" "VERSION" "DATE" "FLAVOR" "ID" "INCREMENTAL" "TAGS" "BRANCH")
    for i in "${arr[@]}"; do printf "$i: ${!i}\n"; done
    # Cleanup
    rm -rf $PROJECT_DIR/working/system_build* $PROJECT_DIR/working/*prop $PROJECT_DIR/working/all_files.txt
done
