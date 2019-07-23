#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/tools/common_script.sh "y"

# Exit if no arguements
if [ -z "$1" ] ; then
	echo -e "${bold}${red}Supply sytem &/ vendor build.prop as arguements!${nocol}"
	exit
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
	find "$1/$SYSTEM_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/system_working.prop \;
	find "$1/vendor" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/working/vendor_working.prop \;
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

# system.prop
TSTART=$(grep -nr "# end build properties" $PROJECT_DIR/working/system_working.prop | sed "s|:.*||g")
TEND=$(grep -nr "# ADDITIONAL_BUILD_PROPERTIES" $PROJECT_DIR/working/system_working.prop | sed "s|:.*||g")
sed -n "${TSTART},${TEND}p" $PROJECT_DIR/working/system_working.prop | sort | sed "s|#.*||g" | sed '/^[[:space:]]*$/d' > $PROJECT_DIR/working/system_new.prop

# vendor.prop
if [ ! -z "$2" ] || [ -e $PROJECT_DIR/working/vendor_working.prop ]; then
	TSTART=$(grep -nr "ADDITIONAL VENDOR BUILD PROPERTIES" $PROJECT_DIR/working/vendor_working.prop | sed "s|:.*||g")
	TEND=$(wc -l $PROJECT_DIR/working/vendor_working.prop | sed "s| .*||g")
	sed -n "${TSTART},${TEND}p" $PROJECT_DIR/working/vendor_working.prop | sort | sed "s|#.*||g" | sed '/^[[:space:]]*$/d' > $PROJECT_DIR/working/vendor_new.prop
fi

# Lineage vendor security patch support
if [ $(grep "ro.build.version.release=" $PROJECT_DIR/working/system_working.prop | sed "s|ro.build.version.release=||g" | head -c 2) -lt 9 ]; then
	grep "ro.build.version.security_patch=" $PROJECT_DIR/working/system_working.prop | sed "s|ro.build.version.security_patch|ro.lineage.build.vendor_security_patch|g" >> $PROJECT_DIR/working/staging.mk
fi

# Combine newly generated system.prop & vendor.prop
if [ ! -z "$2" ] || [ -e $PROJECT_DIR/working/vendor_working.prop ]; then
	echo "$(cat $PROJECT_DIR/working/system_new.prop $PROJECT_DIR/working/vendor_new.prop | sort -u )" >> $PROJECT_DIR/working/staging.mk
else
	echo "$(cat $PROJECT_DIR/working/system_new.prop | sort -u )" >> $PROJECT_DIR/working/staging.mk
fi

if ! grep -q "ro.sf.lcd_density=" $PROJECT_DIR/working/staging.mk; then
	echo "ro.sf.lcd_density=440" >> $PROJECT_DIR/working/staging.mk
fi

# Cleanup unrequired prop's
sed -i "s|dalvik.vm.heapsize=36m||g" $PROJECT_DIR/working/staging.mk
sed -i "s|media.settings.xml=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.sys.mcd_config_file.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.miui.density.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.miui.notch.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.build.fota.version=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.build.software.version=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.build.version.incremental=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.vendor.build.fingerprint.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.rild.nitz_.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.vendor.overlay.izat.optin=rro||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.hwui.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|qemu.hw.mainkeys=0||g" $PROJECT_DIR/working/staging.mk
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
sed -i "s|asus.app-prebuilt.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.asus.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.asus.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.sys.disable_rescue=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.sys.enable_rescue=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|persist.sys.onehandctrl.enable=.*||g" $PROJECT_DIR/working/staging.mk
sed -i "s|ro.product.first_api_level=.*||g" $PROJECT_DIR/working/staging.mk
sed '/^$/d' $PROJECT_DIR/working/staging.mk | sort -u > $PROJECT_DIR/working/temp.mk

