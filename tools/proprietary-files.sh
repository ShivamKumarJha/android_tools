#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/tools/colors.sh

# Arguement checking
if [ -z "$1" ] || [ ! -d "$1" ]; then
	echo -e "${bold}${red}Supply ROM directory as arguement!${nocol}"
	exit 1
fi

# Create $PROJECT_DIR/working directory if it does not exist
if [ ! -d $PROJECT_DIR/working ]; then
	mkdir -p $PROJECT_DIR/working
fi

# clean old
rm -rf $PROJECT_DIR/working/*

# Copy lists to $PROJECT_DIR/working
cp -a $PROJECT_DIR/tools/lists/proprietary/ $PROJECT_DIR/working/

# ADSP modules
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/lib/rfsa/adsp/|vendor/dsp/" | grep -v "scve" | sort -u >> $PROJECT_DIR/working/proprietary/ADSP-Modules

# Alarm
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "alarm" | sort -u >> $PROJECT_DIR/working/proprietary/Alarm

# ANT
find $1 -type f,l -printf '%P\n' | sort | grep -iE "libantradio|qti.ant@" | sort -u >> $PROJECT_DIR/working/proprietary/ANT

# AptX
find $1 -type f,l -printf '%P\n' | sort | grep -iE "aptx" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/AptX

# Audio
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "libsrsprocessing|libaudio|libacdb|libdirac|etc/dirac" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/Audio

# Audio-ACDB
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/etc/acdbdata/" | sort -u >> $PROJECT_DIR/working/proprietary/Audio-ACDB

# Camera blobs
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/lib/libactuator|vendor/lib64/libactuator" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-actuators
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/lib/libarcsoft|vendor/lib64/libarcsoft" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-arcsoft
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/bin/" | grep -iE "camera" | grep -v "android.hardware.camera.provider@" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-bin
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/lib/libchromatix|vendor/lib64/libchromatix" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-chromatix
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/etc/camera|vendor/etc/qvr/|vendor/camera3rd/|vendor/camera_sound" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-configs
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/firmware/cpp_firmware" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-firmware
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "libremosaic|lib/camera/|lib64/camera/|libcamx|libcamera|mibokeh|lib_camera|libgcam|libdualcam|libmakeup|libtriplecam" | grep -v "vendor/lib/rfsa/adsp/" | sort -u >> $PROJECT_DIR/working/proprietary/Camera
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/lib/libois|vendor/lib64/libois" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-ois
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "scve" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-scve
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/lib/libmmcamera|vendor/lib64/libmmcamera" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-sensors

# CDSP
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "cdsprpc|libcdsp|libsdsprpc" | sort -u >> $PROJECT_DIR/working/proprietary/CDSP

# Charger
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/bin/hvdcp_opti" | sort -u >> $PROJECT_DIR/working/proprietary/Charger

# Consumerir
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "consumerir" | grep -v "android.hardware.consumerir.xml" | sort -u >> $PROJECT_DIR/working/proprietary/Consumerir

# CNE
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "cne.server|vendor/etc/cne/|quicinc.cne.|cneapiclient|vendor.qti.hardware.data|libcne" | sort -u >> $PROJECT_DIR/working/proprietary/CNE

# Display
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "etc/dsi_|video_dsi_panel" | grep "xml" | sort -u >> $PROJECT_DIR/working/proprietary/Display

# Display calibration
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/etc/qdcm_calib" | sort -u >> $PROJECT_DIR/working/proprietary/Display-calibration

# Dolby
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "dolby" | sort -u >> $PROJECT_DIR/working/proprietary/Dolby

# DPM
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "dpm.api@" | sort -u >> $PROJECT_DIR/working/proprietary/DPM

# DTS
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "etc/dts/|libdts|libomx-dts" | sort -u >> $PROJECT_DIR/working/proprietary/DTS

# ESE-Powermanager
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "esepowermanager" | sort -u >> $PROJECT_DIR/working/proprietary/ESE-Powermanager

# Factory
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "data.factory|hardware.factory" | sort -u >> $PROJECT_DIR/working/proprietary/Factory

# Fido
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "fido" | sort -u >> $PROJECT_DIR/working/proprietary/Fido

# Fingerprint
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "libgf_|fingerprint|goodix|cdfinger|qfp-" | grep -v "android.hardware.fingerprint.xml" | sort -u >> $PROJECT_DIR/working/proprietary/Fingerprint

# Firmware
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/firmware/|etc/firmware/" | grep -v "cpp_firmware" | sort -u >> $PROJECT_DIR/working/proprietary/Firmware

# Gatekeeper
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "gatekeeper" | sort -u >> $PROJECT_DIR/working/proprietary/Gatekeeper

# Google
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "google" | grep -v "etc/media_codecs_google" | sort -u >> $PROJECT_DIR/working/proprietary/Google

# GPS
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "libizat_|liblowi_|libloc_|liblocation|qti.gnss|gnss@" | sort -u >> $PROJECT_DIR/working/proprietary/GPS

# Graphics
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "libc2d30" | sort -u >> $PROJECT_DIR/working/proprietary/Graphics

# IOP
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "iop@|iopd" | sort -u >> $PROJECT_DIR/working/proprietary/IOP

# Keymaster
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "keymaster" | sort -u >> $PROJECT_DIR/working/proprietary/Keymaster

# Keystore
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "keystore" | sort -u >> $PROJECT_DIR/working/proprietary/Keystore

# Listen
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "liblisten" | sort -u >> $PROJECT_DIR/working/proprietary/Listen

# Meizu
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "meizu" | sort -u >> $PROJECT_DIR/working/proprietary/Meizu

# Media
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "vendor.qti.hardware.vpp|libvpp" | sort -u >> $PROJECT_DIR/working/proprietary/Media

# NFC
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "lib/libpn5" | sort -u >> $PROJECT_DIR/working/proprietary/NFC

# Neural-networks
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "neuralnetworks|libhexagon" | sort -u >> $PROJECT_DIR/working/proprietary/Neural-networks

# OnePlus
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "oneplus" | sort -u >> $PROJECT_DIR/working/proprietary/OnePlus

# qdutils_disp
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "qdutils_disp" | sort -u >> $PROJECT_DIR/working/proprietary/Qdutils

# qteeconnector
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "qteeconnector" | sort -u >> $PROJECT_DIR/working/proprietary/Qteeconnector

# Perf
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "perf@|etc/perf/|libqti-perf|libqti-util" | sort -u >> $PROJECT_DIR/working/proprietary/Perf

# Postprocessing
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "vendor.display.color|vendor.display.postproc" | sort -u >> $PROJECT_DIR/working/proprietary/Postprocessing

# Radio
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "radio/|vendor.qti.hardware.radio" | grep -v "vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio

# Radio-IMS
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "imsrtpservice|imscmservice|uceservice|vendor.qti.ims.|lib-ims|radio.ims@|vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS

# Sensors
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "libsensor|lib64/sensors|lib/sensors|libAsusRGBSensorHAL|lib/hw/sensors|lib64/hw/sensors" | sort -u >> $PROJECT_DIR/working/proprietary/Sensors

# Sensor calibrate
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "sensorscalibrate" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-calibrate

# Sensor configs
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor/etc/sensors/" | grep -v "vendor/etc/sensors/hals.conf" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-configs

# Soter
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "soter" | sort -u >> $PROJECT_DIR/working/proprietary/Soter

# SSR
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "bin/ssr_|subsystem" | sort -u >> $PROJECT_DIR/working/proprietary/SSR

# Thermal
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "etc/thermal|bin/thermal|libthermal" | sort -u >> $PROJECT_DIR/working/proprietary/Thermal

# Touch improve
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "improvetouch" | sort -u >> $PROJECT_DIR/working/proprietary/Touch-improve

# Touchscreen
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "etc/hbtp/|libhbtp" | sort -u >> $PROJECT_DIR/working/proprietary/Touchscreen

# TUI
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "tui_comm" | sort -u >> $PROJECT_DIR/working/proprietary/TUI

# Vivo
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "vivo" | sort -u >> $PROJECT_DIR/working/proprietary/Vivo

# Voice
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "voiceprint@|vendor/etc/qvop/|libqvop" | sort -u >> $PROJECT_DIR/working/proprietary/Voice

# WFD
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "wifidisplayhal|wfdservice|libwfd|wfdconfig" | sort -u >> $PROJECT_DIR/working/proprietary/WFD

# WiFi
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "vendor.qti.hardware.wifi|vendor.qti.hardware.wigig" | sort -u >> $PROJECT_DIR/working/proprietary/WiFi

# Xiaomi
find $1 -type f,l -printf '%P\n' | sort | grep -iE "vendor.xiaomi.hardware.misys" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi
find $1 -type f,l -printf '%P\n' | sort | grep "vendor/" | grep -iE "xiaomi|mlipay|mtd|tidad|libmt|libtida" | grep -v "camera" | grep -v "vendor/etc/nuance/" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi

# Delete empty lists
find $PROJECT_DIR/working/proprietary -size  0 -print0 | xargs -0 rm --

# Add blobs from lists
blobs_list=`find $PROJECT_DIR/working/proprietary -type f,l -printf '%P\n' | sort`
for list in $blobs_list ;
do
	file_lines=`cat $PROJECT_DIR/working/proprietary/$list | sort -u`
	printf "\n# $list\n" >> $PROJECT_DIR/working/staging.txt
	for line in $file_lines ;
	do
		if [ -e "$1/$line" ]; then
			if echo "$line" | grep -iE "vendor.qti.hardware.fm@1.0.so" | grep -v "vendor/"; then
				echo "-$line" >> $PROJECT_DIR/working/staging.txt
			elif echo "$line" | grep -iE "priv-app/imssettings/imssettings.apk"; then
				echo "-$line" >> $PROJECT_DIR/working/staging.txt
			elif echo "$line" | grep -iE "app/|lib64/com.quicinc.cne|libaudio_log_utils.so|libgpustats.so|libsdm-disp-vndapis.so|libthermalclient.so|WfdCommon.jar|libantradio.so"; then
				echo "-$line" >> $PROJECT_DIR/working/staging.txt
			else
				echo "$line" >> $PROJECT_DIR/working/staging.txt
			fi
		fi
	done
done

# Find missing blobs
printf "\n# Misc\n" >> $PROJECT_DIR/working/misc.txt
file_lines=`find $1 -type f,l -printf '%P\n' | sort | grep "vendor/"`
for line in $file_lines;
do
	# Missing
	if ! grep -q "$line" $PROJECT_DIR/working/staging.txt; then
		if ! grep -q "$line" $PROJECT_DIR/tools/lists/ignore.txt; then
			if echo "$line" | grep -iE "apk|jar"; then
				echo "-$line" >> $PROJECT_DIR/working/misc.txt
			else
				echo "$line" >> $PROJECT_DIR/working/misc.txt
			fi
		fi
	fi
done

# Clean up misc
file_lines=`cat $PROJECT_DIR/tools/lists/remove.txt`
for line in $file_lines;
do
	sed -i "s|$line.*||g" $PROJECT_DIR/working/misc.txt
done
sed -i "s|.*\.sh||g" $PROJECT_DIR/working/misc.txt
sed -i '/^$/d' $PROJECT_DIR/working/misc.txt

# Text formatting
awk '!NF || !seen[$0]++' $PROJECT_DIR/working/staging.txt > $PROJECT_DIR/working/staging2.txt
printf "\n" >> $PROJECT_DIR/working/staging2.txt
cat $PROJECT_DIR/working/staging2.txt $PROJECT_DIR/working/misc.txt > $PROJECT_DIR/working/proprietary-files.txt

# cleanup temp files
find $PROJECT_DIR/working/* ! -name 'proprietary-files.txt' -type d,f -exec rm -rf {} +

echo -e "${bold}${cyan}$(ls -d $PROJECT_DIR/working/proprietary-files.txt) prepared!${nocol}"
