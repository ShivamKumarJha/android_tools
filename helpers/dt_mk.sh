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

if [ -z "$1" ]; then
    echo -e "Error! Send DT path"
    exit 1
fi

DT_DIR="$1"
cd "$DT_DIR"/

# configs
find ""$DT_DIR"/configs/audio/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/audio/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/" "# Audio"
find ""$DT_DIR"/configs/gps/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/gps/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/" "# GPS"
if [ -d "$DT_DIR"/configs/idc/ ]; then
    find "configs/idc/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
    bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/idc/" ":\$(TARGET_COPY_OUT_VENDOR)/usr/idc/" "# IDC"
fi
find ""$DT_DIR"/configs/keylayout/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/keylayout/" ":\$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/" "# Keylayout"
find ""$DT_DIR"/configs/media/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/media/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/" "# Media"
find ""$DT_DIR"/configs/seccomp/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/seccomp/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/" "# Seccomp"
find ""$DT_DIR"/configs/sensors/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/sensors/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/sensors/" "# Sensors"
find ""$DT_DIR"/configs/wifi/" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/wifi/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/wifi/" "# WiFi"
if [ -e "$DT_DIR"/configs/excluded-input-devices.xml ]; then
    echo "excluded-input-devices.xml" > "$PROJECT_DIR"/working/mklist.txt
    bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/" ":system/etc/" "# Exclude sensor from InputManager"
fi
if [ -e "$DT_DIR"/configs/msm_irqbalance.conf ]; then
    find ""$DT_DIR"/configs/" -name "msm_irqbalance*" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
    bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/" "# IRQ"
fi
if [ -e "$DT_DIR"/configs/privapp-permissions-qti.xml ]; then
    find ""$DT_DIR"/configs/" -name "privapp-permissions-qti.xml" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
    bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/permissions/" "# QTI"
fi
if [ -e "$DT_DIR"/configs/public.libraries.txt ]; then
    find ""$DT_DIR"/configs/" -name "public.libraries*" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
    bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/" "# Public Libraries"
fi
if [ -e "$DT_DIR"/configs/qti_whitelist.xml ]; then
    find ""$DT_DIR"/configs/" -name "qti_whitelist.xml" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
    bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/" ":system/etc/sysconfig/" "# Low power Whitelist"
fi
if [ -e "$DT_DIR"/configs/sec_config ]; then
    find ""$DT_DIR"/configs/" -name "sec_config" -type f -printf '%P\n' | sort > "$PROJECT_DIR"/working/mklist.txt
    bash $PROJECT_DIR/helpers/writemk.sh "\$(LOCAL_PATH)/configs/" ":\$(TARGET_COPY_OUT_VENDOR)/etc/" "# IRSC"
fi
# permissions
cat "$PROJECT_DIR"/dummy_dt/working/all_files.txt | grep "vendor" | grep -iE "permissions/android.hardware|permissions/android.software|permissions/handheld_core_hardware" | grep -v "android.hardware.light.xml" | sed "s|vendor/etc/permissions/||g" > "$PROJECT_DIR"/working/perms.txt
all_perms=`cat "$PROJECT_DIR"/working/perms.txt | sort`
for perm_line in $all_perms;
do
    echo "    frameworks/native/data/etc/"$perm_line":\$(TARGET_COPY_OUT_VENDOR)/etc/permissions/"$perm_line" \\" >> "$PROJECT_DIR"/working/mklists/Permissions
done
sed -i '1 i\PRODUCT_COPY_FILES += \\' "$PROJECT_DIR"/working/mklists/Permissions
sed -i '1 i\# Permissions' "$PROJECT_DIR"/working/mklists/Permissions
printf "\n" >> "$PROJECT_DIR"/working/mklists/Permissions
#  rootdir.mk
printf "\n" >> "$DT_DIR"/rootdir.mk
mv "$DT_DIR"/rootdir.mk "$PROJECT_DIR"/working/mklists/Ramdisk
# Overlays
printf "# Overlays" >> "$PROJECT_DIR"/working/mklists/Overlays
printf "\nDEVICE_PACKAGE_OVERLAYS += \\" >> "$PROJECT_DIR"/working/mklists/Overlays
printf "\n    \$(LOCAL_PATH)/overlay\n\n" >> "$PROJECT_DIR"/working/mklists/Overlays
# Add makefiles from lists
mk_lists=`find "$PROJECT_DIR"/working/mklists/ -type f -printf '%P\n' | sort`
for list in $mk_lists ;
do
    cat "$PROJECT_DIR"/working/mklists/"$list" >> "$DT_DIR"/device.mk
done
