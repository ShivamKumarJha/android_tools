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

proprietary_rootdir () {
    TSTART=$(grep -nr "# Misc" "$DT_DIR"/proprietary-files.txt | sed "s|:.*||g" | head -1)
    TEND=$(wc -l "$DT_DIR"/proprietary-files.txt | sed "s| .*||g" | head -1)
    sed -n "${TSTART},${TEND}p" "$DT_DIR"/proprietary-files.txt > "$PROJECT_DIR"/dummy_dt/working/misc.txt
    while IFS= read -r line; do
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
    [[ "$VERBOSE" != "n" ]] && echo -e "Preparing proprietary-files.txt"
    bash $PROJECT_DIR/tools/proprietary-files.sh "$PROJECT_DIR"/dummy_dt/working/all_files.txt > /dev/null 2>&1
    cp -a $PROJECT_DIR/working/proprietary-files.txt "$DT_DIR"/proprietary-files.txt
    # find bin's in # Misc which exist in rootdir/
    proprietary_rootdir > /dev/null 2>&1
    # proprietary-files-system.txt
    cat "$DT_DIR"/proprietary-files.txt | grep -v "vendor/" | sort -u | sed "s|#.*||g" | sed '/^$/d' > "$DT_DIR"/proprietary-files-system.txt
}

common_core () {
    # Variables
    source $PROJECT_DIR/helpers/rom_vars.sh "$ROM_PATH" > /dev/null 2>&1
    DT_DIR="$PROJECT_DIR"/dummy_dt/"$BRAND"/"$DEVICE"
    DT_REPO=$(echo device_$BRAND\_$DEVICE)
    DT_REPO_DESC=$(echo "Dummy device tree for $MODEL")
    VT_REPO=$(echo vendor_$BRAND\_$DEVICE)
    VT_REPO_DESC=$(echo "Vendor tree for $MODEL")

    # skip or proceed
    if [ -z "$BRAND" ] || [ -z "$DEVICE" ] || [ -z "$FINGERPRINT" ] || [ -z "$VERSION" ] || [ ! -e $PROJECT_DIR/dummy_dt/working/system_build.prop ] || [ ! -e $PROJECT_DIR/dummy_dt/working/vendor_build.prop ] ; then
        echo -e "Dummy DT: Error! Empty var!"
    elif [[ "$VERSION" -lt 8 ]]; then
        echo -e "Dummy DT: Error! Pre-Oreo ROM's not supported!"
    else
        echo -e "Preparing Dummy DT"
        call_methods
    fi
}

