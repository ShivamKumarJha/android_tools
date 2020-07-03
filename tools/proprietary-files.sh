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

# ADSP
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/|vendor/lib64/|bin/adsprpcd" | grep -iE "libadsp|ibfastcv|adsprpc|mdsprpc|sdsprpc" | grep -v "scve" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/ADSP

# ADSP modules
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/rfsa/adsp/|vendor/dsp/" | grep -v "scve" | sort -u >> $PROJECT_DIR/working/proprietary/ADSP-Modules

# Alarm
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "framework/vendor.qti.hardware.|vendor/" | grep -iE "alarm" | sort -u >> $PROJECT_DIR/working/proprietary/Alarm

# ANT
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "libantradio|qti.ant@" | sort -u >> $PROJECT_DIR/working/proprietary/ANT

# Audio
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "etc/permissions/audiosphere.xml|framework/audiosphere.jar" | sort -u >> $PROJECT_DIR/working/proprietary/Audio
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libtinycompress|tfa98xx|libsrsprocessing|libaudio|libacdb|libdirac|etc/dirac|etc/sony_effect/|etc/drc/|etc/surround_sound_3mic/" | grep -v "lib/rfsa/adsp" | grep -v "lib/modules/" | sort -u >> $PROJECT_DIR/working/proprietary/Audio

# Audio-ACDB
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/acdb|vendor/etc/audconf" | sort -u >> $PROJECT_DIR/working/proprietary/Audio-ACDB

# Audio-Hardware
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/|vendor/lib64/" | grep -iE "libaudio_log_utils.so|libtinycompress_vendor.so|libqcompostprocbundle.so|libqcomvisualizer.so|libqcomvoiceprocessing.so|libvolumelistener.so" | sort -u >> $PROJECT_DIR/working/proprietary/Audio-Hardware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "hw/audio" | grep -v "bluetooth" | sort -u >> $PROJECT_DIR/working/proprietary/Audio-Hardware

# Bluetooth
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libbthost_if|btnvtool|hci_qcomm_init|wcnss_filter|bluetooth|libbt|btconfigstore" | grep -v "vendor/etc/permissions" | grep -v "libbthost_if" | grep -v "overlay/" | grep -v "bluetooth_qti_audio_policy_configuration.xml" | sort -u >> $PROJECT_DIR/working/proprietary/Bluetooth

# Bluetooth-AptX
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "aptx" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/Bluetooth-AptX

# Camera blobs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libactuator|vendor/lib64/libactuator" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-actuators
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libarcsoft|vendor/lib64/libarcsoft" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-arcsoft
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/bin/" | grep -iE "camera" | grep -v "hardware.camera.provider@" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-bin
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libchromatix|vendor/lib64/libchromatix" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-chromatix
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/camera|vendor/etc/qvr/|vendor/camera3rd/|vendor/camera_sound|vendor/etc/FLASH_ON/|vendor/etc/IMX|vendor/camera/" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-configs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/" | grep "ISO" | grep ".*\.ncf" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-configs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/firmware/cpp_firmware|vendor/firmware/CAMERA" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-firmware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libcam|libDepthBokeh|libSonyDual|libtriplecam|libremosaic|lib/camera/|lib64/camera/|mibokeh|lib_camera|libgcam|libdualcam|libmakeup|libtriplecam|SuperSensor|SonyIMX|libmialgo|libsnpe" | grep -v "vendor/lib/rfsa/adsp/" | sort -u >> $PROJECT_DIR/working/proprietary/Camera
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "hw/camera|libMegvii|libVD|libcapi|libextawb|libnti_|vendor.qti.hardware.camera.device" | grep -v "vendor/lib/rfsa/adsp/" | sort -u >> $PROJECT_DIR/working/proprietary/Camera
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "motor" | grep -v "odex" | grep -v "vdex" | grep -v "motorola" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-motor
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libois|vendor/lib64/libois" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-ois
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libmmcamera|vendor/lib64/libmmcamera" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-sensors

# CDSP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "cdsprpc|libcdsp|libsdsprpc|libfastrpc|libsdsprpc|libsysmon" | sort -u >> $PROJECT_DIR/working/proprietary/CDSP

# Charger
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/bin/hvdcp_opti|vendor/charge/chargemon/" | sort -u >> $PROJECT_DIR/working/proprietary/Charger

