#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/tools/colors.sh

if [ -z "$1" ]; then
	echo -e "${bold}${red}Supply ROM file list as arguement!${nocol}"
	exit 1
fi

# Create $PROJECT_DIR/working directory if it does not exist
if [ ! -d $PROJECT_DIR/working ]; then
	mkdir -p $PROJECT_DIR/working
fi

# clean old
rm -rf $PROJECT_DIR/working/*

# copy $1
if echo "$1" | grep "https" ; then
	wget -O $PROJECT_DIR/working/rom_all.txt $1
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

# AptX
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "aptx" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/AptX

# Audio
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libsrsprocessing|libaudio|libacdb|libdirac|etc/dirac" | grep -v "lib/rfsa/adsp" | sort -u >> $PROJECT_DIR/working/proprietary/Audio

# Audio-ACDB
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/acdbdata/" | sort -u >> $PROJECT_DIR/working/proprietary/Audio-ACDB

# Camera blobs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libactuator|vendor/lib64/libactuator" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-actuators
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libarcsoft|vendor/lib64/libarcsoft" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-arcsoft
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/bin/" | grep -iE "camera" | grep -v "android.hardware.camera.provider@" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-bin
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libchromatix|vendor/lib64/libchromatix" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-chromatix
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/camera|vendor/etc/qvr/|vendor/camera3rd/|vendor/camera_sound" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-configs
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/firmware/cpp_firmware" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-firmware
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libremosaic|lib/camera/|lib64/camera/|libcamx|libcamera|mibokeh|lib_camera|libgcam|libdualcam|libmakeup|libtriplecam" | grep -v "vendor/lib/rfsa/adsp/" | sort -u >> $PROJECT_DIR/working/proprietary/Camera
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libois|vendor/lib64/libois" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-ois
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "scve" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-scve
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/lib/libmmcamera|vendor/lib64/libmmcamera" | sort -u >> $PROJECT_DIR/working/proprietary/Camera-sensors

# CDSP
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "cdsprpc|libcdsp|libsdsprpc" | sort -u >> $PROJECT_DIR/working/proprietary/CDSP

# Charger
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/bin/hvdcp_opti" | sort -u >> $PROJECT_DIR/working/proprietary/Charger

# Consumerir
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "consumerir" | grep -v "android.hardware.consumerir.xml" | sort -u >> $PROJECT_DIR/working/proprietary/Consumerir

# CNE
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "cne.server|vendor/etc/cne/|quicinc.cne.|cneapiclient|vendor.qti.hardware.data|libcne" | sort -u >> $PROJECT_DIR/working/proprietary/CNE

# Display
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/dsi_|video_dsi_panel" | grep "xml" | sort -u >> $PROJECT_DIR/working/proprietary/Display

# Display calibration
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/qdcm_calib" | sort -u >> $PROJECT_DIR/working/proprietary/Display-calibration

# Dolby
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "dolby" | sort -u >> $PROJECT_DIR/working/proprietary/Dolby

# DPM
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "dpm.api@" | sort -u >> $PROJECT_DIR/working/proprietary/DPM

# DTS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/dts/|libdts|libomx-dts" | sort -u >> $PROJECT_DIR/working/proprietary/DTS

# ESE-Powermanager
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "esepowermanager" | sort -u >> $PROJECT_DIR/working/proprietary/ESE-Powermanager

# Factory
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "data.factory|hardware.factory" | sort -u >> $PROJECT_DIR/working/proprietary/Factory

# Fido
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "fido" | sort -u >> $PROJECT_DIR/working/proprietary/Fido

# Fingerprint
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libgf_|fingerprint|goodix|cdfinger|qfp-" | grep -v "android.hardware.fingerprint.xml" | sort -u >> $PROJECT_DIR/working/proprietary/Fingerprint

# Firmware
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/firmware/|etc/firmware/" | grep -v "cpp_firmware" | sort -u >> $PROJECT_DIR/working/proprietary/Firmware

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

# Keymaster
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "keymaster" | sort -u >> $PROJECT_DIR/working/proprietary/Keymaster

# Keystore
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "keystore" | sort -u >> $PROJECT_DIR/working/proprietary/Keystore

# Listen
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "liblisten" | sort -u >> $PROJECT_DIR/working/proprietary/Listen

# Meizu
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "meizu" | sort -u >> $PROJECT_DIR/working/proprietary/Meizu

# Media
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.qti.hardware.vpp|libvpp" | sort -u >> $PROJECT_DIR/working/proprietary/Media

# NFC
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "lib/libpn5" | sort -u >> $PROJECT_DIR/working/proprietary/NFC

# Neural-networks
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "neuralnetworks|libhexagon" | sort -u >> $PROJECT_DIR/working/proprietary/Neural-networks

# OnePlus
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "oneplus" | sort -u >> $PROJECT_DIR/working/proprietary/OnePlus

# qdutils_disp
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "qdutils_disp" | sort -u >> $PROJECT_DIR/working/proprietary/Qdutils

# qteeconnector
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "qteeconnector" | sort -u >> $PROJECT_DIR/working/proprietary/Qteeconnector

# Perf
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "perf@|etc/perf/|libqti-perf|libqti-util" | sort -u >> $PROJECT_DIR/working/proprietary/Perf

# Postprocessing
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.display.color|vendor.display.postproc" | sort -u >> $PROJECT_DIR/working/proprietary/Postprocessing

# Radio
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "radio/|vendor.qti.hardware.radio" | grep -v "vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio

# Radio-IMS
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "imsrtpservice|imscmservice|uceservice|vendor.qti.ims.|lib-ims|radio.ims@|vendor.qti.hardware.radio.ims" | sort -u >> $PROJECT_DIR/working/proprietary/Radio-IMS

# Sensors
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "libsensor|lib64/sensors|lib/sensors|libAsusRGBSensorHAL|lib/hw/sensors|lib64/hw/sensors" | sort -u >> $PROJECT_DIR/working/proprietary/Sensors

# Sensor calibrate
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "sensorscalibrate" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-calibrate

# Sensor configs
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor/etc/sensors/" | grep -v "vendor/etc/sensors/hals.conf" | sort -u >> $PROJECT_DIR/working/proprietary/Sensor-configs

# Soter
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "soter" | sort -u >> $PROJECT_DIR/working/proprietary/Soter

# SSR
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "bin/ssr_|subsystem" | sort -u >> $PROJECT_DIR/working/proprietary/SSR

# Thermal
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/thermal|bin/thermal|libthermal" | sort -u >> $PROJECT_DIR/working/proprietary/Thermal

# Touch improve
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "improvetouch" | sort -u >> $PROJECT_DIR/working/proprietary/Touch-improve

# Touchscreen
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "etc/hbtp/|libhbtp" | sort -u >> $PROJECT_DIR/working/proprietary/Touchscreen

# TUI
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "tui_comm" | sort -u >> $PROJECT_DIR/working/proprietary/TUI

# Vivo
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vivo" | sort -u >> $PROJECT_DIR/working/proprietary/Vivo

# Voice
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "voiceprint@|vendor/etc/qvop/|libqvop" | sort -u >> $PROJECT_DIR/working/proprietary/Voice

# WFD
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "wifidisplayhal|wfdservice|libwfd|wfdconfig" | sort -u >> $PROJECT_DIR/working/proprietary/WFD

# WiFi
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "vendor.qti.hardware.wifi|vendor.qti.hardware.wigig" | sort -u >> $PROJECT_DIR/working/proprietary/WiFi

# Xiaomi
cat $PROJECT_DIR/working/rom_all.txt | grep -iE "vendor.xiaomi.hardware.misys" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi
cat $PROJECT_DIR/working/rom_all.txt | grep "vendor/" | grep -iE "xiaomi|mlipay|mtd|tidad|libmt|libtida" | grep -v "camera" | grep -v "vendor/etc/nuance/" | sort -u >> $PROJECT_DIR/working/proprietary/Xiaomi

# Delete empty lists
find $PROJECT_DIR/working/proprietary -size  0 -print0 | xargs -0 rm --

# Add blobs from lists
blobs_list=`find $PROJECT_DIR/working/proprietary -type f,l -printf '%P\n' | sort`
for list in $blobs_list ;
do
	file_lines=`cat $PROJECT_DIR/working/proprietary/$list | sort -u`
	printf "\n# $list\n" >> $PROJECT_DIR/working/proprietary-files.txt
	for line in $file_lines ;
	do
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
for line in $file_lines;
do
	sed -i "s|$line.*||g" $PROJECT_DIR/working/staging.txt
done
sed -i "s|.*\.sh||g" $PROJECT_DIR/working/staging.txt
sed -i '/^$/d' $PROJECT_DIR/working/staging.txt

# Add missing blobs as misc
printf "\n# Misc\n" >> $PROJECT_DIR/working/proprietary-files.txt
file_lines=`cat $PROJECT_DIR/working/staging.txt`
for line in $file_lines;
do
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
