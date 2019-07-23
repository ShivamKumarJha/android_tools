#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"
ROM_PATH="$1"

# Common stuff
source $PROJECT_DIR/tools/common_script.sh "y"

proprietary_rootdir () {
	TSTART=$(grep -nr "# Misc" "$DT_DIR"/proprietary-files.txt | sed "s|:.*||g")
	TEND=$(wc -l "$DT_DIR"/proprietary-files.txt | sed "s| .*||g")
	sed -n "${TSTART},${TEND}p" "$DT_DIR"/proprietary-files.txt > "$PROJECT_DIR"/dummy_dt/working/misc.txt
	while IFS= read -r line
	do
		if grep -ril "$line" "$DT_DIR"/rootdir/; then
			if echo "$line" | grep -iE "apk|jar"; then
				echo "$line" >> "$PROJECT_DIR"/dummy_dt/working/newmisc.txt
			else
				echo "$line" >> "$PROJECT_DIR"/dummy_dt/working/rootdir.txt
			fi
		else
			echo "$line" >> "$PROJECT_DIR"/dummy_dt/working/newmisc.txt
		fi
	done < ""$PROJECT_DIR"/dummy_dt/working/misc.txt"
	TSTART=$((TSTART-1))
	sed -n "1,${TSTART}p" "$DT_DIR"/proprietary-files.txt > "$PROJECT_DIR"/dummy_dt/working/staging.txt
	echo "# rootdir" >> "$PROJECT_DIR"/dummy_dt/working/staging.txt
	cat "$PROJECT_DIR"/dummy_dt/working/rootdir.txt >> "$PROJECT_DIR"/dummy_dt/working/staging.txt
	printf "\n" >> "$PROJECT_DIR"/dummy_dt/working/staging.txt
	cat "$PROJECT_DIR"/dummy_dt/working/newmisc.txt >> "$PROJECT_DIR"/dummy_dt/working/staging.txt
	rm -rf "$PROJECT_DIR"/dummy_dt/working/misc.txt "$PROJECT_DIR"/dummy_dt/working/newmisc.txt "$PROJECT_DIR"/dummy_dt/working/rootdir.txt "$DT_DIR"/proprietary-files.txt
	mv "$PROJECT_DIR"/dummy_dt/working/staging.txt "$DT_DIR"/proprietary-files.txt
}

proprietary () {
	echo -e "${bold}${cyan}Preparing proprietary-files.txt${nocol}"
	bash $PROJECT_DIR/tools/proprietary-files.sh "$PROJECT_DIR"/dummy_dt/working/all_files.txt > /dev/null 2>&1
	cp -a $PROJECT_DIR/working/proprietary-files.txt "$DT_DIR"/proprietary-files.txt

	# find bin's in # Misc which exist in rootdir/
	proprietary_rootdir > /dev/null 2>&1

	# proprietary-files-system.txt
	echo -e "${bold}${cyan}Preparing proprietary-files-system.txt${nocol}"
	cat "$DT_DIR"/proprietary-files.txt | grep -v "vendor/" | sort -u | sed "s|#.*||g" | sed '/^$/d' > "$DT_DIR"/proprietary-files-system.txt
}

