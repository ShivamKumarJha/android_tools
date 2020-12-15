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

if [ -z "$1" ]; then
    echo -e "Supply ROM file list as arguement!"
    exit 1
fi

# copy $1
if echo "$1" | grep "https" ; then
    wget -O $PROJECT_DIR/working/rom_all.txt $1
elif [ -d "$1" ]; then
    find "$1" -type f -printf '%P\n' | sort > $PROJECT_DIR/working/rom_all.txt
elif [ -e "$1" ]; then
    cp -a $1 $PROJECT_DIR/working/rom_all.txt
else
    exit 1
fi

# Cleanup
if grep -q "system/system/" $PROJECT_DIR/working/rom_all.txt; then
    sed -i "s|^system/system/||1" $PROJECT_DIR/working/rom_all.txt
elif grep -q "system/" $PROJECT_DIR/working/rom_all.txt; then
    sed -i "s|^system/||1" $PROJECT_DIR/working/rom_all.txt
fi
sed -i "s|vendor/bin/.*\.sh||g" $PROJECT_DIR/working/rom_all.txt
sed -i "s|.*/oat/.*||g" $PROJECT_DIR/working/rom_all.txt
sed -i '/^$/d' $PROJECT_DIR/working/rom_all.txt

# Copy lists to $PROJECT_DIR/working
cp -a $PROJECT_DIR/helpers/lists/proprietary/ $PROJECT_DIR/working/

# Functions
search_blobs() {
    cat $PROJECT_DIR/working/rom_all.txt
}

add_to_section() {
    sort -u >> "$PROJECT_DIR/working/proprietary/${1}"
}

# ADSP
search_blobs | grep -iE "vendor/lib/|vendor/lib64/|bin/adsprpcd" | grep -iE "libadsp|ibfastcv|adsprpc|mdsprpc|sdsprpc" | grep -v "scve" | grep -v "lib/rfsa/adsp" | add_to_section ADSP

# ADSP modules
search_blobs | grep -iE "vendor/lib/rfsa/adsp/|vendor/dsp/" | grep -v "scve" | add_to_section ADSP-Modules

# Alarm
search_blobs | grep -iE "framework/vendor.qti.hardware.|vendor/" | grep -iE "alarm" | add_to_section Alarm

# ANT
search_blobs | grep -iE "libantradio|qti.ant@" | add_to_section ANT

# Audio
search_blobs | grep -iE "etc/permissions/audiosphere.xml|framework/audiosphere.jar" | add_to_section Audio
search_blobs | grep "vendor/" | grep -iE "libtinycompress|tfa98xx|libsrsprocessing|libaudio|libacdb|libdirac|etc/dirac|etc/sony_effect/|etc/drc/|etc/surround_sound_3mic/" | grep -v "lib/rfsa/adsp" | grep -v "lib/modules/" | add_to_section Audio

# Audio-ACDB
search_blobs | grep -iE "vendor/etc/acdb|vendor/etc/audconf" | add_to_section Audio-ACDB

# Audio-Hardware
search_blobs | grep -iE "vendor/lib/|vendor/lib64/" | grep -iE "libaudio_log_utils.so|libtinycompress_vendor.so|libqcompostprocbundle.so|libqcomvisualizer.so|libqcomvoiceprocessing.so|libvolumelistener.so" | add_to_section Audio-Hardware
search_blobs | grep "vendor/" | grep -iE "hardware.audio|hw/audio" | grep -v "bluetooth" | grep -v "etc/permissions" | add_to_section Audio-Hardware

# Bluetooth
search_blobs | grep "vendor/" | grep -iE "libbthost_if|btnvtool|hci_qcomm_init|wcnss_filter|bluetooth|libbt|btconfigstore" | grep -v "vendor/etc/permissions" | grep -v "libbthost_if" | grep -v "overlay/" | grep -v "bluetooth_qti_audio_policy_configuration.xml" | add_to_section Bluetooth

# Bluetooth-AptX
search_blobs | grep -iE "aptx" | grep -v "lib/rfsa/adsp" | add_to_section Bluetooth-AptX

