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

# Exit if missing token, user or email
if [ -z "$GIT_TOKEN" ] && [ -z "$GITHUB_EMAIL" ] && [ -z "$GITHUB_USER" ]; then
    echo -e "Missing GitHub token or user or email. Exiting."
    exit 1
fi

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply ROM source as arguement!"
    exit 1
fi

# o/p
for var in "$@"; do
    # Check if directory
    if [ ! -d "$var" ] ; then
        echo -e "Supply ROM path as arguement!"
        break
    fi

    # Create vendor tree repo
    source $PROJECT_DIR/helpers/rom_vars.sh "$var" > /dev/null 2>&1
    VT_REPO=$(echo vendor_$BRAND\_$DEVICE)
    VT_REPO_DESC=$(echo "Vendor tree for $MODEL")
    curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$VT_REPO"'","description": "'"$VT_REPO_DESC"'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1

    # Extract vendor blobs
    bash "$PROJECT_DIR/helpers/extract_blobs/extract-files.sh" "$var"

    # Push to GitHub
    cd "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"
    if [ ! -d .git ]; then
        echo -e "Initializing git."
        git init . > /dev/null 2>&1
        echo -e "Adding origin: git@github.com:$GITHUB_USER/"$VT_REPO".git "
        git remote add origin git@github.com:$GITHUB_USER/"$VT_REPO".git > /dev/null 2>&1
    fi
    COMMIT_MSG=$(echo "$DEVICE: $FINGERPRINT" | sort -u | head -n 1 )
    git checkout -b $BRANCH > /dev/null 2>&1
    git add --all > /dev/null 2>&1
    echo -e "Commiting $COMMIT_MSG"
    git -c "user.name=$GITHUB_USER" -c "user.email=$GITHUB_EMAIL" commit -sm "$COMMIT_MSG" -q
    git push https://"$GIT_TOKEN"@github.com/$GITHUB_USER/"$VT_REPO".git $BRANCH > /dev/null 2>&1
done
