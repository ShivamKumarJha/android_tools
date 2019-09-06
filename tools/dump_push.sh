#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source $PROJECT_DIR/tools/common_script.sh

# Exit if no arguements
if [ -z "$1" ] ; then
    echo -e "Supply dir's as arguements!"
    exit 1
fi

# Exit if missing token, user or email
if [ -z "$GIT_TOKEN" ] && [ -z "$GITHUB_EMAIL" ] && [ -z "$GITHUB_USER" ]; then
    echo -e "Missing GitHub token or user or email. Exiting."
    exit 1
fi

# o/p
for var in "$@"; do
    ROM_PATH=$( realpath "$var" )
    cd "$ROM_PATH"
    # Set variables
    source $PROJECT_DIR/tools/rom_vars.sh "$ROM_PATH" > /dev/null 2>&1
    COMMIT_MSG=$(echo "$DEVICE: $FINGERPRINT" | sort -u | head -n 1 )
    REPO=$(echo dump_$BRAND\_$DEVICE | sort -u | head -n 1 )
    REPO_DESC=$(echo "$MODEL-dump" | tr ' ' '-' | sort -u | head -n 1 )
    BRANCH=$(echo $DESCRIPTION | tr ' ' '-' | sort -u | head -n 1 )
    # Create repository in GitHub
    echo -e "Creating https://github.com/$GITHUB_USER/$REPO"
    curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name":"'${REPO}'","description":"'${REPO_DESC}'","private": true,"has_issues": false,"has_projects": false,"has_wiki": false}' > /dev/null 2>&1
    # Add files & push
    if [ ! -d .git ]; then
        echo -e "Initializing git."
        git init . > /dev/null 2>&1
        git remote add origin git@github.com:$GITHUB_USER/"$REPO".git > /dev/null 2>&1
    fi
    if [[ ! -z $(git status -s) ]]; then
        echo -e "Creating branch $BRANCH"
        git checkout -b $BRANCH > /dev/null 2>&1
        find -size +97M -printf '%P\n' > .gitignore
        echo -e "Ignoring following files:\n$(cat .gitignore)"
        echo -e "Adding files ..."
        git add --all > /dev/null 2>&1
        echo -e "Commiting $COMMIT_MSG"
        git -c "user.name=$GITHUB_USER" -c "user.email=$GITHUB_EMAIL" commit -sm "$COMMIT_MSG" > /dev/null 2>&1
        git push https://"$GIT_TOKEN"@github.com/$GITHUB_USER/"$REPO".git $BRANCH
    fi
    cd "$PROJECT_DIR"
done
