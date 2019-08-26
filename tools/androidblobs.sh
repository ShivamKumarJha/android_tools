#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/tools/common_script.sh

# Exit if missing token
if [ -z "$GIT_TOKEN" ]; then
    echo -e "${bold}${red}Missing GitHub token. Exiting.${nocol}"
    exit
fi

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "${bold}${red}Supply ROM source as arguement!${nocol}"
    exit
fi

# o/p
for var in "$@"; do
    # Check if directory
    if [ ! -d "$var" ] ; then
        echo -e "${bold}${red}Supply ROM path as arguement!${nocol}"
        break
    fi
    # Create vendor tree repo
    source $PROJECT_DIR/tools/rom_vars.sh "$var" > /dev/null 2>&1
    VT_REPO=$(echo vendor_$BRAND\_$DEVICE)
    VT_REPO_DESC=$(echo "Vendor tree for $MODEL")
    # Extract vendor blobs
    rm -rf "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"/ "$PROJECT_DIR"/working/*
    bash "$PROJECT_DIR/tools/extract_blobs/extract-files.sh" "$var"
    # Push to GitHub
    cd "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"
    [[ ! -d .git ]] && git init . > /dev/null 2>&1
    find -size +97M -printf '%P\n' -o -name *sensetime* -printf '%P\n' -o -name *.lic -printf '%P\n' > .gitignore
    BRANCH=$(echo $DESCRIPTION | tr ' ' '-' | sort -u | head -n 1 )
    COMMIT_MSG=$(echo "$DEVICE: $FINGERPRINT" | sort -u | head -n 1 )
    echo -e "${bold}${cyan}Branch $COMMIT_MSG. Adding files...${nocol}"
    git checkout -b $BRANCH > /dev/null 2>&1
    git add --all > /dev/null 2>&1
    echo -e "${bold}${cyan}Commiting $COMMIT_MSG${nocol}"
    git -c "user.name=AndroidBlobs" -c "user.email=AndroidBlobs@github.com" commit -sm "$COMMIT_MSG" > /dev/null 2>&1
    curl -s -X POST -H "Authorization: token ${GIT_TOKEN}" -d '{"name": "'"$VT_REPO"'","description": "'"$VT_REPO_DESC"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' "https://api.github.com/orgs/AndroidBlobs/repos" > /dev/null 2>&1
    git push https://"$GIT_TOKEN"@github.com/AndroidBlobs/"$VT_REPO".git $BRANCH
done
