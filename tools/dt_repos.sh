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
	echo -e "${bold}${red}Supply dir's or raw build.prop link as arguements!${nocol}"
	exit
fi

# Exit if missing token
if [ -z "$GIT_TOKEN" ]; then
	echo -e "${bold}${cyan}Missing GitHub token. Exiting.${nocol}"
	exit
fi

# o/p
for var in "$@"; do
	source $PROJECT_DIR/tools/rom_vars.sh "$var" > /dev/null 2>&1
	DT_REPO=$(echo device_$BRAND\_$DEVICE | sort -u | head -n 1 )
	KT_REPO=$(echo kernel_$BRAND\_$DEVICE | sort -u | head -n 1 )
	VT_REPO=$(echo vendor_$BRAND\_$DEVICE | sort -u | head -n 1 )
	DT_REPO_DESC=$(echo "Device-tree-for-$MODEL" | tr ' ' '-' | sort -u | head -n 1 )
	KT_REPO_DESC=$(echo "Kernel-tree-for-$MODEL" | tr ' ' '-' | sort -u | head -n 1 )
	VT_REPO_DESC=$(echo "Vendor-tree-for-$MODEL" | tr ' ' '-' | sort -u | head -n 1 )
	# Create repository in GitHub
	printf "${bold}${cyan}Creating\nhttps://github.com/ShivamKumarJha/$DT_REPO\nhttps://github.com/ShivamKumarJha/$KT_REPO\nhttps://github.com/ShivamKumarJha/$VT_REPO\n${nocol}"
	curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name":"'${DT_REPO}'","description":"'${DT_REPO_DESC}'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
	curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name":"'${KT_REPO}'","description":"'${KT_REPO_DESC}'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
	curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name":"'${VT_REPO}'","description":"'${VT_REPO_DESC}'","private": true,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
done