# Prop's grouping
mkdir -p $PROJECT_DIR/working/lists/
# Audio
cat $PROJECT_DIR/working/temp.mk | grep -iE "audio|af.|ro.af.|ro.config.media|ro.config.vc_call|dirac.|av.|voice." | sort -u > $PROJECT_DIR/working/lists/Audio
# Bluetooth
cat $PROJECT_DIR/working/temp.mk | grep -iE "bt.|bluetooth" | sort -u > $PROJECT_DIR/working/lists/Bluetooth
# Camera
cat $PROJECT_DIR/working/temp.mk | grep -iE "ts.|camera" | grep -v "dalvik" | sort -u > $PROJECT_DIR/working/lists/Camera
# Charging
cat $PROJECT_DIR/working/temp.mk | grep -iE "persist.chg|chg.|cutoff_voltage_mv" | sort -u > $PROJECT_DIR/working/lists/Charging
# CNE
cat $PROJECT_DIR/working/temp.mk | grep -iE "cne." | sort -u > $PROJECT_DIR/working/lists/CNE
# Crypto
cat $PROJECT_DIR/working/temp.mk | grep -iE "crypto." | sort -u > $PROJECT_DIR/working/lists/Crypto
# Dalvik
cat $PROJECT_DIR/working/temp.mk | grep -iE "dalvik" | sort -u > $PROJECT_DIR/working/lists/Dalvik
# DPM
cat $PROJECT_DIR/working/temp.mk | grep -iE "dpm." | sort -u > $PROJECT_DIR/working/lists/DPM
# DRM
cat $PROJECT_DIR/working/temp.mk | grep -iE "drm" | sort -u > $PROJECT_DIR/working/lists/DRM
# FM
cat $PROJECT_DIR/working/temp.mk | grep -iE "fm." | sort -u > $PROJECT_DIR/working/lists/FM
# FRP
cat $PROJECT_DIR/working/temp.mk | grep -iE "frp." | sort -u > $PROJECT_DIR/working/lists/FRP
# FUSE
cat $PROJECT_DIR/working/temp.mk | grep -iE "fuse" | sort -u > $PROJECT_DIR/working/lists/FUSE
# Graphics
cat $PROJECT_DIR/working/temp.mk | grep -iE "debug.sf.|gralloc|hwui|dev.pm.|hdmi|opengles|lcd_density|display|rotator_downscale|debug.egl.hw" | sort -u > $PROJECT_DIR/working/lists/Graphics
# Location
cat $PROJECT_DIR/working/temp.mk | grep -iE "location" | sort -u > $PROJECT_DIR/working/lists/Location
# Media
cat $PROJECT_DIR/working/temp.mk | grep -iE "media.|mm.|mmp.|vidc.|aac." | grep -v "audio" | grep -v "bt." | sort -u > $PROJECT_DIR/working/lists/Media
# Netflix
cat $PROJECT_DIR/working/temp.mk | grep -iE "netflix" | sort -u > $PROJECT_DIR/working/lists/Netflix
# Netmgr
cat $PROJECT_DIR/working/temp.mk | grep -iE "netmgrd|data.mode" | sort -u > $PROJECT_DIR/working/lists/Netmgr
# NFC
cat $PROJECT_DIR/working/temp.mk | grep -iE "nfc" | sort -u > $PROJECT_DIR/working/lists/NFC
# NTP
cat $PROJECT_DIR/working/temp.mk | grep -iE "ntpServer" | sort -u > $PROJECT_DIR/working/lists/NTP
# Perf
cat $PROJECT_DIR/working/temp.mk | grep -iE "perf." | sort -u > $PROJECT_DIR/working/lists/Perf
# QTI
cat $PROJECT_DIR/working/temp.mk | grep -iE "qti" | sort -u > $PROJECT_DIR/working/lists/QTI
# Radio
cat $PROJECT_DIR/working/temp.mk | grep -iE "DEVICE_PROVISIONED|persist.data|radio|ril.|rild.|ro.carrier|dataroaming|telephony" | sort -u > $PROJECT_DIR/working/lists/Radio
# Sensors
cat $PROJECT_DIR/working/temp.mk | grep -iE "sensors." | sort -u > $PROJECT_DIR/working/lists/Sensors
# Skip_validate
cat $PROJECT_DIR/working/temp.mk | grep -iE "skip_validate" | sort -u > $PROJECT_DIR/working/lists/Skip_validate
# Shutdown
cat $PROJECT_DIR/working/temp.mk | grep -iE "shutdown" | sort -u > $PROJECT_DIR/working/lists/Shutdown
# SSR
cat $PROJECT_DIR/working/temp.mk | grep -iE "ssr." | grep -v "audio" | sort -u > $PROJECT_DIR/working/lists/SSR
# Thermal
cat $PROJECT_DIR/working/temp.mk | grep -iE "thermal." | sort -u > $PROJECT_DIR/working/lists/Thermal
# Time
cat $PROJECT_DIR/working/temp.mk | grep -iE "timed." | sort -u > $PROJECT_DIR/working/lists/Time
# UBWC
cat $PROJECT_DIR/working/temp.mk | grep -iE "ubwc" | sort -u > $PROJECT_DIR/working/lists/UBWC
# USB
cat $PROJECT_DIR/working/temp.mk | grep -iE "usb." | grep -v "audio" | sort -u > $PROJECT_DIR/working/lists/USB
# WFD
cat $PROJECT_DIR/working/temp.mk | grep -iE "wfd." | sort -u > $PROJECT_DIR/working/lists/WFD
# WLAN
cat $PROJECT_DIR/working/temp.mk | grep -iE "wlan." | sort -u > $PROJECT_DIR/working/lists/WLAN
# ZRAM
cat $PROJECT_DIR/working/temp.mk | grep -iE "zram" | sort -u > $PROJECT_DIR/working/lists/ZRAM

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

