#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/helpers/common_script.sh "y"

# Make sure to get paths
if [ -z "$1" ] || [ -z "$2" ] ; then
    echo -e "Supply source & target ROM paths!"
    exit 1
fi

# Check if paths are correct
if [ ! -d "$1" ] || [ ! -d "$2" ] ; then
    echo -e "Error! Path is not a directory!"
    exit 1
fi

# List source ROM files
find $1 -type f -printf '%P\n' | sort > $PROJECT_DIR/working/1.txt

# List target ROM files
find $2 -type f -printf '%P\n' | sort > $PROJECT_DIR/working/2.txt

file_lines=`cat $PROJECT_DIR/working/1.txt`
for line in $file_lines ; do
    # Missing
    if ! grep -q "$line" $PROJECT_DIR/working/2.txt; then
        echo "$line" >> $PROJECT_DIR/working/Missing.txt
    else
        # Common
        echo -e "Comparing $line"
        cmp --silent $1/$line $2/$line && echo "$line" >> $PROJECT_DIR/working/Common.txt
        # Modified
        cmp --silent $1/$line $2/$line || echo "$line" >> $PROJECT_DIR/working/Modified.txt
    fi
done
file_lines=`cat $PROJECT_DIR/working/2.txt`
for line in $file_lines ; do
    # Added
    if ! grep -q "$line" $PROJECT_DIR/working/1.txt; then
        echo "$line" >> $PROJECT_DIR/working/Added.txt
    fi
done

for i in "Added" "Common" "Missing" "Modified"; do
    if [ -e $PROJECT_DIR/working/$i.txt ]; then
        echo -e "$i files stored: $(ls -d $PROJECT_DIR/working/$i.txt)"
    fi
done