# Camera blobs
search_blobs | grep -iE "vendor/lib/libactuator|vendor/lib64/libactuator" | add_to_section Camera-actuators
search_blobs | grep -iE "vendor/lib/libarcsoft|vendor/lib64/libarcsoft" | add_to_section Camera-arcsoft
search_blobs | grep "vendor/bin/" | grep -iE "camera" | grep -v "hardware.camera.provider@" | add_to_section Camera-bin
search_blobs | grep -iE "vendor/lib/libchromatix|vendor/lib64/libchromatix" | add_to_section Camera-chromatix
search_blobs | grep -iE "vendor/etc/camera|vendor/etc/qvr/|vendor/camera3rd/|vendor/camera_sound|vendor/etc/FLASH_ON/|vendor/etc/IMX|vendor/camera/" | add_to_section Camera-configs
search_blobs | grep -iE "vendor/etc/" | grep "ISO" | grep ".*\.ncf" | add_to_section Camera-configs
search_blobs | grep -iE "vendor/firmware/cpp_firmware|vendor/firmware/CAMERA" | add_to_section Camera-firmware
search_blobs | grep "vendor/" | grep -iE "libcam|libDepthBokeh|libSonyDual|libtriplecam|libremosaic|lib/camera/|lib64/camera/|mibokeh|lib_camera|libgcam|libdualcam|libmakeup|libtriplecam|SuperSensor|SonyIMX|libmialgo|libsnpe" | grep -v "vendor/lib/rfsa/adsp/" | add_to_section Camera
search_blobs | grep "vendor/" | grep -iE "hw/camera|libMegvii|libVD|libcapi|libextawb|libnti_|vendor.qti.hardware.camera.device" | grep -v "vendor/lib/rfsa/adsp/" | add_to_section Camera
search_blobs | grep "vendor/" | grep -iE "motor" | grep -v "odex" | grep -v "vdex" | grep -v "motorola" | add_to_section Camera-motor
search_blobs | grep -iE "vendor/lib/libois|vendor/lib64/libois" | add_to_section Camera-ois
search_blobs | grep -iE "vendor/lib/libmmcamera|vendor/lib64/libmmcamera" | add_to_section Camera-sensors

# CDSP
search_blobs | grep "vendor/" | grep -iE "cdsprpc|libcdsp|libsdsprpc|libfastrpc|libsdsprpc|libsysmon" | add_to_section CDSP

# Charger
search_blobs | grep -iE "vendor/bin/hvdcp_opti|vendor/charge/chargemon/" | add_to_section Charger

# Consumerir
search_blobs | grep "vendor/" | grep -iE "consumerir" | grep -v "android.hardware.consumerir.xml" | add_to_section Consumerir

# CNE
search_blobs | grep -iE "etc/permissions/cneapiclient.xml|etc/permissions/com.quicinc.cne.xml|priv-app/CNEService/CNEService.apk|etc/cne/|vendor.qti.hardware.data|vendor.qti.data" | grep -v "latency" | add_to_section CNE
search_blobs | grep -iE "framework/|lib/|lib64/" | grep -iE "cneapiclient|com.quicinc.cne|vendor.qti.hardware.data" | grep -iE ".*\.jar|.*\.so" | grep -v "latency" | add_to_section CNE
search_blobs | grep "vendor/" | grep -iE "cne.server|vendor/etc/cne/|quicinc.cne.|cneapiclient|vendor.qti.hardware.data|libcne|vendor.qti.data|CneApp|IWlanService|init/cnd.rc|bin/cnd|libwms.so|libwqe.so|libxml.so" | grep -v "latency" | add_to_section CNE

# CVP
search_blobs | grep "vendor/" | grep -iE "libcvp|cvp@" | grep -v "lib/rfsa/adsp" | add_to_section CVP

# Display
search_blobs | grep "vendor/" | grep -iE "etc/dsi_|video_dsi_panel" | grep "xml" | add_to_section Display

# Display-calibration
search_blobs | grep -iE "vendor/etc/qdcm_calib" | add_to_section Display-calibration

# Display-Hardware
search_blobs | grep -iE "lib/|lib64/" | grep -iE "libsdm-disp-apis.so" | add_to_section Display-Hardware
search_blobs | grep "vendor/" | grep -iE "vendor.qti.hardware.display.allocator|hardware.graphics.mapper|vendor.display.config@|hw/gralloc|hw/hwcomposer|hw/memtrack" | add_to_section Display-Hardware

# Dolby
search_blobs | grep "vendor/" | grep -iE "dolby" | add_to_section Dolby

