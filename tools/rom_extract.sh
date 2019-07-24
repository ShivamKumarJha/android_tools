#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

SECONDS=0

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Create repo?
read -p "Create repo (y/n): " create_repo

# Dependencies check
if [ ! -d "$PROJECT_DIR/tools/Firmware_extractor" ] || [ ! -d "$PROJECT_DIR/tools/extract-dtb" ] || [ ! -d "$PROJECT_DIR/tools/mkbootimg_tools" ]; then
	echo -e "${bold}${red}Missing dependencies!Run: bash tools/dependencies.sh${nocol}"
	exit
fi

# Exit if no arguements
if [ -z "$1" ] ; then
	echo -e "${bold}${red}Supply OTA file(s) as arguement!${nocol}"
	exit
fi

# Common stuff
source $PROJECT_DIR/tools/common_script.sh "y"

core () {
	# Variables
	FILE=${URL##*/}
	EXTENSION=${URL##*.}
	UNZIP_DIR=${FILE/.$EXTENSION/}
	PARTITIONS="system vendor cust odm oem factory product modem xrom"

	# Firmware extractor
	bash $PROJECT_DIR/tools/Firmware_extractor/extractor.sh ${URL} $PROJECT_DIR/working/${UNZIP_DIR}

	# boot.img operations
	if [ -e $PROJECT_DIR/working/${UNZIP_DIR}/boot.img ]; then
		# Extract kernel
		bash $PROJECT_DIR/tools/mkbootimg_tools/mkboot $PROJECT_DIR/working/${UNZIP_DIR}/boot.img $PROJECT_DIR/working/${UNZIP_DIR}/boot/ > /dev/null 2>&1
		mv $PROJECT_DIR/working/${UNZIP_DIR}/boot/kernel $PROJECT_DIR/working/${UNZIP_DIR}/boot/Image.gz-dtb
		# Extract dtb
		echo -e "${bold}${cyan}Extracting dtb${nocol}"
		python3 $PROJECT_DIR/tools/extract-dtb/extract-dtb.py $PROJECT_DIR/working/${UNZIP_DIR}/boot.img -o $PROJECT_DIR/working/${UNZIP_DIR}/bootimg > /dev/null 2>&1
		# Extract dts
		mkdir $PROJECT_DIR/working/${UNZIP_DIR}/bootdts
		dtb_list=`find $PROJECT_DIR/working/${UNZIP_DIR}/bootimg -name '*.dtb' -type f -printf '%P\n' | sort`
		for dtb_file in $dtb_list; do
			echo -e "${bold}${cyan}Extracting dts from $dtb_file${nocol}"
			dtc -I dtb -O dts -o $(echo "$PROJECT_DIR/working/${UNZIP_DIR}/bootdts/$dtb_file" | sed -r 's|.dtb|.dts|g') $PROJECT_DIR/working/${UNZIP_DIR}/bootimg/$dtb_file > /dev/null 2>&1
		done
	fi

	# dtbo
	if [[ -f $PROJECT_DIR/working/${UNZIP_DIR}/dtbo.img ]]; then
		python3 $PROJECT_DIR/tools/extract-dtb/extract-dtb.py $PROJECT_DIR/working/${UNZIP_DIR}/dtbo.img -o $PROJECT_DIR/working/${UNZIP_DIR}/dtbo > /dev/null 2>&1
		echo -e "${bold}${cyan}dtbo extracted${nocol}"
	fi

	# extract partitions
	for p in $PARTITIONS; do
		mkdir $PROJECT_DIR/working/${UNZIP_DIR}/$p || rm -rf $PROJECT_DIR/working/${UNZIP_DIR}/$p/*
		echo -e "${bold}${cyan}$p extracted${nocol}"
		7z x $PROJECT_DIR/working/${UNZIP_DIR}/$p.img -y -o$PROJECT_DIR/working/${UNZIP_DIR}/$p/ 2>/dev/null
		rm $PROJECT_DIR/working/${UNZIP_DIR}/$p.img 2>/dev/null
	done

	# board-info.txt
	find $PROJECT_DIR/working/${UNZIP_DIR}/modem -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> $PROJECT_DIR/working/${UNZIP_DIR}/board-info.txt
	find $PROJECT_DIR/working/${UNZIP_DIR}/modem -type f -exec strings {} \; | grep "Time_Stamp\": \"" | tr -d ' ' | cut -c 15- | sed 's/.$//' | sed -e 's/^/require version-modem=/' >> $PROJECT_DIR/working/${UNZIP_DIR}/board-info.txt
	find $PROJECT_DIR/working/${UNZIP_DIR}/tz* -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> $PROJECT_DIR/working/${UNZIP_DIR}/board-info.txt
	if [ -e $PROJECT_DIR/working/${UNZIP_DIR}/vendor/build.prop ]; then
		strings $PROJECT_DIR/working/${UNZIP_DIR}/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> $PROJECT_DIR/working/${UNZIP_DIR}/board-info.txt
	fi
	sort -u -o $PROJECT_DIR/working/${UNZIP_DIR}/board-info.txt $PROJECT_DIR/working/${UNZIP_DIR}/board-info.txt

	# Permissions & store all_files.txt
	sudo chown $(whoami) * -R ; chmod -R u+rwX *
	find $PROJECT_DIR/working/${UNZIP_DIR} -type f -printf '%P\n' | sort | grep -v ".git/" > $PROJECT_DIR/working/${UNZIP_DIR}/all_files.txt

	# Move to dumps
	if [ -d $PROJECT_DIR/dumps/${UNZIP_DIR}/ ]; then
		rm -rf $PROJECT_DIR/dumps/${UNZIP_DIR}/
	fi
	mv $PROJECT_DIR/working/${UNZIP_DIR}/ $PROJECT_DIR/dumps/${UNZIP_DIR}/

	# Create repo
	if [ "$create_repo" == "y" ]; then
		bash "$PROJECT_DIR"/tools/dump_push.sh $PROJECT_DIR/dumps/${UNZIP_DIR}/
	fi
}

for var in "$@"; do
	URL="$var"
	core
	duration=$SECONDS
	echo -e "${bold}${cyan}Extract time: $(($duration / 60)) minutes and $(($duration % 60)) seconds.${nocol}"
done