# var for my format o/p. staging hence use untill ready.
WILL_CHECK=n

# Add props from lists
props_list=`find $PROJECT_DIR/working/lists -type f -printf '%P\n' | sort`
for list in $props_list; do
	if [ "$WILL_CHECK" == "y" ]; then
		echo "# $list" >> $PROJECT_DIR/working/temp_prop.mk
		echo "PRODUCT_PROPERTY_OVERRIDES += \\" >> $PROJECT_DIR/working/temp_prop.mk
	fi
	awk 'NF{print $0 " \\"}' $PROJECT_DIR/working/lists/$list >> $PROJECT_DIR/working/temp_prop.mk
done

# Remove duplicate props & text formatting
awk '/^PRODUCT_PROPERTY_OVERRIDES/ || !seen[$0]++' $PROJECT_DIR/working/temp_prop.mk > $PROJECT_DIR/working/vendor_prop.mk
sed -i -e 's/^/    /' $PROJECT_DIR/working/vendor_prop.mk
if [ "$WILL_CHECK" == "y" ]; then
	sed -i "s|    #|#|g" $PROJECT_DIR/working/vendor_prop.mk
	sed -i "s|    PRODUCT_PROPERTY_OVERRIDES|PRODUCT_PROPERTY_OVERRIDES|g" $PROJECT_DIR/working/vendor_prop.mk
else
	sed -i '1 i\PRODUCT_PROPERTY_OVERRIDES += \\' $PROJECT_DIR/working/vendor_prop.mk
fi

# cleanup temp files
find $PROJECT_DIR/working/* ! -name 'vendor_prop.mk' -type d,f -exec rm -rf {} +
if [ -z "$2" ] && [ ! -d "$1" ]; then
	mv $PROJECT_DIR/working/vendor_prop.mk $PROJECT_DIR/working/system_prop.mk
fi

echo -e "${bold}${cyan}$(ls -d $PROJECT_DIR/working/*.mk) prepared!${nocol}"
