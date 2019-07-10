#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Text format
bold=$(tput bold)
cyan='\033[0;36m'
nocol='\033[0m'
red='\033[0;31m'

# Create $PROJECT_DIR/working directory if it does not exist
if [ ! -d $PROJECT_DIR/working ]; then
	mkdir -p $PROJECT_DIR/working
fi

# clean up
if [ "$1" = "y" ]; then
	rm -rf $PROJECT_DIR/working/*
fi