# Consumerir
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "consumerir" | grep -v "android.hardware.consumerir.xml" | sort -u >> $PROJECT_DIR/working/proprietary/Consumerir

# CNE
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "etc/permissions/cneapiclient.xml|etc/permissions/com.quicinc.cne.xml|priv-app/CNEService/CNEService.apk|etc/cne/|vendor.qti.hardware.data|vendor.qti.data" | grep -v "latency" | sort -u >> $PROJECT_DIR/working/proprietary/CNE
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "framework/|lib/|lib64/" | grep -iE "cneapiclient|com.quicinc.cne|vendor.qti.hardware.data" | grep -iE ".*\.jar|.*\.so" | grep -v "latency" | sort -u >> $PROJECT_DIR/working/proprietary/CNE
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "cne.server|vendor/etc/cne/|quicinc.cne.|cneapiclient|vendor.qti.hardware.data|libcne|vendor.qti.data|CneApp|IWlanService|init/cnd.rc|bin/cnd|libwms.so|libwqe.so|libxml.so" | grep -v "latency" | sort -u >> $PROJECT_DIR/working/proprietary/CNE

# CVP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libcvp|cvp@" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/CVP

# Display
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/dsi_|video_dsi_panel" | grep "xml" | sort -u >> $PROJECT_DIR/working/proprietary/Display

# Display-calibration
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/qdcm_calib" | sort -u >> $PROJECT_DIR/working/proprietary/Display-calibration

# Display-Hardware
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "lib/|lib64/" | grep -iE "libsdm-disp-apis.so" | sort -u >> $PROJECT_DIR/working/proprietary/Display-Hardware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.qti.hardware.display.allocator|hardware.graphics.mapper|vendor.display.config@|hw/gralloc|hw/hwcomposer|hw/memtrack" | sort -u >> $PROJECT_DIR/working/proprietary/Display-Hardware

# Dolby
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "dolby" | sort -u >> $PROJECT_DIR/working/proprietary/Dolby

# DPM
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "dpm.api@|libdpm|bin/dpmd|etc/dpm/dpm.conf|etc/init/dpmd.rc|com.qti.dpmframework|dpmapi|framework/tcmclient.jar|priv-app/dpmserviceapp/dpmserviceapp.apk|vendor/bin/dpmQmiMgr" | sort -u >> $PROJECT_DIR/working/proprietary/DPM

# DRM-HDCP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libhdcp|hdcpmgr|bin/hdcp" | sort -u >> $PROJECT_DIR/working/proprietary/DRM-HDCP

# DRM-Qteeconnector
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "qteeconnector" | sort -u >> $PROJECT_DIR/working/proprietary/DRM-Qteeconnector

# DRM-Widevine
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep "hardware.drm" | grep "widevine" | sort -u >> $PROJECT_DIR/working/proprietary/DRM-Widevine
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "firmware/cppf|firmware/widevine|mediadrm/|qcdrm/|lib/libwvhidl.so|lib64/libwvhidl.so" | sort -u >> $PROJECT_DIR/working/proprietary/DRM-Widevine

# DTS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/dts/|libdts|libomx-dts" | sort -u >> $PROJECT_DIR/working/proprietary/DTS

# ESE-Powermanager
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "lib/|lib64/|vendor/" | grep -iE "esepowermanager" | sort -u >> $PROJECT_DIR/working/proprietary/ESE-Powermanager

# Factory
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor.qti.hardware.factory" | sort -u >> $PROJECT_DIR/working/proprietary/Factory

# Fido
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "fido" | sort -u >> $PROJECT_DIR/working/proprietary/Fido

# Fingerprint
cat $PROJECT_DIR/working/rom_all.txt | grep "etc/firmware/goodixfp|etc/firmware/fpctzappfingerprint" | sort -u >> $PROJECT_DIR/working/proprietary/Fingerprint
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "fpctzappfingerprint|silead|biometrics|etc/qti_fp/|libgf_|fingerprint|goodix|cdfinger|qfp-daemon|init_qfp_daemon|libqfp|fp_hal|libsl_fp|libarm_proxy_skel|libhvx_proxy_stub" | grep -v "android.hardware.fingerprint.xml" | grep -v "/usr/" | sort -u >> $PROJECT_DIR/working/proprietary/Fingerprint