# DPM
search_blobs | grep -iE "dpm.api@|libdpm|bin/dpmd|etc/dpm/dpm.conf|etc/init/dpmd.rc|com.qti.dpmframework|dpmapi|framework/tcmclient.jar|priv-app/dpmserviceapp/dpmserviceapp.apk|vendor/bin/dpmQmiMgr" | add_to_section DPM

# DRM-HDCP
search_blobs | grep "vendor/" | grep -iE "libhdcp|hdcpmgr|bin/hdcp" | add_to_section DRM-HDCP

# DRM-Qteeconnector
search_blobs | grep "vendor/" | grep -iE "qteeconnector" | add_to_section DRM-Qteeconnector

# DRM-Widevine
search_blobs | grep "vendor/" | grep "hardware.drm" | grep "widevine" | add_to_section DRM-Widevine
search_blobs | grep -iE "firmware/cppf|firmware/widevine|mediadrm/|qcdrm/|lib/libwvhidl.so|lib64/libwvhidl.so" | add_to_section DRM-Widevine

# DTS
search_blobs | grep "vendor/" | grep -iE "etc/dts/|libdts|libomx-dts" | add_to_section DTS

# ESE-Powermanager
search_blobs | grep -iE "lib/|lib64/|vendor/" | grep -iE "esepowermanager" | add_to_section ESE-Powermanager

# Factory
search_blobs | grep -iE "vendor.qti.hardware.factory" | add_to_section Factory

# Fido
search_blobs | grep "vendor/" | grep -iE "fido" | add_to_section Fido

# Fingerprint
search_blobs | grep "etc/firmware/goodixfp|etc/firmware/fpctzappfingerprint" | add_to_section Fingerprint
search_blobs | grep "vendor/" | grep -iE "fpctzappfingerprint|silead|biometrics|etc/qti_fp/|libgf_|fingerprint|goodix|cdfinger|qfp-daemon|init_qfp_daemon|libqfp|fp_hal|libsl_fp|libarm_proxy_skel|libhvx_proxy_stub" | grep -v "android.hardware.fingerprint.xml" | grep -v "/usr/" | add_to_section Fingerprint

# Firmware
search_blobs | grep -iE "vendor/firmware/|etc/firmware/" | grep -v "cpp_firmware" | grep -v "libpn5" | grep -v "ipa_fws" | add_to_section Firmware

# FM
search_blobs | grep -iE "ftm_fm_lib|vendor.qti.hardware.fm|fm_helium.so|libfm-hci.so|fm_qsoc_patches" | add_to_section FM

# Gatekeeper
search_blobs | grep "vendor/" | grep -iE "gatekeeper" | add_to_section Gatekeeper

# Google
search_blobs | grep "vendor/" | grep -iE "google" | grep -v "etc/media_codecs_google" | add_to_section Google

# GPS
search_blobs | grep -iE "etc/permissions/com.qti.location.sdk.xml|etc/permissions/com.qualcomm.location.xml|etc/permissions/izat.xt.srv.xml|etc/permissions/privapp-permissions-com.qualcomm.location.xml|framework/com.qti.location.sdk.jar|framework/izat.xt.srv.jar|lib64/liblocationservice_jni.so|lib64/libxt_native.so|lib/vendor.qti.gnss@|lib64/vendor.qti.gnss@" | add_to_section GPS
search_blobs | grep "vendor/" | grep -iE "libizat_|liblowi_|libloc_|liblocation|qti.gnss|gnss@|hw/gps.mt" | add_to_section GPS

# Graphics
search_blobs | grep "vendor/" | grep -iE "libc2d30|hw/vulkan|lib/egl/|lib64/egl/" | add_to_section Graphics

# HotwordEnrollment
search_blobs | grep -iE "app/" | grep -iE "HotwordEnrollment" | grep ".apk" | add_to_section HotwordEnrollment

# IFAA
search_blobs | grep "vendor/" | grep -iE "IFAA" | add_to_section IFAA

# IPA-Firmware
search_blobs | grep "vendor/firmware/ipa_fws" | add_to_section IPA-Firmware

# Keymaster
search_blobs | grep "vendor/" | grep -iE "keymaster" | add_to_section Keymaster

# Keystore
search_blobs | grep "vendor/" | grep -iE "keystore|libspcom" | add_to_section Keystore

# Latency
search_blobs | grep -iE "data.latency|qti.latency" | grep -v "odex" | grep -v "vdex" | add_to_section Latency

