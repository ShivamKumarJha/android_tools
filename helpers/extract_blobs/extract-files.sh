#!/bin/bash
#
# Copyright (C) 2018 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null && pwd )"

# Prepare blobs list
if [ ! -e $PROJECT_DIR/working/proprietary-files.txt ]; then
    echo "Preparing proprietary-files.txt"
    bash $PROJECT_DIR/tools/proprietary-files.sh "$1" > /dev/null 2>&1
fi

# Set values
source $PROJECT_DIR/helpers/rom_vars.sh "$1"
DEVICE="$DEVICE"
VENDOR="$BRAND"

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$PROJECT_DIR"

if [[ "$VERSION" -lt 10 ]]; then
    HELPER="$LINEAGE_ROOT"/helpers/extract_blobs/extract_utils_pie.sh
else
    HELPER="$LINEAGE_ROOT"/helpers/extract_blobs/extract_utils.sh
fi

if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" false "$CLEAN_VENDOR"

extract $PROJECT_DIR/working/proprietary-files.txt "$SRC" "$SECTION"

. "$MY_DIR"/setup-makefiles.sh
