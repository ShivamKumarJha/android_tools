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

# Required!
DEVICE="$DEVICE"
VENDOR="$BRAND"

INITIAL_COPYRIGHT_YEAR=$( date +"%Y" )

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

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT"

# Copyright headers and guards
write_headers

write_makefiles $PROJECT_DIR/working/proprietary-files.txt true

# Finish
write_footers