# Firmware
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/firmware/|etc/firmware/" | grep -v "cpp_firmware" | grep -v "libpn5" | grep -v "ipa_fws" | sort -u >> $PROJECT_DIR/working/proprietary/Firmware

# FM
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "ftm_fm_lib|vendor.qti.hardware.fm|fm_helium.so|libfm-hci.so|fm_qsoc_patches" | sort -u >> $PROJECT_DIR/working/proprietary/FM

# Gatekeeper
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "gatekeeper" | sort -u >> $PROJECT_DIR/working/proprietary/Gatekeeper

# Google
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "google" | grep -v "etc/media_codecs_google" | sort -u >> $PROJECT_DIR/working/proprietary/Google

# GPS
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "etc/permissions/com.qti.location.sdk.xml|etc/permissions/com.qualcomm.location.xml|etc/permissions/izat.xt.srv.xml|etc/permissions/privapp-permissions-com.qualcomm.location.xml|framework/com.qti.location.sdk.jar|framework/izat.xt.srv.jar|lib64/liblocationservice_jni.so|lib64/libxt_native.so|lib/vendor.qti.gnss@|lib64/vendor.qti.gnss@" | sort -u >> $PROJECT_DIR/working/proprietary/GPS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libizat_|liblowi_|libloc_|liblocation|qti.gnss|gnss@|hw/gps.mt" | sort -u >> $PROJECT_DIR/working/proprietary/GPS

# Graphics
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libc2d30|hw/vulkan|lib/egl/|lib64/egl/" | sort -u >> $PROJECT_DIR/working/proprietary/Graphics

# HotwordEnrollment
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "app/" | grep -iE "HotwordEnrollment" | grep ".apk" | sort -u >> $PROJECT_DIR/working/proprietary/HotwordEnrollment

# IFAA
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "IFAA" | sort -u >> $PROJECT_DIR/working/proprietary/IFAA

# IPA-Firmware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/firmware/ipa_fws" | sort -u >> $PROJECT_DIR/working/proprietary/IPA-Firmware

# Keymaster
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "keymaster" | sort -u >> $PROJECT_DIR/working/proprietary/Keymaster

# Keystore
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "keystore|libspcom" | sort -u >> $PROJECT_DIR/working/proprietary/Keystore

# Latency
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "data.latency|qti.latency" | grep -v "odex" | grep -v "vdex" | sort -u >> $PROJECT_DIR/working/proprietary/Latency

# Listen
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "liblisten|hw/sound_trigger.primary" | sort -u >> $PROJECT_DIR/working/proprietary/Listen

# Machine-Learning
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "mlshal" | sort -u >> $PROJECT_DIR/working/proprietary/Machine-Learning

# Media
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "lib/|lib64/" | grep -iE "extractors/libmmparser.so|libFileMux.so|libOmxMux.so|libmmosal.so|ibmmparser_lite.so|libmmrtpdecoder.so|libmmrtpencoder.so|vendor.qti.hardware.vpp@" | sort -u >> $PROJECT_DIR/working/proprietary/Media
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.qti.hardware.vpp|libvpp" | sort -u >> $PROJECT_DIR/working/proprietary/Media

# Mediatek
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "mediatek|libmtk" | sort -u >> $PROJECT_DIR/working/proprietary/Mediatek

# Meizu
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "meizu" | sort -u >> $PROJECT_DIR/working/proprietary/Meizu

# Motorola
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libmot|lib_mot|motcamera|motobox|motorola" | sort -u >> $PROJECT_DIR/working/proprietary/Motorola

# NFC
cat $PROJECT_DIR/working/rom_all.txt | grep -v "vendor/" | grep -iE "app/NxpNfcNci/NxpNfcNci.apk|app/NxpSecureElement/NxpSecureElement.apk|etc/nfcee_access.xml|etc/permissions/com.nxp.nfc.xml|framework/com.nxp.nfc.jar|libnxpnfc" | sort -u >> $PROJECT_DIR/working/proprietary/NFC
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libpn5|nfc|secure_element|etc/libese|nxp|libp61|ls_client" | grep -v "etc/permissions/android.hardware.nfc" | sort -u >> $PROJECT_DIR/working/proprietary/NFC

