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

if [ -z "$1" ]; then
	echo -e "${bold}${red}Supply ROM file list as arguement!${nocol}"
	exit 1
fi

# copy $1
if echo "$1" | grep "https" ; then
	wget -O $PROJECT_DIR/working/rom_all.txt $1
elif [ -d "$1" ]; then
	find "$1" -type f -printf '%P\n' | sort > $PROJECT_DIR/working/rom_all.txt
else
	cp -a $1 $PROJECT_DIR/working/rom_all.txt
fi

# Copy lists to $PROJECT_DIR/working
cp -a $PROJECT_DIR/tools/lists/proprietary/ $PROJECT_DIR/working/

# ADSP modules
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/rfsa/adsp/|vendor/dsp/" | grep -v "scve" | sort -u >> $PROJECT_DIR/working/proprietary/ADSP-Modules

# Alarm
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "alarm" | sort -u >> $PROJECT_DIR/working/proprietary/Alarm

# ANT
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "libantradio|qti.ant@" | sort -u >> $PROJECT_DIR/working/proprietary/ANT

# Audio
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "tfa98xx|libsrsprocessing|libaudio|libacdb|libdirac|etc/dirac|etc/sony_effect/" | grep -v "lib/rfsa/adsp" | grep -v "lib/modules/" | sort -u >> $PROJECT_DIR/working/proprietary/Audio

# Audio-ACDB
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/acdbdata/|vendor/etc/acdbdata_bl/|vendor/etc/acdbdata_id/" | sort -u >> $PROJECT_DIR/working/proprietary/Audio-ACDB

# Bluetooth
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libbthost_if|btnvtool|hci_qcomm_init|wcnss_filter|bluetooth|libbt" | grep -v "vendor/etc/permissions" | grep -v "libbthost_if" | grep -v "overlay/" | sort -u >> $PROJECT_DIR/working/proprietary/Bluetooth

# Bluetooth-AptX
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "aptx" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/Bluetooth-AptX

# Camera blobs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libactuator|vendor/lib64/libactuator" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-actuators
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libarcsoft|vendor/lib64/libarcsoft" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-arcsoft
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/bin/" | grep -iE "camera" | grep -v "android.hardware.camera.provider@" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-bin
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libchromatix|vendor/lib64/libchromatix" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-chromatix
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/camera|vendor/etc/qvr/|vendor/camera3rd/|vendor/camera_sound|vendor/etc/FLASH_ON/|vendor/etc/IMX|vendor/camera/" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-configs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/firmware/cpp_firmware|vendor/firmware/CAMERA" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-firmware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libDepthBokeh|libSonyDual|libtriplecam|libremosaic|lib/camera/|lib64/camera/|libcamx|libcamera|mibokeh|lib_camera|libgcam|libdualcam|libmakeup|libtriplecam|SuperSensor|SonyIMX|libmialgo|libsnpe" | grep -v "vendor/lib/rfsa/adsp/" | sort -u >> $PROJECT_DIR/working/proprietary/Camera
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "motor" | grep -v "odex" | grep -v "vdex" | grep -v "motorola" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-motor
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libois|vendor/lib64/libois" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-ois
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libmmcamera|vendor/lib64/libmmcamera" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-sensors

# CDSP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "cdsprpc|libcdsp|libsdsprpc" | sort -u >> $PROJECT_DIR/working/proprietary/CDSP

# Charger
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/bin/hvdcp_opti|vendor/charge/chargemon/" | sort -u >> $PROJECT_DIR/working/proprietary/Charger

# Consumerir
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "consumerir" | grep -v "android.hardware.consumerir.xml" | sort -u >> $PROJECT_DIR/working/proprietary/Consumerir

# CNE
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "cne.server|vendor/etc/cne/|quicinc.cne.|cneapiclient|vendor.qti.hardware.data|libcne" | grep -v "latency" | sort -u >> $PROJECT_DIR/working/proprietary/CNE

# CVP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libcvp|cvp@" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/CVP

# Display
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/dsi_|video_dsi_panel" | grep "xml" | sort -u >> $PROJECT_DIR/working/proprietary/Display

# Display calibration
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/qdcm_calib" | sort -u >> $PROJECT_DIR/working/proprietary/Display-calibration

# Dolby
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "dolby" | sort -u >> $PROJECT_DIR/working/proprietary/Dolby

# DPM
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "dpm.api@" | sort -u >> $PROJECT_DIR/working/proprietary/DPM