# Lights
search_blobs | grep "vendor/" | grep -iE "hardware.light|hw/lights" | add_to_section Lights

# Listen
search_blobs | grep "vendor/" | grep -iE "liblisten|hw/sound_trigger.primary" | add_to_section Listen

# Machine-Learning
search_blobs | grep "vendor/" | grep -iE "mlshal" | add_to_section Machine-Learning

# Media
search_blobs | grep -iE "lib/|lib64/" | grep -iE "extractors/libmmparser.so|libFileMux.so|libOmxMux.so|libmmosal.so|ibmmparser_lite.so|libmmrtpdecoder.so|libmmrtpencoder.so|vendor.qti.hardware.vpp@" | add_to_section Media
search_blobs | grep "vendor/" | grep -iE "vendor.qti.hardware.vpp|libvpp" | add_to_section Media

# Mediatek
search_blobs | grep "vendor/" | grep -iE "mediatek|libmtk" | add_to_section Mediatek

# Meizu
search_blobs | grep "vendor/" | grep -iE "meizu" | add_to_section Meizu

# Motorola
search_blobs | grep "vendor/" | grep -iE "libmot|lib_mot|motcamera|motobox|motorola" | add_to_section Motorola

# NFC
search_blobs | grep -v "vendor/" | grep -iE "app/NxpNfcNci/NxpNfcNci.apk|app/NxpSecureElement/NxpSecureElement.apk|etc/nfcee_access.xml|etc/permissions/com.nxp.nfc.xml|framework/com.nxp.nfc.jar|libnxpnfc" | add_to_section NFC
search_blobs | grep "vendor/" | grep -iE "libpn5|nfc|secure_element|etc/libese|nxp|libp61|ls_client" | grep -v "etc/permissions/android.hardware.nfc" | add_to_section NFC

# Neural-networks
search_blobs | grep "vendor/" | grep -iE "neuralnetworks|libhexagon" | add_to_section Neural-networks

# OnePlus
search_blobs | grep "vendor/" | grep -iE "oneplus" | add_to_section OnePlus

# Oppo
search_blobs | grep "vendor/" | grep -iE "oppo" | add_to_section Oppo

# Pasrmanager
search_blobs | grep "vendor/" | grep -iE "pasrmanager" | add_to_section Pasrmanager

# Perf
search_blobs | grep -iE "perf@|etc/perf/|libqti-perf|libqti-util|libqti_perf" | add_to_section Perf

# Perf-IOP
search_blobs | grep "vendor/" | grep -iE "iop@|iopd" | add_to_section Perf-IOP

# Peripheral
search_blobs | grep "vendor/" | grep -iE "bin/pm-proxy|bin/pm-service|libperipheral" | add_to_section Peripheral

# Postprocessing
search_blobs | grep -iE "lib/|lib64/|vendor/" | grep -iE "vendor.display.color|vendor.display.postproc" | add_to_section Postprocessing

# Power-Hardware
search_blobs | grep -iE "vendor/" | grep -iE "hardware.power|hw/power" | add_to_section Power-Hardware

# Qdutils_disp
search_blobs | grep "vendor/" | grep -iE "qdutils_disp" | add_to_section Qdutils

# QMI
search_blobs | grep -iE "etc/permissions/qti_" | add_to_section QMI
search_blobs | grep "vendor/" | grep -iE "libqmi" | add_to_section QMI

# Radio
search_blobs | grep -iE "app/QtiTelephonyService/QtiTelephonyService.apk|app/datastatusnotification/datastatusnotification.apk|app/embms/embms.apk|etc/permissions/embms.xml|etc/permissions/privapp-permissions-qti.xml|etc/permissions/qcrilhook.xml|etc/permissions/telephonyservice.xml|etc/sysconfig/qti_whitelist.xml|priv-app/qcrilmsgtunnel/qcrilmsgtunnel.apk" | add_to_section Radio
search_blobs | grep "framework/" | grep -iE "QtiTelephonyServicelibrary|embmslibrary|qcnvitems|qcrilhook|qti-telephony-common" | grep ".jar" | add_to_section Radio
search_blobs | grep "vendor/" | grep -iE "radio/|vendor.qti.hardware.radio" | grep -v "vendor.qti.hardware.radio.ims" | add_to_section Radio

