#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Exit if no arguements
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
	echo -e "${bold}${red}Supply apiToken, chat_id, text-file, parse_mode & php-output-path as arguements!${nocol}"
	exit
fi

# prepare php
printf "<html>\n<body>\n<?php\n\t\$apiToken = \""$1"\";\n\t\$data = [\n\t\t" > "$5"
printf "'chat_id' => '"$2"',\n\t\t'text' => file_get_contents(\""$3"\"),\n\t\t'parse_mode' => '"$4"'\n\t];" >> "$5"
printf "\n\t\$response = file_get_contents(\"https://api.telegram.org/bot\$apiToken/sendMessage?\" . http_build_query(\$data) );" >> "$5"
printf "\n?>\n</body>\n</html>" >> "$5"

# execute php
php "$5"