# DRM-Widevine
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "firmware/widevine" | sort -u >> $PROJECT_DIR/working/proprietary/DRM-Widevine

# DTS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/dts/|libdts|libomx-dts" | sort -u >> $PROJECT_DIR/working/proprietary/DTS

# ESE-Powermanager
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "esepowermanager" | sort -u >> $PROJECT_DIR/working/proprietary/ESE-Powermanager

# Factory
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "data.factory|hardware.factory" | sort -u >> $PROJECT_DIR/working/proprietary/Factory

# Fido
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "fido" | sort -u >> $PROJECT_DIR/working/proprietary/Fido

# Fingerprint
cat $PROJECT_DIR/working/rom_all.txt | grep "etc/firmware/goodixfp|etc/firmware/fpctzappfingerprint" | sort -u >> $PROJECT_DIR/working/proprietary/Fingerprint
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "fpctzappfingerprint|silead|biometrics|etc/qti_fp/|libgf_|fingerprint|goodix|cdfinger|qfp-daemon|init_qfp_daemon|libqfp|fp_hal|libsl_fp|libarm_proxy_skel|libhvx_proxy_stub" | grep -v "android.hardware.fingerprint.xml" | grep -v "/usr/" | sort -u >> $PROJECT_DIR/working/proprietary/Fingerprint

# Firmware
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/firmware/|etc/firmware/" | grep -v "cpp_firmware" | grep -v "libpn5" | grep -v "ipa_fws" | sort -u >> $PROJECT_DIR/working/proprietary/Firmware

# Gatekeeper
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "gatekeeper" | sort -u >> $PROJECT_DIR/working/proprietary/Gatekeeper

# Google
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "google" | grep -v "etc/media_codecs_google" | sort -u >> $PROJECT_DIR/working/proprietary/Google

# GPS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libizat_|liblowi_|libloc_|liblocation|qti.gnss|gnss@" | sort -u >> $PROJECT_DIR/working/proprietary/GPS

# Graphics
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libc2d30" | sort -u >> $PROJECT_DIR/working/proprietary/Graphics

# IOP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "iop@|iopd" | sort -u >> $PROJECT_DIR/working/proprietary/IOP

# IPA-Firmware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/firmware/ipa_fws" | sort -u >> $PROJECT_DIR/working/proprietary/IPA-Firmware

# Kernel-Modules
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/modules/" | sort -u >> $PROJECT_DIR/working/proprietary/Kernel-Modules

# Keymaster
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "keymaster" | sort -u >> $PROJECT_DIR/working/proprietary/Keymaster

# Keystore
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "keystore|libspcom" | sort -u >> $PROJECT_DIR/working/proprietary/Keystore

# Latency
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "data.latency|qti.latency" | grep -v "odex" | grep -v "vdex" | sort -u >> $PROJECT_DIR/working/proprietary/Latency

# Listen
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "liblisten" | sort -u >> $PROJECT_DIR/working/proprietary/Listen

# Machine-Learning
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "mlshal" | sort -u >> $PROJECT_DIR/working/proprietary/Machine-Learning

# Media
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.qti.hardware.vpp|libvpp" | sort -u >> $PROJECT_DIR/working/proprietary/Media

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

# Qdutils_disp
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "qdutils_disp" | sort -u >> $PROJECT_DIR/working/proprietary/Qdutils

# Qteeconnector
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "qteeconnector" | sort -u >> $PROJECT_DIR/working/proprietary/Qteeconnector

# Pasrmanager
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "pasrmanager" | sort -u >> $PROJECT_DIR/working/proprietary/Pasrmanager

# Perf
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "perf@|etc/perf/|libqti-perf|libqti-util" | sort -u >> $PROJECT_DIR/working/proprietary/Perf

# Postprocessing
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.display.color|vendor.display.postproc" | sort -u >> $PROJECT_DIR/working/proprietary/Postprocessing

# Radio
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "radio/|vendor.qti.hardware.radio" | grep -v "vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio

# Radio-IMS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "imsrtpservice|imscmservice|uceservice|vendor.qti.ims.|lib-ims|radio.ims@|vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS

# SCVE
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "scve" | sort -u >> $PROJECT_DIR/working/proprietary/SCVE

# Seccam
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "seccam" | sort -u >> $PROJECT_DIR/working/proprietary/Seccam

# Sensors
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libsensor|lib64/sensors|lib/sensors|libAsusRGBSensorHAL|lib/hw/sensors|lib64/hw/sensors|libssc" | sort -u >> $PROJECT_DIR/working/proprietary/Sensors