# Neural-networks
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "neuralnetworks|libhexagon" | sort -u >> $PROJECT_DIR/working/proprietary/Neural-networks

# OnePlus
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "oneplus" | sort -u >> $PROJECT_DIR/working/proprietary/OnePlus

# Oppo
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "oppo" | sort -u >> $PROJECT_DIR/working/proprietary/Oppo

# Pasrmanager
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "pasrmanager" | sort -u >> $PROJECT_DIR/working/proprietary/Pasrmanager

# Perf
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "perf@|etc/perf/|libqti-perf|libqti-util|libqti_perf" | sort -u >> $PROJECT_DIR/working/proprietary/Perf

# Perf-IOP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "iop@|iopd" | sort -u >> $PROJECT_DIR/working/proprietary/Perf-IOP

# Peripheral
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "bin/pm-proxy|bin/pm-service|libperipheral" | sort -u >> $PROJECT_DIR/working/proprietary/Peripheral

# Postprocessing
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "lib/|lib64/|vendor/" | grep -iE "vendor.display.color|vendor.display.postproc" | sort -u >> $PROJECT_DIR/working/proprietary/Postprocessing

# Power-Hardware
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/" | grep -iE "hardware.power@|hw/power" | sort -u >> $PROJECT_DIR/working/proprietary/Power-Hardware

# Qdutils_disp
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "qdutils_disp" | sort -u >> $PROJECT_DIR/working/proprietary/Qdutils

# QMI
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "etc/permissions/qti_" | sort -u >> $PROJECT_DIR/working/proprietary/QMI
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libqmi" | sort -u >> $PROJECT_DIR/working/proprietary/QMI

# Radio
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "app/QtiTelephonyService/QtiTelephonyService.apk|app/datastatusnotification/datastatusnotification.apk|app/embms/embms.apk|etc/permissions/embms.xml|etc/permissions/privapp-permissions-qti.xml|etc/permissions/qcrilhook.xml|etc/permissions/telephonyservice.xml|etc/sysconfig/qti_whitelist.xml|priv-app/qcrilmsgtunnel/qcrilmsgtunnel.apk" | sort -u >> $PROJECT_DIR/working/proprietary/Radio
cat $PROJECT_DIR/working/rom_all.txt | grep "framework/" | grep -iE "QtiTelephonyServicelibrary|embmslibrary|qcnvitems|qcrilhook|qti-telephony-common" | grep ".jar" | sort -u >> $PROJECT_DIR/working/proprietary/Radio
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "radio/|vendor.qti.hardware.radio" | grep -v "vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio

# Radio-IMS
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "app/imssettings/imssettings.apk|etc/permissions/com.qualcomm.qti.imscmservice|app/uceShimService/uceShimService.apk" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "framework/com.qualcomm.qti.imscmservice|framework/com.qualcomm.qti.uceservice|framework/vendor.qti.ims|framework/qti-vzw-ims-internal" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "lib/|lib64" | grep -iE "libdiag_system.so|librcc.so|com.qualcomm.qti.imscmservice@|com.qualcomm.qti.uceservice@|lib-ims|libimscamera_jni|libimsmedia_jni|vendor.qti.ims|lib-dplmedia.so|lib-rtp|lib-siputility" | grep -v "priv-app/" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "priv-app/ims/ims.apk|priv-app/imssettings/imssettings.apk|vendor/bin/ims_rtp_daemon|vendor/bin/imsdatadaemon|vendor/bin/imsqmidaemon|vendor/bin/imsrcsd|vendor/bin/ims_rtp_daemon" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "imsrtpservice|imscmservice|uceservice|vendor.qti.ims.|lib-ims|radio.ims@|vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS

# Samsung
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "samsung|SoundAlive" | grep -v "vendor/etc/qdcm_calib" | grep -v "vendor/etc/dsi" | grep -v "vendor/firmware/" | sort -u >> $PROJECT_DIR/working/proprietary/Samsung

# SCVE
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "lib/|lib64/|vendor/" | grep -iE "scve" | sort -u >> $PROJECT_DIR/working/proprietary/SCVE

# Seccam
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "seccam" | sort -u >> $PROJECT_DIR/working/proprietary/Seccam

