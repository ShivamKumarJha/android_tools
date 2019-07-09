#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
source $PROJECT_DIR/tools/colors.sh

# Exit if missing token
if [ -z "$GIT_TOKEN" ]; then
	echo -e "${bold}${red}Missing GitHub token. Exiting.${nocol}"
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
	VT_REPO=$(echo vendor_$BRAND\_$DEVICE | sort -u | head -n 1 )
	VT_REPO_DESC=$(echo "Vendor-tree-for-$MODEL" | tr ' ' '-' | sort -u | head -n 1 )
	curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name":"'${VT_REPO}'","description":"'${VT_REPO_DESC}'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1

	# Extract vendor blobs
	./tools/extract_blobs/extract-files.sh "$var"
	
	# Push to GitHub
	cd "$PROJECT_DIR"/vendor/"$BRAND"/"$DEVICE"
	if [ ! -d .git ]; then
		echo -e "${bold}${cyan}Initializing git.${nocol}"
		git init . > /dev/null 2>&1
		echo -e "${bold}${cyan}Adding origin: git@github.com:ShivamKumarJha/"$VT_REPO".git ${nocol}"
		git remote add origin https://github.com/ShivamKumarJha/"$VT_REPO".git > /dev/null 2>&1
	fi
	BRANCH=$(echo $DESCRIPTION | tr ' ' '-' | sort -u | head -n 1 )
	COMMIT_MSG=$(echo "$DEVICE: $FINGERPRINT" | sort -u | head -n 1 )
	git checkout -b $BRANCH > /dev/null 2>&1
	git add --all > /dev/null 2>&1
	echo -e "${bold}${cyan}Commiting $COMMIT_MSG${nocol}"
	git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "$COMMIT_MSG" > /dev/null 2>&1
	git push https://"$GIT_TOKEN"@github.com/ShivamKumarJha/"$VT_REPO".git $BRANCH
done
