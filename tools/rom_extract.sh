#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

SECONDS=0

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

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
source $PROJECT_DIR/tools/common_script.sh

# Password
read -p "Enter user password: " user_password

core () {
	# Variables
	FILE=${URL##*/}
	EXTENSION=${URL##*.}
	UNZIP_DIR=${FILE/.$EXTENSION/}
	PARTITIONS="system vendor cust odm oem factory product modem xrom systemex"
	[[ -d $PROJECT_DIR/dumps/$UNZIP_DIR/ ]] && rm -rf $PROJECT_DIR/dumps/$UNZIP_DIR/

	# Firmware extractor
	bash $PROJECT_DIR/tools/Firmware_extractor/extractor.sh ${URL} $PROJECT_DIR/dumps/${UNZIP_DIR}

	# boot.img operations
	if [ -e $PROJECT_DIR/dumps/${UNZIP_DIR}/boot.img ]; then
		# Extract kernel
		bash $PROJECT_DIR/tools/mkbootimg_tools/mkboot $PROJECT_DIR/dumps/${UNZIP_DIR}/boot.img $PROJECT_DIR/dumps/${UNZIP_DIR}/boot/ > /dev/null 2>&1
		mv $PROJECT_DIR/dumps/${UNZIP_DIR}/boot/kernel $PROJECT_DIR/dumps/${UNZIP_DIR}/boot/Image.gz-dtb
		# Extract dtb
		echo -e "${bold}${cyan}Extracting dtb${nocol}"
		python3 $PROJECT_DIR/tools/extract-dtb/extract-dtb.py $PROJECT_DIR/dumps/${UNZIP_DIR}/boot.img -o $PROJECT_DIR/dumps/${UNZIP_DIR}/bootimg > /dev/null 2>&1
		# Extract dts
		mkdir $PROJECT_DIR/dumps/${UNZIP_DIR}/bootdts
		dtb_list=`find $PROJECT_DIR/dumps/${UNZIP_DIR}/bootimg -name '*.dtb' -type f -printf '%P\n' | sort`
		for dtb_file in $dtb_list; do
			dtc -I dtb -O dts -o $(echo "$PROJECT_DIR/dumps/${UNZIP_DIR}/bootdts/$dtb_file" | sed -r 's|.dtb|.dts|g') $PROJECT_DIR/dumps/${UNZIP_DIR}/bootimg/$dtb_file > /dev/null 2>&1
		done
	fi

	# dtbo
	if [[ -f $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo.img ]]; then
		python3 $PROJECT_DIR/tools/extract-dtb/extract-dtb.py $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo.img -o $PROJECT_DIR/dumps/${UNZIP_DIR}/dtbo > /dev/null 2>&1
		echo -e "${bold}${cyan}dtbo extracted${nocol}"
	fi

	# mounting
	for file in $PARTITIONS; do
		if [ -e "$PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img" ]; then
			DIR_NAME=$(echo $file | cut -d . -f1)
			echo -e "${bold}${cyan}Mounting & copying ${DIR_NAME}${nocol}"
			mkdir -p $PROJECT_DIR/dumps/${UNZIP_DIR}/$DIR_NAME $PROJECT_DIR/dumps/$UNZIP_DIR/tempmount
			# mount & permissions
			if [ "$file" == "modem" ]; then
				echo $user_password | sudo -S mount -t vfat -o loop "$PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img" "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
			else
				echo $user_password | sudo -S mount -t ext4 -o loop "$PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img" "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
			fi
			echo $user_password | sudo -S chown -R $USER:$USER "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
			echo $user_password | sudo -S chmod -R u+rwX "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount" > /dev/null 2>&1
			# copy to dump
			cp -a $PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount/* $PROJECT_DIR/dumps/$UNZIP_DIR/$DIR_NAME > /dev/null 2>&1
			# cleanup
			echo $user_password | sudo -S umount -l "$PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount"
			rm -rf $PROJECT_DIR/dumps/${UNZIP_DIR}/tempmount $PROJECT_DIR/dumps/${UNZIP_DIR}/$file.img
		fi
	done

	# board-info.txt & all_files.txt
	if [ -d $PROJECT_DIR/dumps/${UNZIP_DIR}/modem ]; then
		find $PROJECT_DIR/dumps/${UNZIP_DIR}/modem -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
		find $PROJECT_DIR/dumps/${UNZIP_DIR}/modem -type f -exec strings {} \; | grep "Time_Stamp\": \"" | tr -d ' ' | cut -c 15- | sed 's/.$//' | sed -e 's/^/require version-modem=/' >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
	fi
	find $PROJECT_DIR/dumps/${UNZIP_DIR}/ -maxdepth 1 -name "tz*" -type f -exec strings {} \; | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
	if [ -e $PROJECT_DIR/dumps/${UNZIP_DIR}/vendor/build.prop ]; then
		strings $PROJECT_DIR/dumps/${UNZIP_DIR}/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
	fi
	sort -u -o $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt $PROJECT_DIR/dumps/${UNZIP_DIR}/board-info.txt
	find $PROJECT_DIR/dumps/${UNZIP_DIR} -type f -printf '%P\n' | sort | grep -v ".git/" > $PROJECT_DIR/dumps/${UNZIP_DIR}/all_files.txt
}

for var in "$@"; do
	URL=$( realpath "$var" )
	core
	duration=$SECONDS
	echo -e "${bold}${cyan}Dump location: $PROJECT_DIR/dumps/$UNZIP_DIR/${nocol}"
	echo -e "${bold}${cyan}Extract time: $(($duration / 60)) minutes and $(($duration % 60)) seconds.${nocol}"
done
