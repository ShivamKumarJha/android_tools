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

# Exit if no arguements
if [ -z "$1" ] ; then
	echo -e "${bold}${red}Supply password as arguement!${nocol}"
	exit
fi

# Clone repo's
for toolsdir in "extract_android_ota_payload" "mkbootimg_tools" "sdat2img"; do
	if [ ! -d "$PROJECT_DIR/tools/$toolsdir" ]; then
		git clone -q https://gitlab.com/ShivamKumarJha/$toolsdir $PROJECT_DIR/tools/$toolsdir
		chmod +x $PROJECT_DIR/tools/$toolsdir/*
	fi
done

# Install some packages
echo "$1" | sudo -S apt-get install -y android-tools-fsutils brotli git
