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
echo "$user_password" | sudo -S apt-get install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack arj cabextract file-roller device-tree-compiler liblzma-dev python-pip brotli liblz4-tool aria2 android-tools-fsutils brotli python3-pip
pip3 install pycryptodome backports.lzma protobuf pycrypto

# Clone repo's
if [ -d "$PROJECT_DIR/tools/extract-dtb" ]; then
    git -C $PROJECT_DIR/tools/extract-dtb pull
else
    git clone https://github.com/PabloCastellano/extract-dtb $PROJECT_DIR/tools/extract-dtb
fi
if [ -d "$PROJECT_DIR/tools/mkbootimg_tools" ]; then
    git -C $PROJECT_DIR/tools/mkbootimg_tools pull
else
    git clone https://github.com/xiaolu/mkbootimg_tools $PROJECT_DIR/tools/mkbootimg_tools
fi
if [ -d "$PROJECT_DIR/tools/Firmware_extractor" ]; then
    git -C $PROJECT_DIR/tools/Firmware_extractor pull --recurse-submodules
    git -C $PROJECT_DIR/tools/Firmware_extractor pull https://github.com/AndroidDumps/Firmware_extractor master
else
    git clone --recurse-submodules https://github.com/ShivamKumarJha/Firmware_extractor $PROJECT_DIR/tools/Firmware_extractor
fi

chmod +x $PROJECT_DIR/tools/* $PROJECT_DIR/tools/prebuilt/*
