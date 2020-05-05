#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit 1
fi

# Install some packages
if [[ -e "/usr/bin/apt-get" ]]; then
    apt-get install -y aria2 arj brotli cabextract cmake device-tree-compiler file-roller g++ git liblz4-tool liblzma-dev libtinyxml2-dev mpack openjdk-8-jdk p7zip-full p7zip-rar python3-pip rar rename sharutils unace unrar unzip uudeview zip
elif [[ -e "/usr/bin/pacman" ]]; then
    pacman -Syu --noconfirm android-tools aria2 arj brotli cabextract cmake dtc file-roller gcc git lz4 xz tinyxml2 mpack jdk8-openjdk p7zip python2-pip python-pip rename rar unrar sharutils unace zip unzip uudeview zip
fi
pip3 install backports.lzma docopt protobuf pycrypto zstandard