call_methods () {
    rm -rf "$DT_DIR" && mkdir -p "$DT_DIR"
    # create repo's
    if [[ "$ORGMEMBER" == "y" ]] && [[ ! -z "$GIT_TOKEN" ]]; then
        ORG="AndroidBlobs"
        GITHUB_EMAIL="${ORG}@github.com"
        curl -s -X POST -H "Authorization: token ${GIT_TOKEN}" -d '{"name": "'"$DT_REPO"'","description": "'"$DT_REPO_DESC"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' "https://api.github.com/orgs/$ORG/repos" > /dev/null 2>&1
        curl -s -X POST -H "Authorization: token ${GIT_TOKEN}" -d '{"name": "'"$VT_REPO"'","description": "'"$VT_REPO_DESC"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' "https://api.github.com/orgs/$ORG/repos" > /dev/null 2>&1
        curl -s -X PUT -H "Authorization: token ${GIT_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d '{ "names": ["'"$TOPIC1"'","'"$TOPIC2"'","'"$TOPIC3"'"]}' "https://api.github.com/repos/${ORG}/${DT_REPO}/topics" > /dev/null 2>&1
        curl -s -X PUT -H "Authorization: token ${GIT_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d '{ "names": ["'"$TOPIC1"'","'"$TOPIC2"'","'"$TOPIC3"'"]}' "https://api.github.com/repos/${ORG}/${VT_REPO}/topics" > /dev/null 2>&1
    elif [[ ! -z "$GIT_TOKEN" ]] && [[ ! -z "$GITHUB_EMAIL" ]] && [[ ! -z "$GITHUB_USER" ]]; then
        ORG="$GITHUB_USER"
        curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$DT_REPO"'","description": "'"$DT_REPO_DESC"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
        curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$VT_REPO"'","description": "'"$VT_REPO_DESC"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
    fi
    [[ ! -z "$GIT_TOKEN" ]] && wget "https://raw.githubusercontent.com/$ORG/$DT_REPO/$BRANCH/Android.mk" -O "$PROJECT_DIR/dummy_dt/working/check" 2>/dev/null && echo "Dummy DT already done!" && exit 1

    # DummyDT
    [[ "$VERBOSE" != "n" ]] && echo -e "Preparing vendor_prop.mk"
    bash $PROJECT_DIR/tools/vendor_prop.sh ${ROM_PATH} > /dev/null 2>&1
    cp -a $PROJECT_DIR/working/* "$DT_DIR"/
    common_dt
    common_overlay > /dev/null 2>&1
    proprietary
    # oppo_product
    [[ -e ${ROM_PATH}/oppo_product/etc/audio_policy_configuration.xml ]] && cat ${ROM_PATH}/oppo_product/etc/audio_policy_configuration.xml > "$DT_DIR"/configs/audio/audio_policy_configuration.xml
    [[ -e ${ROM_PATH}/oppo_product/etc/power_profile/power_profile.xml ]] && cat ${ROM_PATH}/oppo_product/etc/power_profile/power_profile.xml > "$DT_DIR"/overlay/frameworks/base/core/res/res/xml/power_profile.xml
    # Git commit
    [[ ! -z "$ORG" ]] && git_op
    # clean
    rm -rf $PROJECT_DIR/dummy_dt/working/* $PROJECT_DIR/working/*
}

git_op () {
    cd "$DT_DIR"
    [[ "$VERBOSE" != "n" ]] && echo -e "Pushing DummyDT"
    git init . > /dev/null 2>&1
    git checkout -b $BRANCH > /dev/null 2>&1
    git add --all > /dev/null 2>&1
    git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "$DESCRIPTION" > /dev/null 2>&1
    git push https://"$GIT_TOKEN"@github.com/"$ORG"/"$DT_REPO".git --all > /dev/null 2>&1
    echo -e "Dumping blobs"
    rm -rf "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"/
    cp -a "$DT_DIR"/proprietary-files.txt "$PROJECT_DIR"/working/proprietary-files.txt
    cd "$PROJECT_DIR"
    bash "$PROJECT_DIR/helpers/extract_blobs/extract-files.sh" "$ROM_PATH" > /dev/null 2>&1
    cd "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"
    git init . > /dev/null 2>&1
    find -size +97M -printf '%P\n' -o -name *sensetime* -printf '%P\n' -o -name *.lic -printf '%P\n' > .gitignore
    git checkout -b $BRANCH > /dev/null 2>&1
    git add --all > /dev/null 2>&1
    git -c "user.name=$ORG" -c "user.email=$GITHUB_EMAIL" commit -sm "$DESCRIPTION" > /dev/null 2>&1
    git push https://"$GIT_TOKEN"@github.com/"$ORG"/"$VT_REPO".git --all > /dev/null 2>&1
    # Telegram
    if [ ! -z "$TG_API" ] && [[ "$ORGMEMBER" == "y" ]]; then
        [[ "$VERBOSE" != "n" ]] && echo -e "Sending telegram notification"
        printf "<b>Brand: $BRAND</b>" > $PROJECT_DIR/dummy_dt/working/tg.html
        printf "\n<b>Device: $DEVICE</b>" >> $PROJECT_DIR/dummy_dt/working/tg.html
        printf "\n<b>Model: $MODEL</b>" >> $PROJECT_DIR/dummy_dt/working/tg.html
        printf "\n<b>Version:</b> $VERSION" >> $PROJECT_DIR/dummy_dt/working/tg.html
        printf "\n<b>Fingerprint:</b> $FINGERPRINT" >> $PROJECT_DIR/dummy_dt/working/tg.html
        [[ ! -z "$PLATFORM" ]] && printf "\n<b>Platform:</b> $PLATFORM" >> $PROJECT_DIR/dummy_dt/working/tg.html
        printf "\n<b>GitHub:</b>" >> $PROJECT_DIR/dummy_dt/working/tg.html
        printf "\n<a href=\"https://github.com/$ORG/$DT_REPO/tree/$BRANCH/\">Device tree</a>" >> $PROJECT_DIR/dummy_dt/working/tg.html
        printf "\n<a href=\"https://github.com/$ORG/$VT_REPO/tree/$BRANCH/\">Vendor tree</a>" >> $PROJECT_DIR/dummy_dt/working/tg.html
        CHAT_ID="@dummy_dt"
        HTML_FILE=$(cat $PROJECT_DIR/dummy_dt/working/tg.html)
        curl -s "https://api.telegram.org/bot${TG_API}/sendmessage" --data "text=${HTML_FILE}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" > /dev/null 2>&1
    fi
}

get_configs () {
    configs=`cat $PROJECT_DIR/dummy_dt/working/configs.txt | sort`
    for config_file in $configs; do
        cp -a "$ROM_PATH/$config_file" .
    done
}

common_dt () {
    [[ "$VERBOSE" != "n" ]] && echo -e "Preparing Device tree configs"
    cd "$DT_DIR"/
    # Audio
    mkdir -p "$DT_DIR"/configs/audio
    cd "$DT_DIR"/configs/audio
    cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "vendor/etc/" | grep -iE "audio_|graphite_|listen_|mixer_|sound_" | grep -v "audio_param\|boot_sound/" > $PROJECT_DIR/dummy_dt/working/configs.txt
    if grep -q "vendor/etc/audio/audio_policy_configuration.xml" $PROJECT_DIR/dummy_dt/working/configs.txt; then
        sed -i "s|.*/etc/audio_policy_configuration.xml||g" $PROJECT_DIR/dummy_dt/working/configs.txt
        sed -i '/^$/d' $PROJECT_DIR/dummy_dt/working/configs.txt
    fi
    get_configs
    if [ -e "$DT_DIR"/configs/audio/audio_effects.conf ] && [ ! -e "$DT_DIR"/configs/audio/audio_effects.xml ]; then
        "$PROJECT_DIR"/helpers/prebuilt/aeffects-conf2xml "$DT_DIR"/configs/audio/audio_effects.conf "$DT_DIR"/configs/audio/audio_effects.xml
    fi
    # GPS
    mkdir -p "$DT_DIR"/configs/gps
    cd "$DT_DIR"/configs/gps
    cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "vendor/etc" | grep -iE "apdr|flp|gps|izat|lowi|sap|xtwifi" | grep ".*\.conf" > $PROJECT_DIR/dummy_dt/working/configs.txt
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
    cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep -iE "vendor/etc/fstab" > $PROJECT_DIR/dummy_dt/working/configs.txt
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
    fi
    # device.mk
    bash $PROJECT_DIR/helpers/dt_mk.sh "$DT_DIR"
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
    file_lines=$( cat $PROJECT_DIR/dummy_dt/working/all_files.txt | grep "vendor/etc/vintf/manifest/" | sed "s|vendor/etc/vintf/manifest/||g" )
    for line in $file_lines; do
        if [ -e $DT_DIR/$line ]; then
            printf "\nDEVICE_MANIFEST_FILE += \$(DEVICE_PATH)/$line" >> "$DT_DIR"/BoardConfig.mk
        fi
    done
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
    echo "PRODUCT_BUILD_PROP_OVERRIDES += PRIVATE_BUILD_DESC=\""$DESCRIPTION"\"" >> "$DT_DIR"/lineage_"$DEVICE".mk
    printf "\n# Set BUILD_FINGERPRINT variable to be picked up by both system and vendor build.prop\n" >> "$DT_DIR"/lineage_"$DEVICE".mk
    echo "BUILD_FINGERPRINT := "$FINGERPRINT"" >> "$DT_DIR"/lineage_"$DEVICE".mk
}

