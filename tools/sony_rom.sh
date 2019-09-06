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
source $PROJECT_DIR/tools/common_script.sh "y"

# Exit if mono not installed
if [ -z "$(which mono)" ]; then
    echo -e "mono not installed!"
    exit 1
fi

# Dependencies check
if [ ! -d "$PROJECT_DIR/tools/extract-dtb" ] || [ ! -d "$PROJECT_DIR/tools/mkbootimg_tools" ]; then
    echo -e "Missing dependencies!Run: bash tools/dependencies.sh"
    exit 1
fi

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
    URL=$( realpath "$var" )
    FILE=${URL##*/}
    EXTENSION=${URL##*.}
    UNZIP_DIR=${FILE/.$EXTENSION/}
    # Extract
    unzip $URL -d $PROJECT_DIR/working
    # Extract sin
    [[ -e $PROJECT_DIR/working/userdata.sin ]] && rm -rf $PROJECT_DIR/working/userdata.sin
    $PROJECT_DIR/tools/prebuilt/unsin -dr $PROJECT_DIR/working
    find $PROJECT_DIR/working/ -name "*.sin" -type f -exec rm -rf {} \;
    [[ -d $PROJECT_DIR/dumps/$UNZIP_DIR/ ]] && rm -rf $PROJECT_DIR/dumps/$UNZIP_DIR/
    # mounting
    ext4_list=`find $PROJECT_DIR/working -type f \( -name "*ext4*" -o -name "modem.img" -o -name "bluetooth.img" \) -printf '%P\n' | sort`
    for file in $ext4_list; do
        DIR_NAME=$(echo $file | cut -d . -f1)
        echo -e "Mounting & copying ${DIR_NAME}"
        mkdir -p $PROJECT_DIR/working/$DIR_NAME $PROJECT_DIR/dumps/$UNZIP_DIR/$DIR_NAME
        # mount & permissions
        if [ "$file" == "modem.img" ] || [ "$file" == "bluetooth.img" ]; then
            echo $user_password | sudo -S mount -t vfat -o loop $PROJECT_DIR/working/$file $PROJECT_DIR/working/$DIR_NAME > /dev/null 2>&1
        else
            echo $user_password | sudo -S mount -t ext4 -o loop $PROJECT_DIR/working/$file $PROJECT_DIR/working/$DIR_NAME > /dev/null 2>&1
        fi
        echo $user_password | sudo -S chown -R $USER:$USER $PROJECT_DIR/working/$DIR_NAME > /dev/null 2>&1
        echo $user_password | sudo -S chmod -R u+rwX $PROJECT_DIR/working/$DIR_NAME > /dev/null 2>&1
        # copy to dump
        cp -a $PROJECT_DIR/working/$DIR_NAME/* $PROJECT_DIR/dumps/$UNZIP_DIR/$DIR_NAME > /dev/null 2>&1
        # unmount
        echo $user_password | sudo -S umount -l $PROJECT_DIR/working/$DIR_NAME
    done
    # board-info.txt
    find $PROJECT_DIR/dumps/$UNZIP_DIR/modem -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> $PROJECT_DIR/dumps/$UNZIP_DIR/board-info.txt
    find $PROJECT_DIR/dumps/$UNZIP_DIR/modem -type f -exec strings {} \; | grep "Time_Stamp\": \"" | tr -d ' ' | cut -c 15- | sed 's/.$//' | sed -e 's/^/require version-modem=/' >> $PROJECT_DIR/dumps/$UNZIP_DIR/board-info.txt
    if [ -e $PROJECT_DIR/dumps/$UNZIP_DIR/vendor/build.prop ]; then
        strings $PROJECT_DIR/dumps/$UNZIP_DIR/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> $PROJECT_DIR/dumps/$UNZIP_DIR/board-info.txt
    fi
    if [ -d $PROJECT_DIR/working/boot/ ]; then
        boot_list=`find $PROJECT_DIR/working/boot/ -type f -printf '%P\n' | sort`
        for boot_file in $boot_list; do
            DIR_NAME=$(echo $boot_file | cut -d . -f1)
            7z x $PROJECT_DIR/working/boot/$boot_file -y -o$PROJECT_DIR/working/boot/$DIR_NAME/ 2>/dev/null >> $PROJECT_DIR/working/boot/zip.log
        done
        find $PROJECT_DIR/working/boot/ -name "tz*" -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> $PROJECT_DIR/dumps/$UNZIP_DIR/board-info.txt
    fi
    sort -u -o $PROJECT_DIR/dumps/$UNZIP_DIR/board-info.txt $PROJECT_DIR/dumps/$UNZIP_DIR/board-info.txt
    # boot.img operations
    if [ -e $PROJECT_DIR/working/boot.img ]; then
        # Extract kernel
        bash $PROJECT_DIR/tools/mkbootimg_tools/mkboot $PROJECT_DIR/working/boot.img $PROJECT_DIR/dumps/$UNZIP_DIR/boot/ > /dev/null 2>&1
        mv $PROJECT_DIR/dumps/$UNZIP_DIR/boot/kernel $PROJECT_DIR/dumps/$UNZIP_DIR/boot/Image.gz-dtb
        # Extract dtb
        python3 $PROJECT_DIR/tools/extract-dtb/extract-dtb.py $PROJECT_DIR/working/boot.img -o $PROJECT_DIR/dumps/$UNZIP_DIR/bootimg > /dev/null 2>&1
        # Extract dts
        mkdir $PROJECT_DIR/dumps/$UNZIP_DIR/bootdts
        dtb_list=`find $PROJECT_DIR/dumps/$UNZIP_DIR/bootimg -name '*.dtb' -type f -printf '%P\n' | sort`
        for dtb_file in $dtb_list; do
            dtc -I dtb -O dts -o $(echo "$PROJECT_DIR/dumps/$UNZIP_DIR/bootdts/$dtb_file" | sed -r 's|.dtb|.dts|g') $PROJECT_DIR/dumps/$UNZIP_DIR/bootimg/$dtb_file > /dev/null 2>&1
        done
    fi
    # dtbo
    if [[ -f $PROJECT_DIR/working/dtbo.img ]]; then
        python3 $PROJECT_DIR/tools/extract-dtb/extract-dtb.py $PROJECT_DIR/working/dtbo.img -o $PROJECT_DIR/dumps/$UNZIP_DIR/dtbo > /dev/null 2>&1
    fi
    # all_files.txt
    find $PROJECT_DIR/dumps/$UNZIP_DIR/ -type f -printf '%P\n' | sort > $PROJECT_DIR/dumps/$UNZIP_DIR/all_files.txt
    # cleanup & display
    rm -rf $PROJECT_DIR/working/*
    duration=$SECONDS
    echo -e "Dump location: $PROJECT_DIR/dumps/$UNZIP_DIR/"
    echo -e "Extract time: $(($duration / 60)) minutes and $(($duration % 60)) seconds."
done
