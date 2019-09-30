#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/helpers/common_script.sh

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply FWB config.xml as arguement!"
    exit 1
fi

# Get files via either cp or wget
if echo "$1" | grep "https" ; then
    wget -O $PROJECT_DIR/working/config.xml $1
else
    cp -a $1 $PROJECT_DIR/working/config.xml
fi

# update overlay lists
cat $PROJECT_DIR/working/config.xml | grep "<bool name=" | sed "s|<bool||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" >> $PROJECT_DIR/helpers/lists/overlays/bools
cat $PROJECT_DIR/working/config.xml | grep "<dimen name=" | sed "s|<dimen||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" >> $PROJECT_DIR/helpers/lists/overlays/dimens
cat $PROJECT_DIR/working/config.xml | grep "<fraction name=" | sed "s|<fraction||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" >> $PROJECT_DIR/helpers/lists/overlays/fractions
cat $PROJECT_DIR/working/config.xml | grep "<integer name=" | sed "s|<integer||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" >> $PROJECT_DIR/helpers/lists/overlays/integers
cat $PROJECT_DIR/working/config.xml | grep "<string name=" | sed "s|<string||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" | sed "s|\"translatable.*||g" >> $PROJECT_DIR/helpers/lists/overlays/strings
cat $PROJECT_DIR/working/config.xml | grep "<integer-array name=" | sed "s|<integer-array||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" >> $PROJECT_DIR/helpers/lists/overlays/arrays/integer-array
cat $PROJECT_DIR/working/config.xml | grep "<string-array name=" | sed "s|<string-array||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" >> $PROJECT_DIR/helpers/lists/overlays/arrays/string-array
cat $PROJECT_DIR/working/config.xml | grep "<string-array " | sed "s|<string-array||g" | sed "s|\">.*||g" | sed "s|name=\"||g" | sed "s|\s||g" | sed "s|translatable=\"false\"||g" >> $PROJECT_DIR/helpers/lists/overlays/arrays/string-array

# sort lists
bash $PROJECT_DIR/helpers/lists_sort_all.sh