# Radio-IMS
search_blobs | grep -iE "app/imssettings/imssettings.apk|etc/permissions/com.qualcomm.qti.imscmservice|app/uceShimService/uceShimService.apk" | add_to_section Radio-IMS
search_blobs | grep -iE "framework/com.qualcomm.qti.imscmservice|framework/com.qualcomm.qti.uceservice|framework/vendor.qti.ims|framework/qti-vzw-ims-internal" | add_to_section Radio-IMS
search_blobs | grep -iE "lib/|lib64" | grep -iE "libdiag_system.so|librcc.so|com.qualcomm.qti.imscmservice@|com.qualcomm.qti.uceservice@|lib-ims|libimscamera_jni|libimsmedia_jni|vendor.qti.ims|lib-dplmedia.so|lib-rtp|lib-siputility" | grep -v "priv-app/" | add_to_section Radio-IMS
search_blobs | grep -iE "priv-app/ims/ims.apk|priv-app/imssettings/imssettings.apk|vendor/bin/ims_rtp_daemon|vendor/bin/imsdatadaemon|vendor/bin/imsqmidaemon|vendor/bin/imsrcsd|vendor/bin/ims_rtp_daemon" | add_to_section Radio-IMS
search_blobs | grep "vendor/" | grep -iE "imsrtpservice|imscmservice|uceservice|vendor.qti.ims.|lib-ims|radio.ims@|vendor.qti.hardware.radio.ims" | add_to_section Radio-IMS

# Samsung
search_blobs | grep "vendor/" | grep -iE "samsung|SoundAlive" | grep -v "vendor/etc/qdcm_calib" | grep -v "vendor/etc/dsi" | grep -v "vendor/firmware/" | add_to_section Samsung

# SCVE
search_blobs | grep -iE "lib/|lib64/|vendor/" | grep -iE "scve" | add_to_section SCVE

# Seccam
search_blobs | grep "vendor/" | grep -iE "seccam" | add_to_section Seccam

# Sensors
search_blobs | grep "vendor/" | grep -iE "libsensor|lib64/sensors|lib/sensors|libAsusRGBSensorHAL|lib/hw/sensors|lib64/hw/sensors|libssc|hw/activity_recognition|hw/sensors|lib/sensors|lib64/sensors" | add_to_section Sensors

# Sensor-calibrate
search_blobs | grep "vendor/" | grep -iE "sensorscalibrate" | add_to_section Sensor-calibrate

# Sensor-configs
search_blobs | grep -iE "vendor/etc/sensors/" | grep -v "vendor/etc/sensors/hals.conf" | add_to_section Sensor-configs

# Sony
search_blobs | grep "vendor/" | grep -iE "vendor.semc|vendor.somc|init.sony" | add_to_section Sony

# Soter
search_blobs | grep -iE "app/SoterService/SoterService.apk|framework/vendor.qti.hardware.soter|lib64/vendor.qti.hardware.soter" | add_to_section Soter
search_blobs | grep "vendor/" | grep -iE "soter" | add_to_section Soter

# SSR
search_blobs | grep "vendor/" | grep -iE "bin/ssr_|subsystem" | add_to_section SSR

# Thermal
search_blobs | grep "vendor/" | grep -iE "etc/thermal|bin/thermal|libthermal|bin/mi_thermald|thermal" | grep -v "hw/thermal" | add_to_section Thermal

# Thermal-Hardware
search_blobs | grep "vendor/" | grep -iE "lib/hw/thermal|lib64/hw/thermal" | add_to_section Thermal-Hardware

# Touch-improve
search_blobs | grep "vendor/" | grep -iE "improvetouch" | add_to_section Touch-improve

# Touchscreen
search_blobs | grep "vendor/" | grep -iE "etc/hbtp/|libhbtp" | add_to_section Touchscreen

# TUI
search_blobs | grep "vendor/" | grep -iE "tui_comm" | add_to_section TUI

# UBWC
search_blobs | grep "vendor/" | grep -iE "libUBWC.so|libstreamparser.so" | add_to_section UBWC

# Vibrator
search_blobs | grep "vendor/" | grep -iE "vibrator" | add_to_section Vibrator

# Vivo
search_blobs | grep "vendor/" | grep -iE "vivo" | add_to_section Vivo

# Voice
search_blobs | grep "vendor/" | grep -iE "voiceprint@|vendor/etc/qvop/|libqvop" | add_to_section Voice

