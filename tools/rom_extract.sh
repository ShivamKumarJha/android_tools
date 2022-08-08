#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

SECONDS=0

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/helpers/common_script.sh

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply OTA file(s) as arguement!"
    exit 1
fi

# Password
if [ "$EUID" -ne 0 ] && [ -z "$user_password" ]; then
    read -p "Enter user password: " user_password
fi

for var in "$@"; do
    # Variables
    if [[ "$var" == *"http"* ]]; then
        URL="$var"
        dlrom
    else
        URL=$( realpath "$var" )
    fi
    [[ ! -e ${URL} ]] && echo "Error! File $URL does not exist." && break
    FILE=${URL##*/}
    EXTENSION=${URL##*.}
    UNZIP_DIR=${FILE/.$EXTENSION/}
    PARTITIONS="super system vendor cust odm oem factory product xrom modem dtbo dtb boot recovery tz systemex oppo_product preload_common system_ext system_other opproduct reserve india my_preload my_odm my_stock my_operator my_country my_product my_company my_engineering my_heytap my_custom my_manifest my_carrier my_region my_bigball my_version special_preload vendor_dlkm odm_dlkm system_dlkm init_boot vendor_kernel_boot vendor_boot"
    [[ -d $PROJECT_DIR/dumps/$UNZIP_DIR/ ]] && rm -rf $PROJECT_DIR/dumps/$UNZIP_DIR/

    if [ -d "$var" ] ; then
        echo -e "Copying images"
        cp -a "$var" $PROJECT_DIR/dumps/${UNZIP_DIR}
    else
        # Firmware extractor
        if [[ "$VERBOSE" = "n" ]]; then
            echo -e "Creating sparse images"
            bash $PROJECT_DIR/tools/Firmware_extractor/extractor.sh ${URL} $PROJECT_DIR/dumps/${UNZIP_DIR} > /dev/null 2>&1
        else
            bash $PROJECT_DIR/tools/Firmware_extractor/extractor.sh ${URL} $PROJECT_DIR/dumps/${UNZIP_DIR}
        fi
    fi
    [[ ! -e $PROJECT_DIR/dumps/${UNZIP_DIR}/system.img ]] && echo "No system.img found. Exiting" && break

    # boot.img operations
    if [ -e $PROJECT_DIR/dumps/${UNZIP_DIR}/boot.img ]; then
        cd ${PROJECT_DIR}/tools/android_boot_image_editor
        rm -rf ${PROJECT_DIR}/tools/android_boot_image_editor/build/ && ./gradlew clean > /dev/null 2>&1
        cp -a $PROJECT_DIR/dumps/${UNZIP_DIR}/boot.img ${PROJECT_DIR}/tools/android_boot_image_editor/boot.img
        ./gradlew unpack > /dev/null 2>&1
        rm -rf ${PROJECT_DIR}/tools/android_boot_image_editor/boot.img
        [[ -d ${PROJECT_DIR}/tools/android_boot_image_editor/build/unzip_boot ]] && cp -a ${PROJECT_DIR}/tools/android_boot_image_editor/build/unzip_boot $PROJECT_DIR/dumps/${UNZIP_DIR}
        [[ -d $PROJECT_DIR/dumps/${UNZIP_DIR}/unzip_boot ]] && mv $PROJECT_DIR/dumps/${UNZIP_DIR}/unzip_boot $PROJECT_DIR/dumps/${UNZIP_DIR}/boot
    fi
    # dtbo.img operations
    if [[ -f $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo.img ]]; then
        [[ "$VERBOSE" != "n" ]] && echo -e "Extracting dtbo"
        python3 $PROJECT_DIR/tools/extract-dtb/extract_dtb/extract_dtb.py $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo.img -o $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo > /dev/null 2>&1
    fi
    if [[ -d $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo ]]; then
        mkdir -p $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbs
        for dtb in $(ls $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo/); do
        $PROJECT_DIR/helpers/prebuilt/dt-compiler/dtc -f -I dtb -O dts -o "$PROJECT_DIR/dumps/${UNZIP_DIR}/dtbs/`echo "$dtb" | sed 's/\.dtb$//1'`.dts" $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo/$dtb  > /dev/null 2>&1
        done
    fi
    
    # mounting
    for file in $PARTITIONS; do
        if [ -e "$PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img" ]; then
            DIR_NAME=$(echo $file | cut -d . -f1)
            echo -e "Mounting & copying ${DIR_NAME}"
            mkdir -p $PROJECT_DIR/dumps/${UNZIP_DIR}/$DIR_NAME $PROJECT_DIR/dumps/$UNZIP_DIR/tempmount
            # mount & permissions
            echo $user_password | sudo -S mount -o loop "$PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img" "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
            echo $user_password | sudo -S chown -R $USER:$USER "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
            echo $user_password | sudo -S chmod -R u+rwX "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
            # copy to dump
            cp -a $PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount/* $PROJECT_DIR/dumps/$UNZIP_DIR/$DIR_NAME > /dev/null 2>&1
            # unmount
            echo $user_password | sudo -S umount -l "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
            # if empty partitions dump, try with 7z
            if [[ -z "$(ls -A $PROJECT_DIR/dumps/$UNZIP_DIR/$DIR_NAME)" ]]; then
                7z x $PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img -y -o$PROJECT_DIR/dumps/${UNZIP_DIR}/$file/ 2>/dev/null >> $PROJECT_DIR/dumps/${UNZIP_DIR}/zip.log || {
                    rm -rf $PROJECT_DIR/dumps/${UNZIP_DIR}/$file/* 2>/dev/null >> $PROJECT_DIR/dumps/${UNZIP_DIR}/zip.log
                    $PROJECT_DIR/tools/Firmware_extractor/tools/Linux/bin/fsck.erofs --extract=$PROJECT_DIR/dumps/${UNZIP_DIR}/$file $PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img 2>/dev/null >> $PROJECT_DIR/dumps/${UNZIP_DIR}/zip.log2>/dev/null >> $PROJECT_DIR/dumps/${UNZIP_DIR}/zip.log
                }
            fi
            # cleanup
            rm -rf $PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img $PROJECT_DIR/dumps/${UNZIP_DIR}/zip.log $PROJECT_DIR/dumps/$UNZIP_DIR/tempmount > /dev/null 2>&1
        fi
    done

    # board-info.txt & all_files.txt
    if [ -d $PROJECT_DIR/dumps/${UNZIP_DIR}/modem ]; then
        find $PROJECT_DIR/dumps/${UNZIP_DIR}/modem -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
        find $PROJECT_DIR/dumps/${UNZIP_DIR}/modem -type f -exec strings {} \; | grep "Time_Stamp\": \"" | tr -d ' ' | cut -c 15- | sed 's/.$//' | sed -e 's/^/require version-modem=/' >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
    fi
    find $PROJECT_DIR/dumps/${UNZIP_DIR}/ -maxdepth 1 -name "tz*" -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
    if [ -e $PROJECT_DIR/dumps/${UNZIP_DIR}/vendor/build.prop ]; then
        strings $PROJECT_DIR/dumps/${UNZIP_DIR}/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
    fi
    [[ -e $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt ]] && sort -u -o $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
    find $PROJECT_DIR/dumps/${UNZIP_DIR} -type f -printf '%P\n' | sort | grep -v ".git/" > $PROJECT_DIR/dumps/${UNZIP_DIR}/all_files.txt

    duration=$SECONDS
    [[ "$VERBOSE" != "n" ]] && echo -e "Dump location: $PROJECT_DIR/dumps/$UNZIP_DIR/"
    [[ "$VERBOSE" != "n" ]] && echo -e "Extract time: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
    [[ "$DUMPPUSH" == "y" ]] && bash "$PROJECT_DIR/tools/dump_push.sh" "$PROJECT_DIR/dumps/$UNZIP_DIR/"
    [[ "$DUMMYDT" == "y" ]] && bash "$PROJECT_DIR/tools/dummy_dt.sh" "$PROJECT_DIR/dumps/$UNZIP_DIR/"
done
