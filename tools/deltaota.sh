#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source "$PROJECT_DIR"/helpers/common_script.sh "y"

if [ ! -f "$1" ] || [ ! -f "$2" ]; then
    echo -e "Supply full OTA file and patch OTA file as arguements!"
    exit 1
fi

# Set these var's acc to last arg
URL=$( realpath "${@: -1}" )
FILE=${URL##*/}
EXTENSION=${URL##*.}
UNZIP_DIR=${FILE/.$EXTENSION/}

if [[ "$VERBOSE" = "n" ]]; then
    echo "Extracting images of full OTA"
    bash "$PROJECT_DIR"/tools/Firmware_extractor/patcher.sh "$@" -o "$PROJECT_DIR"/working/"$UNZIP_DIR" > /dev/null 2>&1
else
    bash "$PROJECT_DIR"/tools/Firmware_extractor/patcher.sh "$@" -o "$PROJECT_DIR"/working/"$UNZIP_DIR" -v
fi

bash "$PROJECT_DIR"/tools/rom_extract.sh "$PROJECT_DIR"/working/"$UNZIP_DIR"
rm -rf "$PROJECT_DIR"/working/"$UNZIP_DIR"
