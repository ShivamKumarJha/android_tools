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

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply xml's as arguements!"
    exit 1
fi

# o/p
for var in "$@"; do
    while IFS= read -r line
    do
        if echo "$line" | grep "<project"; then
            if ! echo "$line" | grep "clone-depth"; then
                if echo "$line" | grep -iE "potato|mokee|aosip|LineageOS|remote=\"aex|gzosp|crdroid"; then
                    echo "$line" >> "$PROJECT_DIR"/working/new_manifest.xml
                else
                    echo "$line" | sed "s|<project|<project clone-depth=\"1\"|g" >> "$PROJECT_DIR"/working/new_manifest.xml
                fi
            else
                echo "$line" >> "$PROJECT_DIR"/working/new_manifest.xml
            fi
        else
            echo "$line" >> "$PROJECT_DIR"/working/new_manifest.xml
        fi
    done < "$var"
    cat "$PROJECT_DIR"/working/new_manifest.xml > "$var"
    rm -rf "$PROJECT_DIR"/working/new_manifest.xml
done