# VR
search_blobs | grep "vendor/" | grep -iE "lib/hw/vr|lib64/hw/vr" | add_to_section VR

# WFD
search_blobs | grep -iE "bin/wfdservice|etc/init/wfdservice.rc|etc/wfdconfig|framework/WfdCommon.jar|priv-app/WfdService/WfdService.apk" | add_to_section WFD
search_blobs | grep -iE "lib/|lib64/" | grep -iE "wifidisplayhal|libwfd" | grep -v "libwfds.so" | add_to_section WFD
search_blobs | grep "vendor/" | grep -iE "wifidisplayhal|wfdservice|libwfd|wfdconfig|miracast" | add_to_section WFD

# Xiaomi
search_blobs | grep -iE "vendor.xiaomi.hardware." | grep -v "odex" | grep -v "vdex" | add_to_section Xiaomi
search_blobs | grep "vendor/" | grep -iE "xiaomi|mlipay|mtd|tidad|libtida|libmivendor" | grep -v "camera" | grep -v "vendor/etc/nuance/" | add_to_section Xiaomi

# Delete empty lists
find $PROJECT_DIR/working/proprietary -size  0 -print0 | xargs -0 rm --

# Add blobs from lists
blobs_list=`find $PROJECT_DIR/working/proprietary -type f -printf '%P\n' | sort`
for list in $blobs_list ; do
    file_lines=`cat $PROJECT_DIR/working/proprietary/$list | sort -uf`
    printf "\n# $list\n" >> $PROJECT_DIR/working/proprietary-files-staging.txt
    for line in $file_lines ; do
        if search_blobs | grep "$line"; then
            if echo "$line" | grep -iE "libplatformconfig|apk|jar|etc/vintf/manifest/"; then
                echo "-$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            else
                echo "$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            fi
        fi
    done
done

# List all /system_ext blobs
search_blobs | grep "system_ext/" | sort -u > $PROJECT_DIR/working/staging.txt
# Clean up /system_ext
file_lines=`cat $PROJECT_DIR/helpers/lists/remove.txt`
for line in $file_lines; do
    sed -i "s|$line.*||g" $PROJECT_DIR/working/staging.txt
done
sed -i '/^$/d' $PROJECT_DIR/working/staging.txt
# Add missing /system_ext blobs as misc
printf "\n# Misc\n" >> $PROJECT_DIR/working/proprietary-files-staging.txt
file_lines=`cat $PROJECT_DIR/working/staging.txt | sort -f`
for line in $file_lines; do
    # Missing
    if ! grep -q "$line" $PROJECT_DIR/working/proprietary-files-staging.txt; then
        if ! grep -q "$line" $PROJECT_DIR/helpers/lists/ignore.txt; then
            if echo "$line" | grep -iE "apk|jar"; then
                echo "-$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            else
                echo "$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            fi
        fi
    fi
done

# List all /vendor blobs
search_blobs | grep "vendor/" | sort -u > $PROJECT_DIR/working/staging.txt
# Clean up /vendor
file_lines=`cat $PROJECT_DIR/helpers/lists/remove.txt`
for line in $file_lines; do
    sed -i "s|$line.*||g" $PROJECT_DIR/working/staging.txt
done
sed -i "s|vendor/bin/.*\.sh||g" $PROJECT_DIR/working/staging.txt
sed -i '/^$/d' $PROJECT_DIR/working/staging.txt
# Add missing /vendor blobs as misc
file_lines=`cat $PROJECT_DIR/working/staging.txt | sort -f`
for line in $file_lines; do
    # Missing
    if ! grep -q "$line" $PROJECT_DIR/working/proprietary-files-staging.txt; then
        if ! grep -q "$line" $PROJECT_DIR/helpers/lists/ignore.txt; then
            if echo "$line" | grep -iE "apk|jar"; then
                echo "-$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            else
                echo "$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            fi
        fi
    fi
done

# remove duplicates
awk '!NF || !seen[$0]++' $PROJECT_DIR/working/proprietary-files-staging.txt > $PROJECT_DIR/working/proprietary-files.txt

# cleanup temp files
find $PROJECT_DIR/working/* ! -name 'proprietary-files.txt' -type d,f -exec rm -rf {} +

echo -e "$(ls -d $PROJECT_DIR/working/proprietary-files.txt) prepared!"
