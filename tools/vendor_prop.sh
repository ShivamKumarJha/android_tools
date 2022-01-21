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

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply ROM directory as arguement!"
    exit 1
fi

# Get files via either cp or wget
if echo "$1" | grep "https" ; then
    wget -O $PROJECT_DIR/working/system_working.prop $1
elif [ -d "$1" ]; then
    if [ -e "$1"/system/system/build.prop ]; then
        SYSTEM_PATH="system/system"
    elif [ -e "$1"/system/build.prop ]; then
        SYSTEM_PATH="system"
    fi
    find "$1" -name "prop.default" -exec cat {} >> $PROJECT_DIR/working/boot_working.prop \;
    find "$1/$SYSTEM_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/system_working.prop \;
    [[ -d "$1/system/vendor/" ]] && VENDOR_PATH="system/vendor"
    [[ -d "$1/system/system/vendor/" ]] && VENDOR_PATH="system/system/vendor"
    [[ -d "$1/vendor/" ]] && VENDOR_PATH="vendor"
    find "$1/$VENDOR_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/vendor_working.prop \;
else
    cp -a $1 $PROJECT_DIR/working/system_working.prop
fi
if [ ! -z "$2" ] ; then
    if echo "$2" | grep "https" ; then
        wget -O $PROJECT_DIR/working/vendor_working.prop $2
    else
        cp -a $2 $PROJECT_DIR/working/vendor_working.prop
    fi
fi

# boot.prop
if [ -s "$PROJECT_DIR/working/boot_working.prop" ]; then
    TSTART=$(grep -nr "# end build properties" $PROJECT_DIR/working/boot_working.prop | sed "s|:.*||g" | head -1)
    TEND=$(wc -l $PROJECT_DIR/working/boot_working.prop | sed "s| .*||g" | head -1)
    sed -n "${TSTART},${TEND}p" $PROJECT_DIR/working/boot_working.prop | sort | sed "s|#.*||g" | sed '/^[[:space:]]*$/d' > $PROJECT_DIR/working/boot_new.prop
fi

# system.prop
if [ -s "$PROJECT_DIR/working/system_working.prop" ]; then
    TSTART=$(grep -nr "# end build properties" $PROJECT_DIR/working/system_working.prop | sed "s|:.*||g" | head -1)
    TEND=$(grep -nr "# ADDITIONAL_BUILD_PROPERTIES" $PROJECT_DIR/working/system_working.prop | sed "s|:.*||g" | head -1)
    sed -n "${TSTART},${TEND}p" $PROJECT_DIR/working/system_working.prop | sort | sed "s|#.*||g" | sed '/^[[:space:]]*$/d' > $PROJECT_DIR/working/system_new.prop
fi

# vendor.prop
if [ -s "$PROJECT_DIR/working/vendor_working.prop" ]; then
    TSTART=$(grep -nr "ADDITIONAL VENDOR BUILD PROPERTIES" $PROJECT_DIR/working/vendor_working.prop | sed "s|:.*||g" | head -1)
    TEND=$(wc -l $PROJECT_DIR/working/vendor_working.prop | sed "s| .*||g" | head -1)
    sed -n "${TSTART},${TEND}p" $PROJECT_DIR/working/vendor_working.prop | sort | sed "s|#.*||g" | sed '/^[[:space:]]*$/d' > $PROJECT_DIR/working/vendor_new.prop
fi

# Combine newly generated system.prop & vendor.prop
if [ -s "$PROJECT_DIR/working/boot_new.prop" ]; then
    awk '!NF || !seen[$0]++' $PROJECT_DIR/working/boot_new.prop > $PROJECT_DIR/working/boot_new2.prop
    echo "$(cat $PROJECT_DIR/working/boot_new2.prop | sort -u )" >> $PROJECT_DIR/working/staging.mk
elif [ -s "$PROJECT_DIR/working/vendor_new.prop" ]; then
    echo "$(cat $PROJECT_DIR/working/system_new.prop $PROJECT_DIR/working/vendor_new.prop | sort -u )" >> $PROJECT_DIR/working/staging.mk
else
    echo "$(cat $PROJECT_DIR/working/system_new.prop | sort -u )" >> $PROJECT_DIR/working/staging.mk
fi

# Cleanup unrequired prop's
sed -i "s|dalvik.vm.heapsize=36m||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.sys.mcd_config_file.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.miui.density.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.miui.notch.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.build.fota.version=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.build.software.version=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.build.version.incremental=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.vendor.build.fingerprint.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.rild.nitz_.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.hwui.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.config.alarm_alert=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.config.calendaralert_sound=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.config.newmail_sound=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.config.notification_sound=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.config.ringtone=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.config.sentmail_sound=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.com.google.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.external.version.code=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.huaqin.version.release=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.setupwizard.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|setupwizard.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.product.first_api_level=.*||g" $PROJECT_DIR/working/staging.mk
sed '/^$/d' $PROJECT_DIR/working/staging.mk | sort -u > $PROJECT_DIR/working/temp.mk