# Sensors
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libsensor|lib64/sensors|lib/sensors|libAsusRGBSensorHAL|lib/hw/sensors|lib64/hw/sensors|libssc|hw/activity_recognition|hw/sensors|lib/sensors|lib64/sensors" | sort -u >> $PROJECT_DIR/working/proprietary/Sensors

# Sensor-calibrate
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "sensorscalibrate" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-calibrate

# Sensor-configs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/sensors/" | grep -v "vendor/etc/sensors/hals.conf" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-configs

# Sony
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.semc|vendor.somc|init.sony" | sort -u >> $PROJECT_DIR/working/proprietary/Sony

# Soter
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "app/SoterService/SoterService.apk|framework/vendor.qti.hardware.soter|lib64/vendor.qti.hardware.soter" | sort -u >> $PROJECT_DIR/working/proprietary/Soter
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "soter" | sort -u >> $PROJECT_DIR/working/proprietary/Soter

# SSR
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "bin/ssr_|subsystem" | sort -u >> $PROJECT_DIR/working/proprietary/SSR

# Thermal
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/thermal|bin/thermal|libthermal|bin/mi_thermald|thermal" | grep -v "hw/thermal" | sort -u >> $PROJECT_DIR/working/proprietary/Thermal

# Thermal-Hardware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "lib/hw/thermal|lib64/hw/thermal" | sort -u >> $PROJECT_DIR/working/proprietary/Thermal-Hardware

# Touch-improve
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "improvetouch" | sort -u >> $PROJECT_DIR/working/proprietary/Touch-improve

# Touchscreen
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/hbtp/|libhbtp" | sort -u >> $PROJECT_DIR/working/proprietary/Touchscreen

# TUI
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "tui_comm" | sort -u >> $PROJECT_DIR/working/proprietary/TUI

# UBWC
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libUBWC.so|libstreamparser.so" | sort -u >> $PROJECT_DIR/working/proprietary/UBWC

# Vibrator
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vibrator" | sort -u >> $PROJECT_DIR/working/proprietary/Vibrator

# Vivo
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vivo" | sort -u >> $PROJECT_DIR/working/proprietary/Vivo

# Voice
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "voiceprint@|vendor/etc/qvop/|libqvop" | sort -u >> $PROJECT_DIR/working/proprietary/Voice

# VR
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "lib/hw/vr|lib64/hw/vr" | sort -u >> $PROJECT_DIR/working/proprietary/VR

# WFD
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "bin/wfdservice|etc/init/wfdservice.rc|etc/wfdconfig|framework/WfdCommon.jar|priv-app/WfdService/WfdService.apk" | sort -u >> $PROJECT_DIR/working/proprietary/WFD
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "lib/|lib64/" | grep -iE "wifidisplayhal|libwfd" | grep -v "libwfds.so" | sort -u >> $PROJECT_DIR/working/proprietary/WFD
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "wifidisplayhal|wfdservice|libwfd|wfdconfig" | sort -u >> $PROJECT_DIR/working/proprietary/WFD

# Xiaomi
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor.xiaomi.hardware." | grep -v "odex" | grep -v "vdex" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "xiaomi|mlipay|mtd|tidad|libtida|libmivendor" | grep -v "camera" | grep -v "vendor/etc/nuance/" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi

# Delete empty lists
find $PROJECT_DIR/working/proprietary -size  0 -print0 | xargs -0 rm --

# Add blobs from lists
blobs_list=`find $PROJECT_DIR/working/proprietary -type f -printf '%P\n' | sort`
for list in $blobs_list ; do
    file_lines=`cat $PROJECT_DIR/working/proprietary/$list | sort -uf`
    printf "\n# $list\n" >> $PROJECT_DIR/working/proprietary-files-staging.txt
    for line in $file_lines ; do
        if cat $PROJECT_DIR/working/rom_all.txt | grep "$line"; then
            if echo "$line" | grep -iE "libplatformconfig|apk|jar"; then
                echo "-$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            else
                echo "$line" >> $PROJECT_DIR/working/proprietary-files-staging.txt
            fi
        fi
    done
done

# List all /system_ext blobs
cat $PROJECT_DIR/working/rom_all.txt | grep "system_ext/" | sort -u > $PROJECT_DIR/working/staging.txt
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
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | sort -u > $PROJECT_DIR/working/staging.txt
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
