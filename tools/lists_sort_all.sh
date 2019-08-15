#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store lists path
LISTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/lists/" >/dev/null && pwd )"

tools_lists=`find $LISTS_DIR/ -type f -printf '%P\n' | sort | grep -v "overlays/comments/"`
for list in $tools_lists; do
    sort -u -o "$LISTS_DIR/$list" "$LISTS_DIR/$list"
done
