#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source "$PROJECT_DIR"/helpers/common_script.sh

if [ ! -f "$1" ] || [ ! -f "$2" ]; then
    echo -e "Supply full OTA file and patch OTA file as arguements!"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/tools/Firmware_extractor" ] || [ ! -d "$PROJECT_DIR/tools/extract-dtb" ] || [ ! -d "$PROJECT_DIR/tools/mkbootimg_tools" ] || [ ! -d "$PROJECT_DIR/tools/update_payload_extractor" ]; then
    [[ "$VERBOSE" != "n" ]] && echo -e "Cloning dependencies..."
    bash $PROJECT_DIR/helpers/dependencies.sh > /dev/null 2>&1
fi

URL_A=$( realpath "$1" )
FILE_A=${URL_A##*/}
EXTENSION_A=${URL_A##*.}
UNZIP_DIR_A=${FILE_A/.$EXTENSION_A/}

URL_B=$( realpath "$2" )
FILE_B=${URL_B##*/}
EXTENSION_B=${URL_B##*.}
UNZIP_DIR_B=${FILE_B/.$EXTENSION_B/}

[[ -d "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A" ]] && rm -rf "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"

if [[ "$VERBOSE" = "n" ]]; then
    echo "Extracting images of full OTA"
    bash "$PROJECT_DIR"/tools/Firmware_extractor/extractor.sh "$URL_A" "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A" > /dev/null 2>&1
else
    bash "$PROJECT_DIR"/tools/Firmware_extractor/extractor.sh "$URL_A" "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"
fi

echo "Extracting patch OTA payload.bin"
cd "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"
7z e -y "$URL_B" "payload.bin" > /dev/null 2>&1

if [[ "$VERBOSE" = "n" ]]; then
    echo "Merging patch OTA"
    python "$PROJECT_DIR"/tools/update_payload_extractor/extract.py --source_dir "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A" "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/payload.bin > /dev/null 2>&1
else
    python "$PROJECT_DIR"/tools/update_payload_extractor/extract.py --source_dir "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A" "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/payload.bin
fi

[[ -d "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/output ]] && cd "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/output
find "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/output -type f -not -name "*.*" -exec mv "{}" "{}".img \;

mv "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/output "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/"$UNZIP_DIR_B"
bash "$PROJECT_DIR"/tools/rom_extract.sh "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/"$UNZIP_DIR_B"
rm -rf "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/"$UNZIP_DIR_B" "$PROJECT_DIR"/dumps/"$UNZIP_DIR_A"/payload.bin
