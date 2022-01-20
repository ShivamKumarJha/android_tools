#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/helpers/common_script.sh "y"

# Make sure to get path
if [ -z "$1" ]; then
    echo -e "Supply ROM path!"
    exit 1
fi

# Get files
mkdir -p $PROJECT_DIR/working/rootdir/bin/ $PROJECT_DIR/working/rootdir/etc/
[[ -f "$1"/vendor/bin/*.sh ]] && cp -a "$1"/vendor/bin/*.sh $PROJECT_DIR/working/rootdir/bin/
[[ -d "$1"/vendor/etc/init/hw/ ]] && cp -a "$1"/vendor/etc/init/hw/* $PROJECT_DIR/working/rootdir/etc/

# Prepare Android.mk
printf "LOCAL_PATH := \$(call my-dir)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\ninclude \$(CLEAR_VARS)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
# bins
rootdir_bins=`find $PROJECT_DIR/working/rootdir/bin/ -type f -printf '%P\n' | sort`
for file_bins in $rootdir_bins; do
    printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE       := $file_bins" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_TAGS  := optional" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_SRC_FILES    := bin/$file_bins" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR_EXECUTABLES)" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
    # rootdir.mk
    printf "$file_bins\n" >> $PROJECT_DIR/working/rootdir_temp.mk
done
# etc
rootdir_etc=`find $PROJECT_DIR/working/rootdir/etc/ -type f -printf '%P\n' | sort`
for file_etc in $rootdir_etc; do
    printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE       := $file_etc" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_TAGS  := optional" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_SRC_FILES    := etc/$file_etc" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR_ETC)/init/hw" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
    # rootdir.mk
    printf "$file_etc\n" >> $PROJECT_DIR/working/rootdir_temp.mk
done

# fstab Android.mk
cp -a "$1"/vendor/etc/fstab* $PROJECT_DIR/working/rootdir/etc/
rootdir_etc=`find $PROJECT_DIR/working/rootdir/etc/ -maxdepth 1 -type f -name "*fstab*" -printf '%P\n' | sort`
for file_fstab in $rootdir_etc; do
    printf "$file_fstab\n" >> $PROJECT_DIR/working/rootdir_temp.mk
    printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE       := $file_fstab" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_TAGS  := optional" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_SRC_FILES    := etc/$file_fstab" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR_ETC)" >> $PROJECT_DIR/working/rootdir/Android.mk
    printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk
done

# ueventd Android.mk
cp -a "$1"/vendor/ueventd.rc $PROJECT_DIR/working/rootdir/etc/ueventd.qcom.rc
printf "ueventd.qcom.rc\n" >> $PROJECT_DIR/working/rootdir_temp.mk
printf "\ninclude \$(CLEAR_VARS)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE       := ueventd.qcom.rc" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_STEM  := ueventd.rc" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_TAGS  := optional" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_CLASS := ETC" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_SRC_FILES    := etc/ueventd.qcom.rc" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\nLOCAL_MODULE_PATH  := \$(TARGET_OUT_VENDOR)" >> $PROJECT_DIR/working/rootdir/Android.mk
printf "\ninclude \$(BUILD_PREBUILT)\n" >> $PROJECT_DIR/working/rootdir/Android.mk

# Prepare rootdir.mk
awk 'NF{print $0 " \\"}' $PROJECT_DIR/working/rootdir_temp.mk >> $PROJECT_DIR/working/rootdir.mk
sed -i -e 's/^/    /' $PROJECT_DIR/working/rootdir.mk
sed -i '1 i\PRODUCT_PACKAGES += \\' $PROJECT_DIR/working/rootdir.mk
sed -i '1 i\# Ramdisk' $PROJECT_DIR/working/rootdir.mk

# cleanup
rm -rf $PROJECT_DIR/working/rootdir_temp.mk
