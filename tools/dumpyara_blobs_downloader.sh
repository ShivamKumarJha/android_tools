#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Exit if invalid arguements
if [ -z "$1" ] || [ -z "$2" ] || [ ! -e "$2" ]; then
    echo -e "${bold}${red}Supply Git raw URL & blobs list file as arguements!"
    exit 1
fi

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"
WORK_DIR="$PROJECT_DIR/working"
mkdir -p "$WORK_DIR" && cd "$WORK_DIR"
rm -rf "$WORK_DIR"/*
cp -a "$2" "$WORK_DIR/list.txt"

# remove blob pin, comments & empty lines from blobs list
sed -i "s/^#.*//g" "$WORK_DIR/list.txt"
sed -i "s/|.*//g" "$WORK_DIR/list.txt"
sed -i '/^$/d' "$WORK_DIR/list.txt"

# download blobs in list
file_list=`cat "$WORK_DIR/list.txt" | sort -u`
for file in $file_list; do
    if [[ "$(echo $file | cut -c 1)" == "-" ]]; then
        FULL_NAME=$(echo $file | sed "s|-||1" )
    else
        FULL_NAME=$(echo $file)
    fi
    FILE_NAME=$(echo $file | rev | cut -d / -f1 | rev )
    DIRS_NAME=$(echo $FULL_NAME | sed "s|$FILE_NAME||g" )
    [[ "$DIRS_NAME" != "" ]] && mkdir -p "$WORK_DIR/$DIRS_NAME" && cd "$WORK_DIR/$DIRS_NAME"
    [[ "$DIRS_NAME" == "" ]] && cd "$WORK_DIR"
    echo "PATH: $WORK_DIR/$FULL_NAME"
    aria2c -x16 "$1/$FULL_NAME" > /dev/null || aria2c -x16 "$1/system/$FULL_NAME" > /dev/null || aria2c -x16 "$1/system/system/$FULL_NAME" > /dev/null
done

printf "\nFinished. Check $WORK_DIR\n"
