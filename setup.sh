#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Install some packages
if [[ -e "/usr/bin/apt-get" ]]; then
    sudo apt-get install -y aria2 arj brotli cabextract cmake device-tree-compiler gcc g++ git liblz4-tool liblzma-dev libtinyxml2-dev lz4 mpack openjdk-11-jdk p7zip-full p7zip-rar python3 python3-pip rar sharutils unace unrar unzip uudeview xz-utils zip zlib1g-dev
elif [[ -e "/usr/bin/pacman" ]]; then
    sudo pacman -Syu --noconfirm android-tools aria2 arj brotli cabextract cmake dtc gcc git lz4 xz tinyxml2 p7zip python-pip unrar sharutils unace zip unzip uudeview zip
fi
pip3 install backports.lzma docopt protobuf pycrypto zstandard
