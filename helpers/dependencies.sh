#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Clone repo's
if [ -d "$PROJECT_DIR/tools/extract-dtb" ]; then
    git -C $PROJECT_DIR/tools/extract-dtb pull
else
    git clone https://github.com/PabloCastellano/extract-dtb $PROJECT_DIR/tools/extract-dtb
fi
if [ -d "$PROJECT_DIR/tools/mkbootimg_tools" ]; then
    git -C $PROJECT_DIR/tools/mkbootimg_tools pull
else
    git clone https://github.com/carlitros900/mkbootimg_tools $PROJECT_DIR/tools/mkbootimg_tools
fi
if [ -d "$PROJECT_DIR/tools/Firmware_extractor" ]; then
    git -C $PROJECT_DIR/tools/Firmware_extractor pull --recurse-submodules
else
    git clone --recurse-submodules https://github.com/ShivamKumarJha/Firmware_extractor $PROJECT_DIR/tools/Firmware_extractor
fi

# extract-ikconfig
[[ ! -e ${PROJECT_DIR}/helpers/extract-ikconfig ]] && curl https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-ikconfig > ${PROJECT_DIR}/helpers/extract-ikconfig
