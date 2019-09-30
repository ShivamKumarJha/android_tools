#!/usr/bin/env bash

[[ -z "$1" ]] && echo "Give URL as arguement!" && exit 1
android_tools="/home/$USER/android_tools"
if [[ -d "$android_tools" ]]; then
    git -C "$android_tools" fetch origin master
    git -C "$android_tools" reset --hard origin/master
else
    echo "Cloning repo"
    git clone -q git@github.com:ShivamKumarJha/android_tools.git "$android_tools"
fi

for var in "$@"; do
    mkdir -p "$android_tools/input"
    cd "$android_tools/input"
    rm -rf $android_tools/input/*
    echo "Downloading ROM"
    if echo ${var} | grep "https://drive.google.com/" && [[ -e "/usr/local/bin/gdrive" ]]; then
        gdrive download "$(echo ${var} | sed "s|https://drive.google.com/||g" | sed "s|/view.*||g" | sed "s|.*id=||g" | sed "s|.*file/d/||g" | sed "s|&export=.*||g" )" || exit 1
    else
        aria2c -q -s 16 -x 16 ${var} || wget ${var} || exit 1
    fi
    URL=$( ls "$android_tools/input/" )
    FILE=${URL##*/}
    EXTENSION=${URL##*.}
    UNZIP_DIR=${FILE/.$EXTENSION/}
    echo "Extracting ROM"
    bash "$android_tools/tools/rom_extract.sh" "$android_tools/input/$FILE*"
    echo "Pushing to AndroidDumps GitHub"
    bash "$android_tools/helpers/dumpyara_push.sh" "$android_tools/dumps/$UNZIP_DIR" > /dev/null 2>&1
    echo "Done"
done
