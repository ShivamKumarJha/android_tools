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
[[ -z "$1" ]] && echo -e "Supply dir's as arguements!" && exit 1

# Exit if missing token's
[[ -z "$GIT_TOKEN" ]] && echo -e "Missing GitHub token. Exiting." && exit 1

# o/p
for var in "$@"; do
    ROM_PATH=$( realpath "$var" )
    [[ ! -d "$ROM_PATH" ]] && echo -e "$ROM_PATH is not a valid directory!" && exit 1
    cd "$ROM_PATH"
    [[ ! -d "system/" ]] && echo -e "No system partition found, pushing cancelled!" && exit 1
    # Set variables
    source $PROJECT_DIR/helpers/rom_vars.sh "$ROM_PATH" > /dev/null 2>&1
    if [ -z "$BRAND" ] || [ -z "$DEVICE" ]; then
        echo -e "Could not set variables! Exiting"
        exit 1
    fi
    repo=$(echo $BRAND\_$DEVICE\_dump | tr '[:upper:]' '[:lower:]')
    repo_desc=$(echo "$MODEL dump")
    ORG="$GITHUB_USER"
    curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$repo"'","description": "'"$repo_desc"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
    [[ -z "$ORG" ]] && echo -e "Missing GitHub user name. Exiting." && exit 1
    wget "https://raw.githubusercontent.com/$ORG/$repo/$BRANCH/all_files.txt" 2>/dev/null && echo "Firmware already dumped!" && exit 1

    git init > /dev/null 2>&1
    git checkout -b $BRANCH > /dev/null 2>&1
    find -size +97M -printf '%P\n' -o -name *sensetime* -printf '%P\n' -o -name *.lic -printf '%P\n' > .gitignore
    git remote add origin https://github.com/$ORG/${repo,,}.git > /dev/null 2>&1
    echo -e "Dumping extras"
    git add --all > /dev/null 2>&1
    git reset system/ vendor/ > /dev/null 2>&1
    git -c "user.name=${ORG}" -c "user.email=${GITHUB_EMAIL}" commit -asm "Add extras for ${DESCRIPTION}" > /dev/null 2>&1
    git push https://$GIT_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH > /dev/null 2>&1
    [[ -d vendor/ ]] && echo -e "Dumping vendor"
    [[ -d vendor/ ]] && git add vendor/ > /dev/null 2>&1
    [[ -d vendor/ ]] && git -c "user.name=${ORG}" -c "user.email=${GITHUB_EMAIL}" commit -asm "Add vendor for ${DESCRIPTION}" > /dev/null 2>&1
    [[ -d vendor/ ]] && git push https://$GIT_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH > /dev/null 2>&1
    echo -e "Dumping apps"
    git add system/system/app/ system/system/priv-app/ > /dev/null 2>&1 || git add system/app/ system/priv-app/ > /dev/null 2>&1
    git -c "user.name=${ORG}" -c "user.email=${GITHUB_EMAIL}" commit -asm "Add apps for ${DESCRIPTION}" > /dev/null 2>&1
    git push https://$GIT_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH > /dev/null 2>&1
    echo -e "Dumping system"
    git add system/ > /dev/null 2>&1
    git -c "user.name=${ORG}" -c "user.email=${GITHUB_EMAIL}" commit -asm "Add system for ${DESCRIPTION}" > /dev/null 2>&1
    git push https://$GIT_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH > /dev/null 2>&1
done
