#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

SECONDS=0

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"
cd $PROJECT_DIR

# Text format
source $PROJECT_DIR/tools/colors.sh

# Password
if [ -z "$1" ]; then
	read -p "Enter user password: " user_password
else
	user_password=$1
fi

# Create repo?
if [ -z "$2" ]; then
	read -p "Create repo (y/n): " create_repo
else
	create_repo=$2
fi

# Dependecies check
. $PROJECT_DIR/tools/dependencies.sh "$user_password" > /dev/null 2>&1

# array variable storing potential partitions to be extracted
declare -a arr=("system" "vendor" "xrom")

clean_up()
{
	echo -e "${bold}${cyan}Unmounting images & performing cleanup.${nocol}"
	for i in "${arr[@]}" "modem"
	do
		if [ -d working/$i/ ]; then
			echo $user_password | sudo -S umount -l working/$i/
		fi
	done
	rm -rf working/*
}

repo_push()
{
	cd dumps/$DEVICE/
	# Set variables
	BRAND_TEMP=$( cat system/build.prop | grep "ro.product.brand=" | sed "s|ro.product.brand=||g" )
	BRAND=${BRAND_TEMP,,}
	if [ "$BRAND" = "vivo" ]; then
		DEVICE=$( cat system/build.prop | grep "ro.vivo.product.release.name=" | sed "s|ro.vivo.product.release.name=||g" )
	else
		DEVICE=$( cat system/build.prop | grep "ro.product.device=" | sed "s|ro.product.device=||g" | sed "s|ASUS_||g" )
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=$( cat system/build.prop | grep "ro.build.product=" | sed "s|ro.build.product=||g" | sed "s|ASUS_||g" )
	fi
	DESCRIPTION=$( cat system/build.prop | grep "ro.build.description=" | sed "s|ro.build.description=||g" )
	FINGERPRINT=$( cat system/build.prop | grep "ro.build.fingerprint=" | sed "s|ro.build.fingerprint=||g" )
	VERSION=$( cat system/build.prop | grep "ro.build.version.release=" | sed "s|ro.build.version.release=||g" | head -c 1)
	COMMIT_MSG=$(echo "$DEVICE: $FINGERPRINT")
	REPO=$(echo dump_$BRAND\_$DEVICE)
	REPO_DESC=$(echo "$DEVICE-dump")
	BRANCH=$(echo $DESCRIPTION | tr ' ' '-')
	# Create repository in GitHub
	curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name":"'${REPO}'","description":"'${REPO_DESC}'","private": true,"has_issues": false,"has_projects": false,"has_wiki": false}'
	# Add files & push
	if [ ! -d .git ]; then
		git init .
	fi
	git checkout --orphan $BRANCH
	find -size +97M -printf '%P\n' > .gitignore
	git add --all
	git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "$COMMIT_MSG"
	git remote add origin https://github.com/ShivamKumarJha/"$REPO".git
	git push https://"$GIT_TOKEN"@github.com/ShivamKumarJha/"$REPO".git $BRANCH
	cd $PROJECT_DIR
}

extract_subcomponent()
{
	if [ -e working/$ZIPDIR.new.dat.br ]; then
		echo -e "${bold}${cyan}Extracting working/${ZIPDIR}.new.dat.br${nocol}"
		brotli -d working/$ZIPDIR.new.dat.br
	fi

	if [ -e working/$ZIPDIR.new.dat ]; then
		echo -e "${bold}${cyan}Converting working/${ZIPDIR}.new.dat to working/${ZIPDIR}.img${nocol}"
		./tools/sdat2img/sdat2img.py working/$ZIPDIR.transfer.list working/$ZIPDIR.new.dat working/$ZIPDIR.img
	fi

	if [ -e working/$ZIPDIR.img ]; then
		echo -e "${bold}${cyan}Mounting working/${ZIPDIR}.img${nocol}"
		mkdir -p working/$ZIPDIR
		if [ "$IS_FASTBOOT" = "y" ]; then
			simg2img working/$ZIPDIR.img working/$ZIPDIR.ext4.img > /dev/null 2>&1
			echo $user_password | sudo -S mount -t ext4 -o loop working/$ZIPDIR.ext4.img working/$ZIPDIR/ > /dev/null 2>&1
		else
			echo $user_password | sudo -S mount -t ext4 -o loop working/$ZIPDIR.img working/$ZIPDIR/ > /dev/null 2>&1
		fi
		echo $user_password | sudo -S chown -R $USER:$USER working/$ZIPDIR/ > /dev/null 2>&1
		echo $user_password | sudo -S chmod -R 777 working/$ZIPDIR/ > /dev/null 2>&1
	fi

	if [ -z "$(ls -A working/$ZIPDIR/)" ] || [ ! -e working/$ZIPDIR.img ] ; then
		echo -e "${bold}${red}Error! Extracting sub-components failed.${nocol}"
		clean_up
		exit
	fi
}

core()
{
# A/B
if [ -e working/payload.bin ]; then
	./tools/extract_android_ota_payload/extract_android_ota_payload.py working/payload.bin working/
fi

# Extraction
for i in "${arr[@]}"
do
	if [ -e working/$i.img ] || [ -e working/$i.new.dat ] || [ -e working/$i.new.dat.br ] ; then
		ZIPDIR=$i
		extract_subcomponent
	fi
done

# set device name
if [ -e working/system/system/build.prop ]; then
	DEVICE=$( cat working/system/system/build*.prop | grep "ro.product.device=" | sed "s|ro.product.device=||g" )
	if [ -z "$DEVICE" ]; then
		DEVICE=$( cat working/system/system/build*.prop | grep "ro.build.product=" | sed "s|ro.build.product=||g" )
	fi
elif [ -e working/system/build.prop ]; then
	DEVICE=$( cat working/system/build*.prop | grep "ro.product.device=" | sed "s|ro.product.device=||g" )
	if [ -z "$DEVICE" ]; then
		DEVICE=$( cat working/system/build*.prop | grep "ro.build.product=" | sed "s|ro.build.product=||g" )
	fi
fi

if [ -z "$DEVICE" ]; then
	DEVICE=target
fi

# Copy to device folder
if [ ! -d dumps/$DEVICE ]; then
	mkdir -p dumps/$DEVICE
else
	echo -e "${bold}${cyan}Removing previously extracted files in dumps/${DEVICE}${nocol}"
	rm -rf dumps/$DEVICE/*
fi

# boot.img operations
find working/ -name 'boot.img' -exec mv {} working/bootdevice.img \;
if [ -e working/bootdevice.img ]; then
	./tools/mkbootimg_tools/mkboot working/bootdevice.img dumps/$DEVICE/boot > /dev/null 2>&1
	mv dumps/$DEVICE/boot/kernel dumps/$DEVICE/boot/Image.gz-dtb
	echo -e "${bold}${cyan}boot_info: $(ls dumps/$DEVICE/boot/img_info)${nocol}"
	echo -e "${bold}${cyan}Prebuilt kernel: $(ls dumps/$DEVICE/boot/Image.gz-dtb)${nocol}"
fi

# Store trustzone version in board-info.txt
find working/ -name 'tz.*' -exec mv {} working/tz \;
if [ -e working/tz ]; then
	strings working/tz | grep QC_IMAGE_VERSION_STRING | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" > dumps/$DEVICE/board-info.txt
	echo -e "${bold}${cyan}$(cat dumps/${DEVICE}/board-info.txt)${nocol}"
else
	echo -e "${bold}${cyan}tz not found!${nocol}"
fi

# Copy to dumps
echo -e "${bold}${cyan}Copying to dumps/${DEVICE}${nocol}"
if [ -e working/system/system/build.prop ]; then
	cp -a working/system/system/ dumps/$DEVICE > /dev/null 2>&1
else
	cp -a working/system/ dumps/$DEVICE > /dev/null 2>&1
fi

if [ -e working/vendor.img ]; then
	rm -rf dumps/$DEVICE/system/vendor
	cp -a working/vendor/ dumps/$DEVICE/system > /dev/null 2>&1
fi

# modem
find working/ -name 'NON-HLOS.bin' -exec mv {} working/modem.img \;
if [ -e working/modem.img ]; then
	mkdir -p working/modem
	echo $user_password | sudo -S mount -t vfat -o loop working/modem.img working/modem > /dev/null 2>&1
	echo $user_password | sudo -S chown -R $USER:$USER working/modem > /dev/null 2>&1
	echo $user_password | sudo -S chmod -R 777 working/modem > /dev/null 2>&1
fi

for imgdir in xrom modem; do
	if [ -e working/$imgdir.img ]; then
		echo -e "${bold}${cyan}Copying ${imgdir} to dumps/${DEVICE}/${nocol}"
		cp -a working/$imgdir/ dumps/$DEVICE/ > /dev/null 2>&1
	fi
done

# List ROM
find dumps/$DEVICE/system/ -type f -printf '%P\n' | sort > dumps/$DEVICE/all_files.txt

# Cleanup
clean_up

if [ $? -eq 0 ]; then
	# Display time taken
	duration=$SECONDS
	echo -e "${bold}${cyan}Extract time: $(($duration / 60)) minutes and $(($duration % 60)) seconds.${nocol}"
else
	echo -e "${bold}${red}Extract failed.${nocol}"
fi

# Create repo
if [ "$create_repo" = "y" ]; then
	repo_push
fi
}

# Create working directory if it does not exist
if [ ! -d working ]; then
	mkdir -p working
fi

# Extract ROM zip to working
if [ ! -e $PROJECT_DIR/input/*.zip ] && [ ! -e $PROJECT_DIR/input/*.tgz ]; then
	echo -e "${bold}${red}No zip or tgz file detected in input folder.${nocol}"
	exit
else
	if [ -e $PROJECT_DIR/input/*.zip ]; then
		for file in $PROJECT_DIR/input/*.zip; do
			unzip ${file} -d $PROJECT_DIR/working
			if ! [ $(find $PROJECT_DIR/working/ -name 'META-INF' | wc -l) -gt 0 ]; then
				IS_FASTBOOT=y
			else
				IS_FASTBOOT=n
			fi
			core
		done
	fi
	if [ -e $PROJECT_DIR/input/*.tgz ]; then
		for file in $PROJECT_DIR/input/*.tgz; do
			IS_FASTBOOT=y
			tar -zxvf ${file} -C $PROJECT_DIR/working
			for i in "${arr[@]}" "boot" "modem"; do
				find working/ -name "$i.img" -exec mv {} $PROJECT_DIR/working/$i.img \;
			done
			core
		done
	fi
fi

exit