common_setup () {
	clear
	rm -rf $PROJECT_DIR/dummy_dt/working/*
	cd $PROJECT_DIR/dummy_dt/
	git clean -fd > /dev/null 2>&1
	git reset --hard > /dev/null 2>&1
	cd $PROJECT_DIR/
	echo -e "${bold}${cyan}Fetching all_files.txt & build.prop ${nocol}"
}

common_core () {
	# Variables
	source $PROJECT_DIR/tools/rom_vars.sh "$PROJECT_DIR/dummy_dt/working/system_build.prop"
	DT_DIR="$PROJECT_DIR"/dummy_dt/"$BRAND"/"$DEVICE"

	# skip or proceed
	if [ -z "$BRAND" ] || [ -z "$DEVICE" ] || [ -z "$FINGERPRINT" ] || [ -z "$VERSION" ] || [ ! -e $PROJECT_DIR/dummy_dt/working/system_build.prop ] || [ ! -e $PROJECT_DIR/dummy_dt/working/vendor_build.prop ] ; then
		echo -e "${bold}${red}Error! Skipping this device.${nocol}"
	else
		call_methods
	fi
}

call_methods () {
	# Set commit message
	if [ ! -d "$DT_DIR" ]; then
		mkdir -p "$DT_DIR"
		COMMIT_MSG=$(echo "Add: $DEVICE: $FINGERPRINT")
	else
		rm -rf "$DT_DIR"/*
		COMMIT_MSG=$(echo "Update: $DEVICE: $FINGERPRINT")
	fi

	# vendor_prop.mk
	echo -e "${bold}${cyan}Preparing vendor_prop.mk${nocol}"
	bash $PROJECT_DIR/tools/vendor_prop.sh $PROJECT_DIR/dummy_dt/working/system_build.prop $PROJECT_DIR/dummy_dt/working/vendor_build.prop > /dev/null 2>&1
	cp -a $PROJECT_DIR/working/vendor_prop.mk "$DT_DIR"/vendor_prop.mk

	# system_prop.mk
	echo -e "${bold}${cyan}Preparing system_prop.mk${nocol}"
	bash $PROJECT_DIR/tools/vendor_prop.sh $PROJECT_DIR/dummy_dt/working/system_build.prop > /dev/null 2>&1
	cp -a $PROJECT_DIR/working/system_prop.mk "$DT_DIR"/system_prop.mk

	# Device configs
	common_dt
	common_overlay

	# proprietary-files
	proprietary

	# Git commit
	git_op

	# clean
	rm -rf $PROJECT_DIR/dummy_dt/working/* $PROJECT_DIR/working/*
}

git_op () {
	cd $PROJECT_DIR/dummy_dt/
	if [[ ! -z $(git status -s) ]]; then
		echo -e "${bold}${cyan}Performing git operations${nocol}"
		git add --all > /dev/null 2>&1
		git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "$COMMIT_MSG" > /dev/null 2>&1
		if [ -z "$GIT_TOKEN" ]; then
			echo -e "${bold}${cyan}GitHub token not found! Skipping GitHub push.${nocol}"
		else
			git push https://"$GIT_TOKEN"@github.com/ShivamKumarJha/Dummy_DT.git master > /dev/null 2>&1
		fi
		COMMIT_HEAD=$(git log --format=format:%H | head -n 1)
		COMMIT_LINK=$(echo "https://github.com/ShivamKumarJha/Dummy_DT/commit/$COMMIT_HEAD")
		
		# Telegram
		echo -e "${bold}${cyan}Sending telegram notification${nocol}"
		printf "<b>Brand: $BRAND</b>" > $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<b>Device: $DEVICE</b>" >> $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<b>Model: $MODEL</b>" >> $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<b>Version:</b> $VERSION" >> $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<b>Fingerprint:</b> $FINGERPRINT" >> $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<b>GitHub:</b>" >> $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<a href=\"$COMMIT_LINK\">Commit</a>" >> $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<a href=\"https://github.com/ShivamKumarJha/Dummy_DT/commits/master/$BRAND/$DEVICE/\">History</a>" >> $PROJECT_DIR/dummy_dt/working/tg.html
		printf "\n<a href=\"https://github.com/ShivamKumarJha/Dummy_DT/tree/master/$BRAND/$DEVICE/\">$DEVICE</a>" >> $PROJECT_DIR/dummy_dt/working/tg.html
		if [ -z "$TG_API" ]; then
			echo -e "${bold}${cyan}Telegram API key not found! Skipping Telegram notification.${nocol}"
		else
			bash $PROJECT_DIR/tools/telegram.sh "$TG_API" "@dummy_dt" "$PROJECT_DIR/dummy_dt/working/tg.html" "HTML" "$PROJECT_DIR/dummy_dt/working/telegram.php" > /dev/null 2>&1
		fi
	fi
}

get_configs () {
	configs=`cat $PROJECT_DIR/dummy_dt/working/configs.txt | sort`
	for config_file in $configs; do
		if [ -z "$ROM_PATH" ]; then
			echo -e "${bold}${cyan}Downloading $config_file${nocol}"
			if echo "$config_file" | grep -iE "Bluetooth.apk|CarrierConfig.apk|framework-res.apk|modem.b16|tz.mbn" ; then
				axel -a -n64 "$device_line/$config_file" > /dev/null 2>&1 || curl -O -J -u username:$GIT_TOKEN "$device_line/$config_file" > /dev/null 2>&1
			else
				wget "$device_line/$config_file" > /dev/null 2>&1 || curl -O -J -u username:$GIT_TOKEN "$device_line/$config_file" > /dev/null 2>&1
			fi
		else
			cp -a "$ROM_PATH/$config_file" .
		fi
	done
}

common_dt () {
	echo -e "${bold}${cyan}Preparing Device tree configs${nocol}"
	cd "$DT_DIR"/
	# Audio
	mkdir -p "$DT_DIR"/configs/audio
	cd "$DT_DIR"/configs/audio
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "vendor/etc/" | grep -iE "audio_|graphite_|listen_|mixer_|sound_" | grep -v "audio_param" > $PROJECT_DIR/dummy_dt/working/configs.txt
	if grep -q "vendor/etc/audio/audio_policy_configuration.xml" $PROJECT_DIR/dummy_dt/working/configs.txt; then
		sed -i "s|vendor/etc/audio_policy_configuration.xml||g" $PROJECT_DIR/dummy_dt/working/configs.txt
		sed -i '/^$/d' $PROJECT_DIR/dummy_dt/working/configs.txt
	fi
	get_configs
	if [ -e "$DT_DIR"/configs/audio/audio_effects.conf ] && [ ! -e "$DT_DIR"/configs/audio/audio_effects.xml ]; then
		aeffects-conf2xml "$DT_DIR"/configs/audio/audio_effects.conf "$DT_DIR"/configs/audio/audio_effects.xml
	fi
	# GPS
	mkdir -p "$DT_DIR"/configs/gps
	cd "$DT_DIR"/configs/gps
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "vendor/etc" | grep -iE "apdr.conf|flp|gps|izat|lowi|sap|xtwifi" | grep ".*\.conf" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# IDC
	mkdir -p "$DT_DIR"/configs/idc
	cd "$DT_DIR"/configs/idc
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "usr/idc/" | grep -iE "fpc|goodix" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# Keylayout
	mkdir -p "$DT_DIR"/configs/keylayout
	cd "$DT_DIR"/configs/keylayout
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "usr/keylayout/" | grep -iE "fpc|goodix|gpio" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# Media
	mkdir -p "$DT_DIR"/configs/media
	cd "$DT_DIR"/configs/media
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/etc/media_|vendor/etc/system_properties.xml" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# Seccomp
	mkdir -p "$DT_DIR"/configs/seccomp
	cd "$DT_DIR"/configs/seccomp
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/etc/seccomp_policy/" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# Sensors
	mkdir -p "$DT_DIR"/configs/sensors
	cd "$DT_DIR"/configs/sensors
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/etc/sensors/hals.conf" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# WiFi
	mkdir -p "$DT_DIR"/configs/wifi
	cd "$DT_DIR"/configs/wifi
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/etc/wifi/" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# Configs
	cd "$DT_DIR"/configs/
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "excluded-input-devices.xml|privapp-permissions-qti.xml|qti_whitelist.xml|vendor/etc/msm_irqbalance|vendor/etc/public.libraries.txt|vendor/etc/sec_config" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# Rootdir
	mkdir -p "$DT_DIR"/rootdir-temp/vendor/bin "$DT_DIR"/rootdir-temp/vendor/etc/init/hw/
	cd "$DT_DIR"/rootdir-temp/vendor/bin
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "vendor/bin" | grep ".*\.sh" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	cd "$DT_DIR"/rootdir-temp/vendor/etc/init/hw/
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/etc/init/hw/" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	cd "$DT_DIR"/rootdir-temp/vendor/etc/
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/etc/fstab.qcom" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	cd "$DT_DIR"/rootdir-temp/vendor/
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/ueventd.rc" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	bash $PROJECT_DIR/tools/rootdir.sh "$DT_DIR"/rootdir-temp/ > /dev/null 2>&1
	cp -a $PROJECT_DIR/working/* "$DT_DIR"/
	rm -rf "$DT_DIR"/rootdir-temp/
	# root
	cd "$DT_DIR"/
	cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "compatibility_matrix.device.xml|vendor/compatibility_matrix.xml|vendor/manifest.xml|vendor/etc/vintf/compatibility_matrix|vendor/etc/vintf/manifest|vendor/ext_xml/compatibility_matrix|vendor/ext_xml/manifest|vendor/etc/ext_xml/compatibility_matrix|vendor/etc/ext_xml/manifest" > $PROJECT_DIR/dummy_dt/working/configs.txt
	get_configs
	# board-info.txt
	if grep -q "board-info.txt" $PROJECT_DIR/dummy_dt/working/all_files.txt; then
		cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "board-info.txt" > $PROJECT_DIR/dummy_dt/working/configs.txt
		get_configs
	else
		cd $PROJECT_DIR/dummy_dt/working/
		cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "modem.b16|tz.mbn" > $PROJECT_DIR/dummy_dt/working/configs.txt
		get_configs
		if [ -e modem.b16 ]; then
			strings modem.b16 | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> "$DT_DIR"/board-info.txt
		fi
		if [ -e tz.mbn ]; then
			strings tz.mbn | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> "$DT_DIR"/board-info.txt
		fi
		strings vendor_build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> "$DT_DIR"/board-info.txt
	fi
	# device.mk
	bash $PROJECT_DIR/tools/dt_mk.sh "$DT_DIR"
	# Inherit vendor
	printf "# Inherit vendor" >> "$DT_DIR"/device.mk
	printf "\n\$(call inherit-product, vendor/"$BRAND"/"$DEVICE"/"$DEVICE"-vendor.mk)" >> "$DT_DIR"/device.mk
	# Android.mk
	printf "LOCAL_PATH := \$(call my-dir)" >> "$DT_DIR"/Android.mk
	printf "\nifeq (\$(TARGET_DEVICE),"$DEVICE")" >> "$DT_DIR"/Android.mk
	printf "\ninclude \$(call all-makefiles-under,\$(LOCAL_PATH))" >> "$DT_DIR"/Android.mk
	printf "\ninclude \$(CLEAR_VARS)\nendif" >> "$DT_DIR"/Android.mk
	# AndroidProducts.mk
	printf "PRODUCT_MAKEFILES := \\" >> "$DT_DIR"/AndroidProducts.mk
	printf "\n    \$(LOCAL_DIR)/lineage_"$DEVICE".mk" >> "$DT_DIR"/AndroidProducts.mk
	# BoardConfig.mk
	printf "DEVICE_PATH := device/"$BRAND"/"$DEVICE"" >> "$DT_DIR"/BoardConfig.mk
	printf "\nBOARD_VENDOR := "$BRAND"\n" >> "$DT_DIR"/BoardConfig.mk
	if [ "$VERSION" -gt 8 ]; then
		printf "\n# Security patch level\nVENDOR_SECURITY_PATCH := "$SECURITY_PATCH"\n" >> "$DT_DIR"/BoardConfig.mk
	fi
	if [ -e "$DT_DIR"/manifest.xml ]; then
		printf "\n# HIDL" >> "$DT_DIR"/BoardConfig.mk
		printf "\nDEVICE_MANIFEST_FILE := \$(DEVICE_PATH)/manifest.xml" >> "$DT_DIR"/BoardConfig.mk
	fi
	if [ -e "$DT_DIR"/android.hardware.cas@1.1-service.xml ]; then
		printf "\nDEVICE_MANIFEST_FILE += \$(DEVICE_PATH)/android.hardware.cas@1.1-service.xml" >> "$DT_DIR"/BoardConfig.mk
	fi
	if [ -e "$DT_DIR"/compatibility_matrix.xml ]; then
		printf "\nDEVICE_MATRIX_FILE := \$(DEVICE_PATH)/compatibility_matrix.xml" >> "$DT_DIR"/BoardConfig.mk
	fi
	if [ -e "$DT_DIR"/compatibility_matrix.device.xml ]; then
		mv "$DT_DIR"/compatibility_matrix.device.xml "$DT_DIR"/framework_compatibility_matrix.xml
		printf "\nDEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE := \$(DEVICE_PATH)/framework_compatibility_matrix.xml" >> "$DT_DIR"/BoardConfig.mk
	fi
	printf "\n\n-include vendor/"$BRAND"/"$DEVICE"/BoardConfigVendor.mk" >> "$DT_DIR"/BoardConfig.mk
	# lineage_"$DEVICE".mk
	printf "# Inherit from those products. Most specific first." >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\n\$(call inherit-product, \$(SRC_TARGET_DIR)/product/core_64_bit.mk)" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\n\$(call inherit-product, \$(SRC_TARGET_DIR)/product/full_base_telephony.mk)" >> "$DT_DIR"/lineage_"$DEVICE".mk
	if [ $(grep "ro.build.version.release=" $PROJECT_DIR/dummy_dt/working/system_build.prop | sed "s|ro.build.version.release=||g" | head -c 1) -eq 8 ]; then
		printf "\n\$(call inherit-product, \$(SRC_TARGET_DIR)/product/product_launched_with_o_mr1.mk)" >> "$DT_DIR"/lineage_"$DEVICE".mk
	fi
	if [ $(grep "ro.build.version.release=" $PROJECT_DIR/dummy_dt/working/system_build.prop | sed "s|ro.build.version.release=||g" | head -c 1) -eq 9 ]; then
		printf "\n\$(call inherit-product, \$(SRC_TARGET_DIR)/product/product_launched_with_p.mk)" >> "$DT_DIR"/lineage_"$DEVICE".mk
	fi
	printf "\n\n# Inherit some common Lineage stuff" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\n\$(call inherit-product, vendor/lineage/config/common_full_phone.mk)" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\n\n# Inherit from "$DEVICE" device" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\n\$(call inherit-product, \$(LOCAL_PATH)/device.mk)" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\n\nPRODUCT_BRAND := "$BRAND"" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\nPRODUCT_DEVICE := "$DEVICE"" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\nPRODUCT_MANUFACTURER := "$BRAND"" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\nPRODUCT_NAME := lineage_"$DEVICE"\n" >> "$DT_DIR"/lineage_"$DEVICE".mk
	echo "PRODUCT_MODEL := "$MODEL"" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\nPRODUCT_GMS_CLIENTID_BASE := android-"$BRAND"" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\nTARGET_VENDOR := "$BRAND"" >> "$DT_DIR"/lineage_"$DEVICE".mk
	printf "\nTARGET_VENDOR_PRODUCT_NAME := "$DEVICE"\n" >> "$DT_DIR"/lineage_"$DEVICE".mk
	if [ ! -z "$DESCRIPTION" ]; then
		echo "PRODUCT_BUILD_PROP_OVERRIDES += PRIVATE_BUILD_DESC=\""$DESCRIPTION"\"" >> "$DT_DIR"/lineage_"$DEVICE".mk
	fi
	printf "\n# Set BUILD_FINGERPRINT variable to be picked up by both system and vendor build.prop\n" >> "$DT_DIR"/lineage_"$DEVICE".mk
	echo "BUILD_FINGERPRINT := "$FINGERPRINT"" >> "$DT_DIR"/lineage_"$DEVICE".mk
}

common_overlay () {
	mkdir -p "$PROJECT_DIR"/working/overlays
	cd "$PROJECT_DIR"/working/overlays
	cat "$PROJECT_DIR"/dummy_dt/working/all_files.txt | grep -iE "framework/framework-res.apk|app/CarrierConfig/CarrierConfig.apk|app/Bluetooth/Bluetooth.apk" > "$PROJECT_DIR"/dummy_dt/working/configs.txt
	get_configs
	ovlist=`find "$PROJECT_DIR"/working/overlays -maxdepth 1 -type f -printf '%P\n' | sort`
	for list in $ovlist ;
	do
		echo -e "${bold}${cyan}Extracting $list${nocol}"
		apktool -f d "$list" > /dev/null 2>&1
	done
	mkdir -p "$DT_DIR"/overlay/frameworks/base/core/res/res/xml/ "$DT_DIR"/overlay/packages/apps/CarrierConfig/res/xml "$DT_DIR"/overlay/frameworks/base/core/res/res/values/ "$DT_DIR"/overlay/packages/apps/Bluetooth/res/values
	cp -a "$PROJECT_DIR"/working/overlays/framework-res/res/xml/power_profile.xml "$DT_DIR"/overlay/frameworks/base/core/res/res/xml/power_profile.xml > /dev/null 2>&1
	cp -a "$PROJECT_DIR"/working/overlays/Bluetooth/res/values/bools.xml "$DT_DIR"/overlay/packages/apps/Bluetooth/res/values/bools.xml > /dev/null 2>&1
	cp -a "$PROJECT_DIR"/working/overlays/CarrierConfig/res/xml/* "$DT_DIR"/overlay/packages/apps/CarrierConfig/res/xml/ > /dev/null 2>&1
	# Extract overlay configs
	ovlist=`find "$PROJECT_DIR"/tools/lists/overlays/ -maxdepth 1 -type f -printf '%P\n' | sort`
	for list in $ovlist ;
	do
		overlay_configs=`cat "$PROJECT_DIR"/tools/lists/overlays/"$list" | sort`
		for overlay_line in $overlay_configs;
		do
			if grep -q "\""$overlay_line"\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/"$list".xml; then
				if [ -e "$PROJECT_DIR"/tools/lists/overlays/comments/"$overlay_line" ]; then
					printf "\n" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
					cat "$PROJECT_DIR"/tools/lists/overlays/comments/"$overlay_line" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
				fi
				echo "    " $(cat "$PROJECT_DIR"/working/overlays/framework-res/res/values/"$list".xml | grep "\""$overlay_line"\">") >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
			fi
		done
	done
	# integer arrays
	overlay_configs=`cat $PROJECT_DIR/tools/lists/overlays/arrays/integer-array | sort`
	for target in $overlay_configs;
	do
		TSTART=$(grep -n "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g")
		if [ ! -z "$TSTART" ]; then
			configs=`grep -n "</integer-array>" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g"`
			for config_file in $configs;
			do
				TEND="$config_file"
				if [ ! -z "$TEND" ] && [ "$TEND" -gt "$TSTART" ]; then
					break
				fi
			done
			if grep -q "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml; then
				if [ -e "$PROJECT_DIR"/tools/lists/overlays/comments/"$target" ]; then
					printf "\n" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
					cat "$PROJECT_DIR"/tools/lists/overlays/comments/"$target" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
				fi
				sed -n "${TSTART},${TEND}p" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
			fi
		fi
	done
	# string arrays
	overlay_configs=`cat $PROJECT_DIR/tools/lists/overlays/arrays/string-array | sort`
	for target in $overlay_configs;
	do
		TSTART=$(grep -n "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g")
		if [ ! -z "$TSTART" ]; then
			configs=`grep -n "</string-array>" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g"`
			for config_file in $configs;
			do
				TEND="$config_file"
				if [ ! -z "$TEND" ] && [ "$TEND" -gt "$TSTART" ]; then
					break
				fi
			done
			if grep -q "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml; then
				if [ -e "$PROJECT_DIR"/tools/lists/overlays/comments/"$target" ]; then
					printf "\n" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
					cat "$PROJECT_DIR"/tools/lists/overlays/comments/"$target" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
				fi
				sed -n "${TSTART},${TEND}p" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
			fi
		fi
	done

	# Make xml proper
	mv "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml "$DT_DIR"/overlay/frameworks/base/core/res/res/values/staging.xml
	cat "$PROJECT_DIR"/tools/lists/overlays/comments/HEADER "$DT_DIR"/overlay/frameworks/base/core/res/res/values/staging.xml > "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
	printf "\n</resources>" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
	rm -rf "$DT_DIR"/overlay/frameworks/base/core/res/res/values/staging.xml
}

# Init git if not already
if [ ! -d "$PROJECT_DIR"/dummy_dt/ ] && [ ! -z "$GIT_TOKEN" ]; then
	echo -e "${bold}${cyan}Cloning Dummy_DT${nocol}"
	git clone -q https://"$GIT_TOKEN"@github.com/ShivamKumarJha/Dummy_DT.git "$PROJECT_DIR"/dummy_dt
fi

# Create working directory if it does not exist
if [ ! -d "$PROJECT_DIR"/dummy_dt/working ]; then
	mkdir -p "$PROJECT_DIR"/dummy_dt/working
fi

# from roms.txt
if [ -z "$ROM_PATH" ] || [ ! -d "$ROM_PATH" ]; then
	devices=`cat $PROJECT_DIR/tools/lists/roms.txt | sort`
	for device_line in $devices;
	do
		# setup
		common_setup
		wget -O $PROJECT_DIR/dummy_dt/working/all_files.txt "$device_line"/all_files.txt > /dev/null 2>&1
		if ! grep -q "system/system/" $PROJECT_DIR/dummy_dt/working/all_files.txt; then
			wget -O $PROJECT_DIR/dummy_dt/working/system_build.prop "$device_line"/system/build.prop > /dev/null 2>&1
		else
			wget -O $PROJECT_DIR/dummy_dt/working/system_build.prop "$device_line"/system/system/build.prop > /dev/null 2>&1
		fi
		wget -O $PROJECT_DIR/dummy_dt/working/vendor_build.prop "$device_line"/vendor/build.prop > /dev/null 2>&1

		# operation
		common_core
	done
else
# local dumps
	for var in "$@"
	do
		# setup
		ROM_PATH=$( realpath "$var" )
		if [ -e "$ROM_PATH"/system/system/build.prop ]; then
			SYSTEM_PATH="system/system"
		elif [ -e "$ROM_PATH"/system/build.prop ]; then
			SYSTEM_PATH="system"
		fi
		common_setup
		find "$ROM_PATH" -type f -printf '%P\n' | sort > $PROJECT_DIR/dummy_dt/working/all_files.txt
		find "$ROM_PATH/$SYSTEM_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/dummy_dt/working/system_build.prop \;
		find "$ROM_PATH/vendor/" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/dummy_dt/working/vendor_build.prop \;

		# operation
		common_core
	done
fi

echo -e "${bold}${cyan}Finished!${nocol}"
