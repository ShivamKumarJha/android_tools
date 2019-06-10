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

# Create "$PROJECT_DIR"/working directory if it does not exist
if [ ! -d "$PROJECT_DIR"/working ]; then
	mkdir -p "$PROJECT_DIR"/working
fi

# clean up
rm -rf "$PROJECT_DIR"/working/*

# Exit if no arguements
if [ -z "$1" ] ; then
	echo -e "${bold}${red}Supply xml's as arguements!${nocol}"
	exit
fi

# o/p
for var in "$@"; do
	# Copy files
	cp -a "$var" "$PROJECT_DIR"/working/manifest.xml
	while IFS= read -r line
	do
		if echo "$line" | grep "<project"; then
			if ! echo "$line" | grep "clone-depth"; then
				if echo "$line" | grep -iE "LineageOS|remote=\"aex"; then
					echo "$line" >> "$PROJECT_DIR"/working/new_manifest.xml
				else
					echo "$line" | sed "s|<project|<project clone-depth=\"1\"|g" >> "$PROJECT_DIR"/working/new_manifest.xml
				fi
			else
				echo "$line" >> "$PROJECT_DIR"/working/new_manifest.xml
			fi
		else
			echo "$line" >> "$PROJECT_DIR"/working/new_manifest.xml
		fi
	done < "$var"
	cat "$PROJECT_DIR"/working/new_manifest.xml > "$var"
	rm -rf "$PROJECT_DIR"/working/new_manifest.xml
done