# Sensor-calibrate
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "sensorscalibrate" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-calibrate

# Sensor-configs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/sensors/" | grep -v "vendor/etc/sensors/hals.conf" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-configs

# Sony
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.semc|vendor.somc|sony" | sort -u >> $PROJECT_DIR/working/proprietary/Sony

# Soter
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "soter" | sort -u >> $PROJECT_DIR/working/proprietary/Soter

# SSR
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "bin/ssr_|subsystem" | sort -u >> $PROJECT_DIR/working/proprietary/SSR

# Thermal
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/thermal|bin/thermal|libthermal" | sort -u >> $PROJECT_DIR/working/proprietary/Thermal

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
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "wifidisplayhal|wfdservice|libwfd|wfdconfig" | sort -u >> $PROJECT_DIR/working/proprietary/WFD

# Xiaomi
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor.xiaomi.hardware.misys" | grep -v "odex" | grep -v "vdex" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "xiaomi|mlipay|mtd|tidad|libmt|libtida|libmivendor" | grep -v "camera" | grep -v "vendor/etc/nuance/" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi

# Delete empty lists
find $PROJECT_DIR/working/proprietary -size  0 -print0 | xargs -0 rm --

# Add blobs from lists
blobs_list=`find $PROJECT_DIR/working/proprietary -type f -printf '%P\n' | sort`
for list in $blobs_list ; do
	file_lines=`cat $PROJECT_DIR/working/proprietary/$list | sort -u`
	printf "\n# $list\n" >> $PROJECT_DIR/working/proprietary-files.txt
	for line in $file_lines ; do
		if cat $PROJECT_DIR/working/rom_all.txt | grep "$line"; then
			if echo "$line" | grep -iE "vendor.qti.hardware.fm@1.0.so" | grep -v "vendor/"; then
				echo "-$line" >> $PROJECT_DIR/working/proprietary-files.txt
			elif echo "$line" | grep -iE "priv-app/imssettings/imssettings.apk"; then
				echo "-$line" >> $PROJECT_DIR/working/proprietary-files.txt
			elif echo "$line" | grep -iE "app/|lib64/com.quicinc.cne|libaudio_log_utils.so|libgpustats.so|libsdm-disp-vndapis.so|libthermalclient.so|WfdCommon.jar|libantradio.so"; then
				echo "-$line" >> $PROJECT_DIR/working/proprietary-files.txt
			else
				echo "$line" >> $PROJECT_DIR/working/proprietary-files.txt
			fi
		fi
	done
done

# List all vendor blobs
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | sort -u > $PROJECT_DIR/working/staging.txt

# Clean up misc
file_lines=`cat $PROJECT_DIR/tools/lists/remove.txt`
for line in $file_lines; do
	sed -i "s|$line.*||g" $PROJECT_DIR/working/staging.txt
done
sed -i "s|.*\.sh||g" $PROJECT_DIR/working/staging.txt
sed -i '/^$/d' $PROJECT_DIR/working/staging.txt

# Add missing blobs as misc
printf "\n# Misc\n" >> $PROJECT_DIR/working/proprietary-files.txt
file_lines=`cat $PROJECT_DIR/working/staging.txt`
for line in $file_lines; do
	# Missing
	if ! grep -q "$line" $PROJECT_DIR/working/proprietary-files.txt; then
		if ! grep -q "$line" $PROJECT_DIR/tools/lists/ignore.txt; then
			if echo "$line" | grep -iE "apk|jar"; then
				echo "-$line" >> $PROJECT_DIR/working/proprietary-files.txt
			else
				echo "$line" >> $PROJECT_DIR/working/proprietary-files.txt
			fi
		fi
	fi
done

# remove system/
sed -i "s|system/||g" $PROJECT_DIR/working/proprietary-files.txt

# remove duplicates
awk '!NF || !seen[$0]++' $PROJECT_DIR/working/proprietary-files.txt > $PROJECT_DIR/working/proprietary-files-new.txt
cat $PROJECT_DIR/working/proprietary-files-new.txt > $PROJECT_DIR/working/proprietary-files.txt

# cleanup temp files
find $PROJECT_DIR/working/* ! -name 'proprietary-files.txt' -type d,f -exec rm -rf {} +

echo -e "${bold}${cyan}$(ls -d $PROJECT_DIR/working/proprietary-files.txt) prepared!${nocol}"