common_overlay () {
    mkdir -p "$PROJECT_DIR"/working/overlays "$DT_DIR"/overlay/frameworks/base/core/res/res/xml/ "$DT_DIR"/overlay/packages/apps/CarrierConfig/res/xml "$DT_DIR"/overlay/frameworks/base/core/res/res/values/ "$DT_DIR"/overlay/packages/apps/Bluetooth/res/values "$DT_DIR"/overlay-lineage/lineage-sdk/lineage/res/res/values
    cd "$PROJECT_DIR"/working/overlays
    cat "$PROJECT_DIR"/dummy_dt/working/all_files.txt | grep -iE "priv-app/SystemUI/SystemUI.apk|framework/framework-res.apk|app/CarrierConfig/CarrierConfig.apk|app/Bluetooth/Bluetooth.apk" > "$PROJECT_DIR"/dummy_dt/working/configs.txt
    get_configs
    ovlist=`find "$PROJECT_DIR"/working/overlays -maxdepth 1 -type f -printf '%P\n' | sort`
    for list in $ovlist; do
        [[ "$VERBOSE" != "n" ]] && echo -e "Extracting $list"
        $PROJECT_DIR/helpers/prebuilt/apktool -f d "$list" > /dev/null 2>&1
    done
    cp -a "$PROJECT_DIR"/working/overlays/framework-res/res/xml/power_profile.xml "$DT_DIR"/overlay/frameworks/base/core/res/res/xml/power_profile.xml > /dev/null 2>&1
    cp -a "$PROJECT_DIR"/working/overlays/Bluetooth/res/values/bools.xml "$DT_DIR"/overlay/packages/apps/Bluetooth/res/values/bools.xml > /dev/null 2>&1
    cp -a "$PROJECT_DIR"/working/overlays/CarrierConfig/res/xml/* "$DT_DIR"/overlay/packages/apps/CarrierConfig/res/xml/ > /dev/null 2>&1
    # Extract overlay configs
    ovlist=`find "$PROJECT_DIR"/helpers/lists/overlays/ -maxdepth 1 -type f -printf '%P\n' | sort`
    for list in $ovlist; do
        overlay_configs=`cat "$PROJECT_DIR"/helpers/lists/overlays/"$list" | sort`
        for overlay_line in $overlay_configs; do
            if grep -q "\""$overlay_line"\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/"$list".xml; then
                if [ -e "$PROJECT_DIR"/helpers/lists/overlays/comments/"$overlay_line" ]; then
                    printf "\n" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
                    cat "$PROJECT_DIR"/helpers/lists/overlays/comments/"$overlay_line" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
                fi
                echo "    " $(cat "$PROJECT_DIR"/working/overlays/framework-res/res/values/"$list".xml | grep "\""$overlay_line"\">") >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
            fi
        done
    done
    # integer arrays
    overlay_configs=`cat $PROJECT_DIR/helpers/lists/overlays/arrays/integer-array | sort`
    for target in $overlay_configs; do
        TSTART=$(grep -n "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g")
        if [ ! -z "$TSTART" ]; then
            configs=`grep -n "</integer-array>" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g"`
            for config_file in $configs; do
                TEND="$config_file"
                if [ ! -z "$TEND" ] && [ "$TEND" -gt "$TSTART" ]; then
                    break
                fi
            done
            if grep -q "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml; then
                if [ -e "$PROJECT_DIR"/helpers/lists/overlays/comments/"$target" ]; then
                    printf "\n" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
                    cat "$PROJECT_DIR"/helpers/lists/overlays/comments/"$target" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
                fi
                sed -n "${TSTART},${TEND}p" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
            fi
        fi
    done
    # string arrays
    overlay_configs=`cat $PROJECT_DIR/helpers/lists/overlays/arrays/string-array | sort`
    for target in $overlay_configs; do
        TSTART=$(grep -n "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g")
        if [ ! -z "$TSTART" ]; then
            configs=`grep -n "</string-array>" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml | sed "s|:.*||g"`
            for config_file in $configs; do
                TEND="$config_file"
                if [ ! -z "$TEND" ] && [ "$TEND" -gt "$TSTART" ]; then
                    break
                fi
            done
            if grep -q "\"$target\">" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml; then
                if [ -e "$PROJECT_DIR"/helpers/lists/overlays/comments/"$target" ]; then
                    printf "\n" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
                    cat "$PROJECT_DIR"/helpers/lists/overlays/comments/"$target" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
                fi
                sed -n "${TSTART},${TEND}p" "$PROJECT_DIR"/working/overlays/framework-res/res/values/arrays.xml >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
            fi
        fi
    done
    # Make xml proper
    mv "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml "$DT_DIR"/overlay/frameworks/base/core/res/res/values/staging.xml
    cat "$PROJECT_DIR"/helpers/lists/overlays/comments/HEADER "$DT_DIR"/overlay/frameworks/base/core/res/res/values/staging.xml > "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
    printf "\n</resources>" >> "$DT_DIR"/overlay/frameworks/base/core/res/res/values/config.xml
    rm -rf "$DT_DIR"/overlay/frameworks/base/core/res/res/values/staging.xml
    # config_vendorPlatformSignatures
    cat "$PROJECT_DIR"/dummy_dt/working/all_files.txt | grep -iE "system/etc/selinux/plat_mac_permissions.xml" > "$PROJECT_DIR"/dummy_dt/working/configs.txt
    get_configs
    if [[ -e ""$PROJECT_DIR"/working/overlays/plat_mac_permissions.xml" ]]; then
        vensig="$(cat "$PROJECT_DIR"/working/overlays/plat_mac_permissions.xml | grep "<policy><signer signature=\"" | sed "s|.*<policy><signer signature=\"||g" | sed "s|\"><seinfo value=\"platform.*||g")"
        printf "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<resources>" > "$DT_DIR"/overlay-lineage/lineage-sdk/lineage/res/res/values/config.xml
        printf "\n    <!-- The list of vendor package signatures that should also be considered" >> "$DT_DIR"/overlay-lineage/lineage-sdk/lineage/res/res/values/config.xml
        printf "\n    platform signatures, specifically for use on devices with a vendor partition. -->" >> "$DT_DIR"/overlay-lineage/lineage-sdk/lineage/res/res/values/config.xml
        printf "\n    <string-array name=\"config_vendorPlatformSignatures\">" >> "$DT_DIR"/overlay-lineage/lineage-sdk/lineage/res/res/values/config.xml
        printf "\n        <item>$vensig</item>\n    </string-array>\n</resources>" >> "$DT_DIR"/overlay-lineage/lineage-sdk/lineage/res/res/values/config.xml
    fi
}

[[ -z "$1" ]] && echo "Give arguement!" && exit 1

# Create working directory if it does not exist
mkdir -p "$PROJECT_DIR"/dummy_dt/working

for var in "$@"; do
    ROM_PATH=$( realpath "$var" )
    if [ -e "$ROM_PATH"/system/system/build.prop ]; then
        SYSTEM_PATH="system/system"
    elif [ -e "$ROM_PATH"/system/build.prop ]; then
        SYSTEM_PATH="system"
    fi
    [[ -d "$ROM_PATH/system/vendor/" ]] && VENDOR_PATH="system/vendor"
    [[ -d "$ROM_PATH/system/system/vendor/" ]] && VENDOR_PATH="system/system/vendor"
    [[ -d "$ROM_PATH/vendor/" ]] && VENDOR_PATH="vendor"
    rm -rf $PROJECT_DIR/dummy_dt/working/*
    find "$ROM_PATH" -type f -printf '%P\n' | sort > $PROJECT_DIR/dummy_dt/working/all_files.txt
    find "$ROM_PATH/$SYSTEM_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/dummy_dt/working/system_build.prop \;
    find "$ROM_PATH/$VENDOR_PATH" -maxdepth 1 -name "build*prop" -exec cat {} >> $PROJECT_DIR/dummy_dt/working/vendor_build.prop \;
    common_core
    cd "$PROJECT_DIR"
done

[[ "$VERBOSE" != "n" ]] && echo -e "Finished!"
