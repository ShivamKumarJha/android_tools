#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Password
if [ -z "$1" ]; then
	read -p "Enter user password: " user_password
else
	user_password=$1
fi

# Install some packages
echo "$user_password" | sudo -S apt-get install -y android-tools-fsutils brotli git device-tree-compiler python3-pip
pip3 install pycryptodome

# Clone repo's
for toolsdir in "extract_android_ota_payload" "extract-dtb" "mkbootimg_tools" "oppo_ozip_decrypt" "sdat2img"; do
	if [ ! -d "$PROJECT_DIR/tools/$toolsdir" ]; then
		git clone -q https://gitlab.com/ShivamKumarJha/$toolsdir $PROJECT_DIR/tools/$toolsdir --depth 1
		chmod +x $PROJECT_DIR/tools/$toolsdir/*
	fi
done
