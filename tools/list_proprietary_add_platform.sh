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

declare -a arr=("msm8937" "msm8953" "msm8996" "msm8998" "msmnile" "qcom" "sdm660" "sdm710" "sdm845" "sm6125" "sm6150" "sm8150" "trinket")

add_platform()
{
	for target_platform in "${arr[@]}"; do
		echo "$target_line" | sed "s|REMOVEME|$target_platform|g" >> "$target_file"
	done
}

target_line="vendor/lib/hw/audio.primary.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Audio-Hardware" && add_platform
target_line="vendor/lib64/hw/audio.primary.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Audio-Hardware" && add_platform
target_line="vendor/lib/hw/camera.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Camera" && add_platform
target_line="vendor/lib64/hw/camera.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Camera" && add_platform
target_line="vendor/lib/hw/gralloc.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Display-Hardware" && add_platform
target_line="vendor/lib/hw/hwcomposer.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Display-Hardware" && add_platform
target_line="vendor/lib/hw/memtrack.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Display-Hardware" && add_platform
target_line="vendor/lib64/hw/gralloc.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Display-Hardware" && add_platform
target_line="vendor/lib64/hw/hwcomposer.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Display-Hardware" && add_platform
target_line="vendor/lib64/hw/memtrack.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Display-Hardware" && add_platform
target_line="vendor/lib/hw/vulkan.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Graphics" && add_platform
target_line="vendor/lib64/hw/vulkan.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Graphics" && add_platform
target_line="vendor/lib/hw/sound_trigger.primary.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Listen" && add_platform
target_line="vendor/lib64/hw/sound_trigger.primary.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Listen" && add_platform
target_line="vendor/lib/hw/activity_recognition.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Sensors" && add_platform
target_line="vendor/lib/hw/sensors.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Sensors" && add_platform
target_line="vendor/lib64/hw/activity_recognition.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Sensors" && add_platform
target_line="vendor/lib64/hw/sensors.REMOVEME.so" && target_file="$PROJECT_DIR/tools/lists/proprietary/Sensors" && add_platform

# sort lists
bash $PROJECT_DIR/tools/lists_sort_all.sh
