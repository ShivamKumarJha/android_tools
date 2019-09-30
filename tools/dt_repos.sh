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

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply dir's or raw build.prop link as arguements!"
    exit 1
fi

# Exit if missing token, user or email
if [ -z "$GIT_TOKEN" ] && [ -z "$GITHUB_USER" ]; then
    echo -e "Missing GitHub token or user or email. Exiting."
    exit 1
fi

# o/p
for var in "$@"; do
    source $PROJECT_DIR/helpers/rom_vars.sh "$var" > /dev/null 2>&1
    DT_REPO=$(echo device_$BRAND\_$DEVICE)
    KT_REPO=$(echo kernel_$BRAND\_$DEVICE)
    VT_REPO=$(echo vendor_$BRAND\_$DEVICE)
    DT_REPO_DESC=$(echo "Device tree for $MODEL")
    KT_REPO_DESC=$(echo "Kernel tree for $MODEL")
    VT_REPO_DESC=$(echo "Vendor tree for $MODEL")
    # Create repository in GitHub
    printf "Creating\nhttps://github.com/$GITHUB_USER/$DT_REPO\nhttps://github.com/$GITHUB_USER/$KT_REPO\nhttps://github.com/$GITHUB_USER/$VT_REPO\n"
    curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$DT_REPO"'","description": "'"$DT_REPO_DESC"'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
    curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$KT_REPO"'","description": "'"$KT_REPO_DESC"'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
    curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$VT_REPO"'","description": "'"$VT_REPO_DESC"'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
done
