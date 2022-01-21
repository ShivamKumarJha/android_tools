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

# Exit if invalid arguements
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "Supply source & target ROM path's as arguements!"
    exit 1
fi

# Create temp dir's
mkdir -p $TMPDIR/dt_common/

# List props
bash $PROJECT_DIR/tools/vendor_prop.sh "$1" > /dev/null 2>&1
cat $PROJECT_DIR/working/*.mk > $TMPDIR/dt_common/prop_source

bash $PROJECT_DIR/tools/vendor_prop.sh "$2" > /dev/null 2>&1
cat $PROJECT_DIR/working/*.mk > $TMPDIR/dt_common/prop_target
rm -rf $PROJECT_DIR/working/*

# Find common & uncommon props
comm -12 <(sort $TMPDIR/dt_common/prop_source) <(sort $TMPDIR/dt_common/prop_target) > $PROJECT_DIR/working/common-vendor_prop.mk
comm -23 <(sort $TMPDIR/dt_common/prop_source) <(sort $TMPDIR/dt_common/prop_target) > $PROJECT_DIR/working/source-vendor_prop.mk
comm -13 <(sort $TMPDIR/dt_common/prop_source) <(sort $TMPDIR/dt_common/prop_target) > $PROJECT_DIR/working/target-vendor_prop.mk

# Makefile formatting
sed -i "s|PRODUCT_PROPERTY_OVERRIDES.*||g" $PROJECT_DIR/working/common-vendor_prop.mk $PROJECT_DIR/working/source-vendor_prop.mk $PROJECT_DIR/working/target-vendor_prop.mk
sed -i '1 i\PRODUCT_PROPERTY_OVERRIDES += \\' $PROJECT_DIR/working/common-vendor_prop.mk $PROJECT_DIR/working/source-vendor_prop.mk $PROJECT_DIR/working/target-vendor_prop.mk
sed -i '/^$/d' $PROJECT_DIR/working/common-vendor_prop.mk $PROJECT_DIR/working/source-vendor_prop.mk $PROJECT_DIR/working/target-vendor_prop.mk
sed -i "s|#.*||g" $PROJECT_DIR/working/common-vendor_prop.mk $PROJECT_DIR/working/source-vendor_prop.mk $PROJECT_DIR/working/target-vendor_prop.mk
sed -i '/^$/d' $PROJECT_DIR/working/common-vendor_prop.mk $PROJECT_DIR/working/source-vendor_prop.mk $PROJECT_DIR/working/target-vendor_prop.mk

# Final results
rm -rf $TMPDIR/dt_common/
echo -e "Files prepared. Check $PROJECT_DIR/working/"
