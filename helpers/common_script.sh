#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Create some folders
mkdir -p "$PROJECT_DIR/dumps/" "$PROJECT_DIR/working" "$PROJECT_DIR/input"

# clean up
if [ "$1" == "y" ]; then
    rm -rf $PROJECT_DIR/working/*
fi

# set common var's
GITHUB_EMAIL="$(git config --get user.email)"
GITHUB_USER="$(git config --get user.name)"
[[ -z "$DUMMYDT" ]] && DUMMYDT="n"
[[ -z "$DUMPPUSH" ]] && DUMPPUSH="n"
[[ -z "$ORGMEMBER" ]] && ORGMEMBER="n"
[[ -z "$VERBOSE" ]] && VERBOSE="y"
[[ -z "$TMPDIR" ]] && TMPDIR="/tmp"
export LC_ALL=C make

# Dependencies check
if [ ! -d "$PROJECT_DIR/tools/Firmware_extractor" ] || [ ! -d "$PROJECT_DIR/tools/android_boot_image_editor" ] || [ ! -d "$PROJECT_DIR/tools/extract-dtb" ]; then
    [[ "$VERBOSE" != "n" ]] && echo -e "Cloning dependencies..."
    bash $PROJECT_DIR/helpers/dependencies.sh > /dev/null 2>&1
fi

function dlrom() {
    echo "Downloading file"
    mkdir -p ${PROJECT_DIR}/input
    cd ${PROJECT_DIR}/input
    if [[ "$URL" == *"https://drive.google.com/"* ]] && [[ ! -z "$(which gdrive)" ]]; then
        rm -rf ${PROJECT_DIR}/input/*
        FILE_ID="$(echo "${URL:?}" | sed -Er -e 's/https.*id=(.*)/\1/' -e 's/https.*\/d\/(.*)\/(view|edit)/\1/' -e 's/(.*)(&|\?).*/\1/')"
        gdrive download "$FILE_ID" --no-progress || { echo "Download failed!"; }
        find ${PROJECT_DIR}/input -name "* *" -type f
        URL=$( ls -d $PWD/* )
    elif [[ "$URL" == *"https://mega.nz/"* ]] && [[ -e "/usr/bin/megadl" ]]; then
        rm -rf ${PROJECT_DIR}/input/*
        megadl "${URL}" --no-progress || { echo "Download failed!"; }
        find ${PROJECT_DIR}/input -name "* *" -type f
        URL=$( ls -d $PWD/* )
    else
        if [[ $(echo $URL | grep ".zip?") ]]; then
            FILE="$(echo $URL | grep '.zip?' | cut -d? -f1)"
            FILE="$(echo ${FILE##*/} | sed "s| |_|g" )"
        elif [[ $(echo $URL | grep ".exe?") ]]; then
            FILE="$(echo $URL | grep '.exe?' | cut -d? -f1)"
            FILE="$(echo ${FILE##*/} | sed "s| |_|g" )"
        else
            FILE="$(echo ${URL##*/} | sed "s| |_|g" )"
        fi
        rm -rf $PROJECT_DIR/input/${FILE}
        aria2c -q -s 16 -x 16 ${URL} -d ${PROJECT_DIR}/input -o ${FILE} || { echo "Download failed!"; }
        find ${PROJECT_DIR}/input -name "* *" -type f
        URL=$PROJECT_DIR/input/${FILE}
        [[ -e ${URL} ]] && du -sh ${URL}
    fi
}