add_to_section() {
	if [[ -z "${3}" ]]; then
	    cat "$PROJECT_DIR/working/temp.mk" | grep -iE "${1}" | sort -u > "$PROJECT_DIR/working/lists/${2}"
	else
	    cat "$PROJECT_DIR/working/temp.mk" | grep -iE "${1}" | grep -v "${2}" | sort -u > "$PROJECT_DIR/working/lists/${3}"
	fi
}

# Prop's grouping
mkdir -p $PROJECT_DIR/working/lists/
# Audio
add_to_section "audio|af.|ro.af.|ro.config.media|ro.config.vc_call|dirac.|av.|voice." Audio
# Bluetooth
add_to_section "bt.|bluetooth" Bluetooth
# Camera
add_to_section "ts.|camera" "dalvik" Camera
# Charging
add_to_section "persist.chg|chg.|cutoff_voltage_mv" Charging
# CNE
add_to_section "cne." CNE
# Crypto
add_to_section "crypto." Crypto
# Dalvik
add_to_section "dalvik" Dalvik
# DPM
add_to_section "dpm." DPM
# DRM
add_to_section "drm" DRM
# FM
add_to_section "fm." FM
# FRP
add_to_section "frp." FRP
# FUSE
add_to_section "fuse" FUSE
# Graphics
add_to_section "debug.sf.|gralloc|hwui|dev.pm.|hdmi|opengles|lcd_density|display|rotator_downscale|debug.egl.hw" Graphics
# Location
add_to_section "location" Location
# Media
add_to_section "media.|mm.|mmp.|vidc.|aac." "audio" Media
# Netflix
add_to_section "netflix" Netflix
# Netmgr
add_to_section "netmgrd|data.mode" Netmgr
# NFC
add_to_section "nfc" NFC
# NTP
add_to_section "ntpServer" NTP
# Perf
add_to_section "perf." Perf
# QTI
add_to_section "qti" QTI
# Radio
add_to_section "DEVICE_PROVISIONED|persist.data|radio|ril.|rild.|ro.carrier|dataroaming|telephony" Radio
# Sensors
add_to_section "sensors." Sensors
# Skip_validate
add_to_section "skip_validate" Skip_validate
# Shutdown
add_to_section "shutdown" Shutdown
# SSR
add_to_section "ssr." "audio" SSR
# Thermal
add_to_section "thermal." Thermal
# Time
add_to_section "timed." Time
# UBWC
add_to_section "ubwc" UBWC
# USB
add_to_section "usb." "audio" USB
# WFD
add_to_section "wfd." WFD
# WLAN
add_to_section "wlan." WLAN
# ZRAM
add_to_section "zram" ZRAM

# Store missing props as Misc
cat $PROJECT_DIR/working/lists/* > $PROJECT_DIR/working/tempall.mk
file_lines=`cat $PROJECT_DIR/working/temp.mk`
for line in $file_lines; do
    if ! grep -q "$line" $PROJECT_DIR/working/tempall.mk; then
        echo "$line" >> $PROJECT_DIR/working/lists/Misc
    fi
done

# Delete empty lists
find $PROJECT_DIR/working/lists/ -size  0 -print0 | xargs -0 rm --

# Add props from lists
props_list=`find $PROJECT_DIR/working/lists -type f -printf '%P\n' | sort`
for list in $props_list; do
    echo "# $list" >> $PROJECT_DIR/working/temp_prop.mk
    echo "PRODUCT_PROPERTY_OVERRIDES += \\" >> $PROJECT_DIR/working/temp_prop.mk
    awk 'NF{print $0 " \\"}' $PROJECT_DIR/working/lists/$list >> $PROJECT_DIR/working/temp_prop.mk
done

# Remove duplicate props & text formatting
awk '/^PRODUCT_PROPERTY_OVERRIDES/ || !seen[$0]++' $PROJECT_DIR/working/temp_prop.mk > $PROJECT_DIR/working/vendor_prop.mk
sed -i -e 's/^/    /' $PROJECT_DIR/working/vendor_prop.mk
sed -i "s|    #|#|g" $PROJECT_DIR/working/vendor_prop.mk
sed -i "s|    PRODUCT_PROPERTY_OVERRIDES|PRODUCT_PROPERTY_OVERRIDES|g" $PROJECT_DIR/working/vendor_prop.mk

# cleanup temp files
find $PROJECT_DIR/working/* ! -name 'vendor_prop.mk' -type d,f -exec rm -rf {} +
if [ -z "$2" ] && [ ! -d "$1" ]; then
    mv $PROJECT_DIR/working/vendor_prop.mk $PROJECT_DIR/working/system_prop.mk
fi

echo -e "$(ls -d $PROJECT_DIR/working/*.mk) prepared!"
