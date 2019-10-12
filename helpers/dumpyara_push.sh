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
    echo -e "Supply dir's as arguements!"
    exit 1
fi

# Exit if missing token's
if [ -z "$DUMPYARA_TOKEN" ]; then
    echo -e "Missing GitHub token. Exiting."
    exit 1
fi

# o/p
for var in "$@"; do
    ROM_PATH=$( realpath "$var" )
    if [ ! -d "$ROM_PATH" ] ; then
        echo -e "$ROM_PATH is not a valid directory!"
        exit 1
    fi
    cd "$ROM_PATH"
    GIT_OAUTH_TOKEN="$DUMPYARA_TOKEN"
    ORG=AndroidDumps
    cd $ROM_PATH/
    ls system/build*.prop 2>/dev/null || ls system/system/build*.prop 2>/dev/null || { echo "No system build*.prop found, pushing cancelled!" && exit 1 ;}
    # Set variables
    source $PROJECT_DIR/helpers/rom_vars.sh "$ROM_PATH" > /dev/null 2>&1
    BRANCH=$(echo $DESCRIPTION | tr ' ' '-')
    repo=$(echo $BRAND\_$DEVICE\_dump | tr '[:upper:]' '[:lower:]')
    repo_desc=$(echo "$MODEL dump")

    git init
    git checkout -b $BRANCH
    find -size +97M -printf '%P\n' -o -name *sensetime* -printf '%P\n' -o -name *.lic -printf '%P\n' > .gitignore
    git add --all
    git remote add origin https://github.com/$ORG/${repo,,}.git
    git -c "user.name=AndroidDumps" -c "user.email=AndroidDumps@github.com" commit -asm "Add ${DESCRIPTION}"
    curl -s -X POST -H "Authorization: token ${GIT_OAUTH_TOKEN}" -d '{"name": "'"$repo"'","description": "'"$repo_desc"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' "https://api.github.com/orgs/${ORG}/repos" #create new repo
    git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH ||
    (git update-ref -d HEAD ; git reset system/ vendor/ ;
    git checkout -b $BRANCH ;
    git -c "user.name=AndroidDumps" -c "user.email=AndroidDumps@github.com" commit -asm "Add extras for ${DESCRIPTION}" ;
    git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH ;
    git add vendor/ ;
    git -c "user.name=AndroidDumps" -c "user.email=AndroidDumps@github.com" commit -asm "Add vendor for ${DESCRIPTION}" ;
    git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH ;
    git add system/system/app/ system/system/priv-app/ || git add system/app/ system/priv-app/ ;
    git -c "user.name=AndroidDumps" -c "user.email=AndroidDumps@github.com" commit -asm "Add apps for ${DESCRIPTION}" ;
    git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH ;
    git add system/ ;
    git -c "user.name=AndroidDumps" -c "user.email=AndroidDumps@github.com" commit -asm "Add system for ${DESCRIPTION}" ;
    git push https://$GIT_OAUTH_TOKEN@github.com/$ORG/${repo,,}.git $BRANCH ;)

    # Telegram channel
    if [ ! -z "$TG_API" ]; then
        CHAT_ID="@android_dumps"
        commit_head=$(git log --format=format:%H | head -n 1)
        commit_link=$(echo "https://github.com/$ORG/$repo/commit/$commit_head")
        echo -e "Sending telegram notification"
        printf "<b>Brand: $BRAND</b>" > $PROJECT_DIR/working/tg.html
        printf "\n<b>Device: $DEVICE</b>" >> $PROJECT_DIR/working/tg.html
        printf "\n<b>Version:</b> $VERSION" >> $PROJECT_DIR/working/tg.html
        printf "\n<b>Fingerprint:</b> $FINGERPRINT" >> $PROJECT_DIR/working/tg.html
        printf "\n<b>GitHub:</b>" >> $PROJECT_DIR/working/tg.html
        printf "\n<a href=\"$commit_link\">Commit</a>" >> $PROJECT_DIR/working/tg.html
        printf "\n<a href=\"https://github.com/$ORG/$repo/tree/$BRANCH/\">$DEVICE</a>" >> $PROJECT_DIR/working/tg.html
        TEXT=$(cat $PROJECT_DIR/working/tg.html)
        curl -s "https://api.telegram.org/bot${TG_API}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" > /dev/null
        rm -rf $PROJECT_DIR/working/tg.html
    fi
    cd "$PROJECT_DIR"
done
