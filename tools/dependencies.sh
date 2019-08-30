#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Password
if [ "$EUID" -ne 0 ] && [ -z "$user_password" ]; then
    read -p "Enter user password: " user_password
fi

# Install some packages
echo "$user_password" | sudo -S apt-get install -y android-tools-fsutils aria2 arj brotli cabextract device-tree-compiler file-roller git liblz4-tool liblzma-dev mpack p7zip-full p7zip-rar python-pip python3-pip rar sharutils unace unrar unzip uudeview zip cmake g++ libtinyxml2-dev
pip install backports.lzma protobuf pycrypto

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
