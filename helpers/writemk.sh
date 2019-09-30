#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../working" >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/helpers/common_script.sh

# create lists dir if not exits
if [ ! -d "$WORK_DIR"/mklists/ ]; then
    mkdir -p "$WORK_DIR"/mklists/
fi

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ ! -e "$WORK_DIR"/mklist.txt ]; then
    echo -e "Error!"
    echo -e "Script must take 3 arguements"
    echo -e "1st is local path string"
    echo -e "2nd is destination path string"
    echo -e "3rd is comment header"
    echo -e "Also mklist.txt must exist in working/ with list of file names!"
    exit 1
fi

all_configs=`cat "$WORK_DIR"/mklist.txt | sort`
for config_line in $all_configs; do
    echo "    ""$1""$config_line""$2""$config_line"" \\" >> "$WORK_DIR"/temp.mk
done
if [ -e "$WORK_DIR"/temp.mk ]; then
    sed -i '1 i\PRODUCT_COPY_FILES += \\' "$WORK_DIR"/temp.mk
    sed -i '1 i\'"$3"'' "$WORK_DIR"/temp.mk
    printf "\n" >> "$WORK_DIR"/temp.mk
    NAME=$(echo "$3" | sed "s|# ||g" | tr ' ' '-')
    cat "$WORK_DIR"/temp.mk >> "$WORK_DIR"/mklists/"$NAME"
    rm -rf "$WORK_DIR"/temp.mk
fi
