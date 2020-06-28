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
[[ -z "$DUMPYARA" ]] && DUMPYARA="n"
[[ -z "$ORGMEMBER" ]] && ORGMEMBER="n"
[[ -z "$VERBOSE" ]] && VERBOSE="y"
export LC_ALL=C make

# extract-ikconfig
[[ ! -e ${PROJECT_DIR}/helpers/extract-ikconfig ]] && curl https://raw.githubusercontent.com/torvalds/linux/master/scripts/extract-ikconfig > ${PROJECT_DIR}/helpers/extract-ikconfig

function dlrom() {
    echo "Downloading file"
    mkdir -p ${PROJECT_DIR}/input
    cd ${PROJECT_DIR}/input
    if [[ "$URL" == *"https://drive.google.com/"* ]] && [[ ! -z "$(which gdrive)" ]]; then
        rm -rf ${PROJECT_DIR}/input/*
        FILE_ID="$(echo "${URL:?}" | sed -Er -e 's/https.*id=(.*)/\1/' -e 's/https.*\/d\/(.*)\/(view|edit)/\1/' -e 's/(.*)(&|\?).*/\1/')"
        gdrive download "$FILE_ID" --no-progress || { echo "Download failed!"; }
        find ${PROJECT_DIR}/input -name "* *" -type f | rename 's/ /_/g'
        URL=$( ls -d $PWD/* )
    elif [[ "$URL" == *"https://mega.nz/"* ]] && [[ -e "/usr/bin/megadl" ]]; then
        rm -rf ${PROJECT_DIR}/input/*
        megadl "${URL}" --no-progress || { echo "Download failed!"; }
        find ${PROJECT_DIR}/input -name "* *" -type f | rename 's/ /_/g'
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
        find ${PROJECT_DIR}/input -name "* *" -type f | rename 's/ /_/g'
        URL=$PROJECT_DIR/input/${FILE}
        [[ -e ${URL} ]] && du -sh ${URL}
    fi
}
