#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/helpers/common_script.sh

# Exit if missing token
if [ -z "$GIT_TOKEN" ]; then
    echo -e "Missing GitHub token. Exiting."
    exit 1
fi

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply ROM source as arguement!"
    exit 1
fi

blobs_extract_push () {
    VT_REPO=$(echo vendor_$BRAND\_$DEVICE)
    VT_REPO_DESC=$(echo "Vendor tree for $MODEL")
    # Extract vendor blobs
    rm -rf "$PROJECT_DIR"/working/*
    mkdir -p "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"/
    bash "$PROJECT_DIR/helpers/extract_blobs/extract-files.sh" "$ROM_PATH"
    # Push to GitHub
    cd "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"
    git init . > /dev/null 2>&1
    find -size +97M -printf '%P\n' -o -name *sensetime* -printf '%P\n' -o -name *.lic -printf '%P\n' > .gitignore
    BRANCH=$(echo $DESCRIPTION | tr ' ' '-' )
    COMMIT_MSG=$(echo "$DEVICE: $FINGERPRINT" )
    echo -e "Branch $COMMIT_MSG. Adding files..."
    git checkout -b $BRANCH > /dev/null 2>&1
    git add --all > /dev/null 2>&1
    echo -e "Commiting $COMMIT_MSG"
    git -c "user.name=AndroidBlobs" -c "user.email=AndroidBlobs@github.com" commit -sm "$COMMIT_MSG" > /dev/null 2>&1
    curl -s -X POST -H "Authorization: token ${GIT_TOKEN}" -d '{"name": "'"$VT_REPO"'","description": "'"$VT_REPO_DESC"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' "https://api.github.com/orgs/AndroidBlobs/repos" > /dev/null 2>&1
    git push https://"$GIT_TOKEN"@github.com/AndroidBlobs/"$VT_REPO".git --all
}

# o/p
for var in "$@"; do
    unset VT_REPO VT_REPO_DESC BRANCH COMMIT_MSG
    ROM_PATH=$( realpath "$var" )
    # Check if directory
    if [ ! -d "$ROM_PATH" ]; then
        echo -e "Supply ROM path as arguement!"
        break
    fi
    # Create vendor tree repo
    source $PROJECT_DIR/helpers/rom_vars.sh "$ROM_PATH" > /dev/null 2>&1
    if [ -z "$BRAND" ] || [ -z "$DEVICE" ]; then
        echo -e "Error! Empty variable."
        break
    else
        blobs_extract_push
    fi
    cd "$PROJECT_DIR"
done
