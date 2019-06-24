#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

PRODUCT_COPY_FILES_LIST=()
PRODUCT_COPY_FILES_HASHES=()
PRODUCT_COPY_FILES_FIXUP_HASHES=()
PRODUCT_PACKAGES_LIST=()
PRODUCT_PACKAGES_HASHES=()
PRODUCT_PACKAGES_FIXUP_HASHES=()
PACKAGE_LIST=()
VENDOR_STATE=-1
VENDOR_RADIO_STATE=-1
COMMON=-1
ARCHES=
FULLY_DEODEXED=-1

TMPDIR=$(mktemp -d)

#
# cleanup
#
# kill our tmpfiles with fire on exit
#
function cleanup() {
    rm -rf "${TMPDIR:?}"
}

trap cleanup 0

#
# setup_vendor
#
# $1: device name
# $2: vendor name
# $3: Lineage root directory
# $4: is common device - optional, default to false
# $5: cleanup - optional, default to true
# $6: custom vendor makefile name - optional, default to false
#
# Must be called before any other functions can be used. This
# sets up the internal state for a new vendor configuration.
#
function setup_vendor() {
    local DEVICE="$1"
    if [ -z "$DEVICE" ]; then
        echo "\$DEVICE must be set before including this script!"
        exit 1
    fi

    export VENDOR="$2"
    if [ -z "$VENDOR" ]; then
        echo "\$VENDOR must be set before including this script!"
        exit 1
    fi

    export LINEAGE_ROOT="$3"
    if [ ! -d "$LINEAGE_ROOT" ]; then
        echo "\$LINEAGE_ROOT must be set and valid before including this script!"
        exit 1
    fi

    export OUTDIR=vendor/"$VENDOR"/"$DEVICE"
    if [ ! -d "$LINEAGE_ROOT/$OUTDIR" ]; then
        mkdir -p "$LINEAGE_ROOT/$OUTDIR"
    fi

    VNDNAME="$6"
    if [ -z "$VNDNAME" ]; then
        VNDNAME="$DEVICE"
    fi

    export PRODUCTMK="$LINEAGE_ROOT"/"$OUTDIR"/"$VNDNAME"-vendor.mk
    export ANDROIDMK="$LINEAGE_ROOT"/"$OUTDIR"/Android.mk
    export BOARDMK="$LINEAGE_ROOT"/"$OUTDIR"/BoardConfigVendor.mk

    if [ "$4" == "true" ] || [ "$4" == "1" ]; then
        COMMON=1
    else
        COMMON=0
    fi

    if [ "$5" == "false" ] || [ "$5" == "0" ]; then
        VENDOR_STATE=1
        VENDOR_RADIO_STATE=1
    else
        VENDOR_STATE=0
        VENDOR_RADIO_STATE=0
    fi
}

# Helper functions for parsing a spec.
# notes: an optional "|SHA1" that may appear in the format is stripped
#        early from the spec in the parse_file_list function, and
#        should not be present inside the input parameter passed
#        to these functions.

#
# input: spec in the form of "src[:dst][;args]"
# output: "src"
#
function src_file() {
    local SPEC="$1"
    local SPLIT=(${SPEC//:/ })
    local ARGS="$(target_args ${SPEC})"
    # Regardless of there being a ":" delimiter or not in the spec,
    # the source file is always either the first, or the only entry.
    local SRC="${SPLIT[0]}"
    # Remove target_args suffix, if present
    echo "${SRC%;${ARGS}}"
}

#
# input: spec in the form of "src[:dst][;args]"
# output: "dst" if present, "src" otherwise.
#
function target_file() {
    local SPEC="$1"
    local SPLIT=(${SPEC//:/ })
    local ARGS="$(target_args ${SPEC})"
    local DST=
    case ${#SPLIT[@]} in
    1)
        # The spec doesn't have a : delimiter
        DST="${SPLIT[0]}"
        ;;
    *)
        # The spec actually has a src:dst format
        DST="${SPLIT[1]}"
        ;;
    esac
    # Remove target_args suffix, if present
    echo "${DST%;${ARGS}}"
}

#
# input: spec in the form of "src[:dst][;args]"
# output: "args" if present, "" otherwise.
#
function target_args() {
    local SPEC="$1"
    local SPLIT=(${SPEC//;/ })
    local ARGS=
    case ${#SPLIT[@]} in
    1)
        # No ";" delimiter in the spec.
        ;;
    *)
        # The "args" are whatever comes after the ";" character.
        # Basically the spec stripped of whatever is to the left of ";".
        ARGS="${SPEC#${SPLIT[0]};}"
        ;;
    esac
    echo "${ARGS}"
}

#
# prefix_match:
#
# input:
#   - $1: prefix
#   - (global variable) PRODUCT_PACKAGES_LIST: array of [src:]dst[;args] specs.
# output:
#   - new array consisting of dst[;args] entries where $1 is a prefix of ${dst}.
#
function prefix_match() {
    local PREFIX="$1"
    for LINE in "${PRODUCT_PACKAGES_LIST[@]}"; do
        local FILE=$(target_file "$LINE")
        if [[ "$FILE" =~ ^"$PREFIX" ]]; then
            local ARGS=$(target_args "$LINE")
            if [ -z "${ARGS}" ]; then
                echo "${FILE#$PREFIX}"
            else
                echo "${FILE#$PREFIX};${ARGS}"
            fi
        fi
    done
}

#
# prefix_match_file:
#
# $1: the prefix to match on
# $2: the file to match the prefix for
#
# Internal function which returns true if a filename contains the
# specified prefix.
#
function prefix_match_file() {
    local PREFIX="$1"
    local FILE="$2"
    if [[ "$FILE" =~ ^"$PREFIX" ]]; then
        return 0
    else
        return 1
    fi
}

#
# suffix_match_file:
#
# $1: the suffix to match on
# $2: the file to match the suffix for
#
# Internal function which returns true if a filename contains the
# specified suffix.
#
function suffix_match_file() {
    local SUFFIX="$1"
    local FILE="$2"
    if [[ "$FILE" = *"$SUFFIX" ]]; then
        return 0
    else
        return 1
    fi
}

#
# truncate_file
#
# $1: the filename to truncate
# $2: the argument to output the truncated filename to
#
# Internal function which truncates a filename by removing the first dir
# in the path. ex. vendor/lib/libsdmextension.so -> lib/libsdmextension.so
#
function truncate_file() {
    local FILE="$1"
    RETURN_FILE="$2"
    local FIND="${FILE%%/*}"
    local LOCATION="${#FIND}+1"
    echo ${FILE:$LOCATION}
}

#
# write_product_copy_files:
#
# $1: make treble compatible makefile - optional, default to false
#
# Creates the PRODUCT_COPY_FILES section in the product makefile for all
# items in the list which do not start with a dash (-).
#
function write_product_copy_files() {
    local COUNT=${#PRODUCT_COPY_FILES_LIST[@]}
    local TARGET=
    local FILE=
    local LINEEND=
    local TREBLE_COMPAT=$1

    if [ "$COUNT" -eq "0" ]; then
        return 0
    fi

    printf '%s\n' "PRODUCT_COPY_FILES += \\" >> "$PRODUCTMK"
    for (( i=1; i<COUNT+1; i++ )); do
        FILE="${PRODUCT_COPY_FILES_LIST[$i-1]}"
        LINEEND=" \\"
        if [ "$i" -eq "$COUNT" ]; then
            LINEEND=""
        fi

        TARGET=$(target_file "$FILE")
        if [ "$TREBLE_COMPAT" == "true" ] || [ "$TREBLE_COMPAT" == "1" ]; then
            if prefix_match_file "vendor/" $TARGET ; then
                local OUTTARGET=$(truncate_file $TARGET)
                printf '    %s/proprietary/%s:$(TARGET_COPY_OUT_VENDOR)/%s%s\n' \
                    "$OUTDIR" "$TARGET" "$OUTTARGET" "$LINEEND" >> "$PRODUCTMK"
            else
                printf '    %s/proprietary/%s:system/%s%s\n' \
                    "$OUTDIR" "$TARGET" "$TARGET" "$LINEEND" >> "$PRODUCTMK"
            fi
        else
            printf '    %s/proprietary/%s:system/%s%s\n' \
                "$OUTDIR" "$TARGET" "$TARGET" "$LINEEND" >> "$PRODUCTMK"
        fi
    done
    return 0
}

#
# write_packages:
#
# $1: The LOCAL_MODULE_CLASS for the given module list
# $2: "true" if this package is part of the vendor/ path
# $3: type-specific extra flags
# $4: Name of the array holding the target list
#
# Internal function which writes out the BUILD_PREBUILT stanzas
# for all modules in the list. This is called by write_product_packages
# after the modules are categorized.
#
function write_packages() {

    local CLASS="$1"
    local VENDOR_PKG="$2"
    local EXTRA="$3"

    # Yes, this is a horrible hack - we create a new array using indirection
    local ARR_NAME="$4[@]"
    local FILELIST=("${!ARR_NAME}")

    local FILE=
    local ARGS=
    local BASENAME=
    local EXTENSION=
    local PKGNAME=
    local SRC=

    for P in "${FILELIST[@]}"; do
        FILE=$(target_file "$P")
        ARGS=$(target_args "$P")

        BASENAME=$(basename "$FILE")
        DIRNAME=$(dirname "$FILE")
        EXTENSION=${BASENAME##*.}
        PKGNAME=${BASENAME%.*}

        # Add to final package list
        PACKAGE_LIST+=("$PKGNAME")

        SRC="proprietary"
        if [ "$VENDOR_PKG" = "true" ]; then
            SRC+="/vendor"
        fi

        printf 'include $(CLEAR_VARS)\n'
        printf 'LOCAL_MODULE := %s\n' "$PKGNAME"
        printf 'LOCAL_MODULE_OWNER := %s\n' "$VENDOR"
        if [ "$CLASS" = "SHARED_LIBRARIES" ]; then
            if [ "$EXTRA" = "both" ]; then
                printf 'LOCAL_SRC_FILES_64 := %s/lib64/%s\n' "$SRC" "$FILE"
                printf 'LOCAL_SRC_FILES_32 := %s/lib/%s\n' "$SRC" "$FILE"
                #if [ "$VENDOR_PKG" = "true" ]; then
                #    echo "LOCAL_MODULE_PATH_64 := \$(TARGET_OUT_VENDOR_SHARED_LIBRARIES)"
                #    echo "LOCAL_MODULE_PATH_32 := \$(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)"
                #else
                #    echo "LOCAL_MODULE_PATH_64 := \$(TARGET_OUT_SHARED_LIBRARIES)"
                #    echo "LOCAL_MODULE_PATH_32 := \$(2ND_TARGET_OUT_SHARED_LIBRARIES)"
                #fi
            elif [ "$EXTRA" = "64" ]; then
                printf 'LOCAL_SRC_FILES := %s/lib64/%s\n' "$SRC" "$FILE"
            else
                printf 'LOCAL_SRC_FILES := %s/lib/%s\n' "$SRC" "$FILE"
            fi
            if [ "$EXTRA" != "none" ]; then
                printf 'LOCAL_MULTILIB := %s\n' "$EXTRA"
            fi
        elif [ "$CLASS" = "APPS" ]; then
            if [ "$EXTRA" = "priv-app" ]; then
                SRC="$SRC/priv-app"
            else
                SRC="$SRC/app"
            fi
            printf 'LOCAL_SRC_FILES := %s/%s\n' "$SRC" "$FILE"
            local CERT=platform
            if [ ! -z "$ARGS" ]; then
                CERT="$ARGS"
            fi
            printf 'LOCAL_CERTIFICATE := %s\n' "$CERT"
        elif [ "$CLASS" = "JAVA_LIBRARIES" ]; then
            printf 'LOCAL_SRC_FILES := %s/framework/%s\n' "$SRC" "$FILE"
            local CERT=platform
            if [ ! -z "$ARGS" ]; then
                CERT="$ARGS"
            fi
            printf 'LOCAL_CERTIFICATE := %s\n' "$CERT"
        elif [ "$CLASS" = "ETC" ]; then
            printf 'LOCAL_SRC_FILES := %s/etc/%s\n' "$SRC" "$FILE"
        elif [ "$CLASS" = "EXECUTABLES" ]; then
            if [ "$ARGS" = "rootfs" ]; then
                SRC="$SRC/rootfs"
                if [ "$EXTRA" = "sbin" ]; then
                    SRC="$SRC/sbin"
                    printf '%s\n' "LOCAL_MODULE_PATH := \$(TARGET_ROOT_OUT_SBIN)"
                    printf '%s\n' "LOCAL_UNSTRIPPED_PATH := \$(TARGET_ROOT_OUT_SBIN_UNSTRIPPED)"
                fi
            else
                SRC="$SRC/bin"
            fi
            printf 'LOCAL_SRC_FILES := %s/%s\n' "$SRC" "$FILE"
            unset EXTENSION
        else
            printf 'LOCAL_SRC_FILES := %s/%s\n' "$SRC" "$FILE"
        fi
        printf 'LOCAL_MODULE_TAGS := optional\n'
        printf 'LOCAL_MODULE_CLASS := %s\n' "$CLASS"
        if [ "$CLASS" = "APPS" ]; then
            printf 'LOCAL_DEX_PREOPT := false\n'
        fi
        if [ ! -z "$EXTENSION" ]; then
            printf 'LOCAL_MODULE_SUFFIX := .%s\n' "$EXTENSION"
        fi
        if [ "$CLASS" = "SHARED_LIBRARIES" ] || [ "$CLASS" = "EXECUTABLES" ]; then
            if [ "$DIRNAME" != "." ]; then
                printf 'LOCAL_MODULE_RELATIVE_PATH := %s\n' "$DIRNAME"
            fi
        fi
        if [ "$EXTRA" = "priv-app" ]; then
            printf 'LOCAL_PRIVILEGED_MODULE := true\n'
        fi
        if [ "$VENDOR_PKG" = "true" ]; then
            printf 'LOCAL_VENDOR_MODULE := true\n'
        fi
        printf 'include $(BUILD_PREBUILT)\n\n'
    done
}

#
# write_product_packages:
#
# This function will create BUILD_PREBUILT entries in the
# Android.mk and associated PRODUCT_PACKAGES list in the
# product makefile for all files in the blob list which
# start with a single dash (-) character.
#
function write_product_packages() {
    PACKAGE_LIST=()

    local COUNT=${#PRODUCT_PACKAGES_LIST[@]}

    if [ "$COUNT" = "0" ]; then
        return 0
    fi

    # Figure out what's 32-bit, what's 64-bit, and what's multilib
    # I really should not be doing this in bash due to shitty array passing :(
    local T_LIB32=( $(prefix_match "lib/") )
    local T_LIB64=( $(prefix_match "lib64/") )
    local MULTILIBS=( $(comm -12 <(printf '%s\n' "${T_LIB32[@]}") <(printf '%s\n' "${T_LIB64[@]}")) )
    local LIB32=( $(comm -23 <(printf '%s\n'  "${T_LIB32[@]}") <(printf '%s\n' "${MULTILIBS[@]}")) )
    local LIB64=( $(comm -23 <(printf '%s\n' "${T_LIB64[@]}") <(printf '%s\n' "${MULTILIBS[@]}")) )

    if [ "${#MULTILIBS[@]}" -gt "0" ]; then
        write_packages "SHARED_LIBRARIES" "false" "both" "MULTILIBS" >> "$ANDROIDMK"
    fi
    if [ "${#LIB32[@]}" -gt "0" ]; then
        write_packages "SHARED_LIBRARIES" "false" "32" "LIB32" >> "$ANDROIDMK"
    fi
    if [ "${#LIB64[@]}" -gt "0" ]; then
        write_packages "SHARED_LIBRARIES" "false" "64" "LIB64" >> "$ANDROIDMK"
    fi

    local T_V_LIB32=( $(prefix_match "vendor/lib/") )
    local T_V_LIB64=( $(prefix_match "vendor/lib64/") )
    local V_MULTILIBS=( $(comm -12 <(printf '%s\n' "${T_V_LIB32[@]}") <(printf '%s\n' "${T_V_LIB64[@]}")) )
    local V_LIB32=( $(comm -23 <(printf '%s\n' "${T_V_LIB32[@]}") <(printf '%s\n' "${V_MULTILIBS[@]}")) )
    local V_LIB64=( $(comm -23 <(printf '%s\n' "${T_V_LIB64[@]}") <(printf '%s\n' "${V_MULTILIBS[@]}")) )

    if [ "${#V_MULTILIBS[@]}" -gt "0" ]; then
        write_packages "SHARED_LIBRARIES" "true" "both" "V_MULTILIBS" >> "$ANDROIDMK"
    fi
    if [ "${#V_LIB32[@]}" -gt "0" ]; then
        write_packages "SHARED_LIBRARIES" "true" "32" "V_LIB32" >> "$ANDROIDMK"
    fi
    if [ "${#V_LIB64[@]}" -gt "0" ]; then
        write_packages "SHARED_LIBRARIES" "true" "64" "V_LIB64" >> "$ANDROIDMK"
    fi

    # Apps
    local APPS=( $(prefix_match "app/") )
    if [ "${#APPS[@]}" -gt "0" ]; then
        write_packages "APPS" "false" "" "APPS" >> "$ANDROIDMK"
    fi
    local PRIV_APPS=( $(prefix_match "priv-app/") )
    if [ "${#PRIV_APPS[@]}" -gt "0" ]; then
        write_packages "APPS" "false" "priv-app" "PRIV_APPS" >> "$ANDROIDMK"
    fi
    local V_APPS=( $(prefix_match "vendor/app/") )
    if [ "${#V_APPS[@]}" -gt "0" ]; then
        write_packages "APPS" "true" "" "V_APPS" >> "$ANDROIDMK"
    fi
    local V_PRIV_APPS=( $(prefix_match "vendor/priv-app/") )
    if [ "${#V_PRIV_APPS[@]}" -gt "0" ]; then
        write_packages "APPS" "true" "priv-app" "V_PRIV_APPS" >> "$ANDROIDMK"
    fi

    # Framework
    local FRAMEWORK=( $(prefix_match "framework/") )
    if [ "${#FRAMEWORK[@]}" -gt "0" ]; then
        write_packages "JAVA_LIBRARIES" "false" "" "FRAMEWORK" >> "$ANDROIDMK"
    fi
    local V_FRAMEWORK=( $(prefix_match "vendor/framework/") )
    if [ "${#V_FRAMEWORK[@]}" -gt "0" ]; then
        write_packages "JAVA_LIBRARIES" "true" "" "V_FRAMEWORK" >> "$ANDROIDMK"
    fi

    # Etc
    local ETC=( $(prefix_match "etc/") )
    if [ "${#ETC[@]}" -gt "0" ]; then
        write_packages "ETC" "false" "" "ETC" >> "$ANDROIDMK"
    fi
    local V_ETC=( $(prefix_match "vendor/etc/") )
    if [ "${#V_ETC[@]}" -gt "0" ]; then
        write_packages "ETC" "true" "" "V_ETC" >> "$ANDROIDMK"
    fi

    # Executables
    local BIN=( $(prefix_match "bin/") )
    if [ "${#BIN[@]}" -gt "0"  ]; then
        write_packages "EXECUTABLES" "false" "" "BIN" >> "$ANDROIDMK"
    fi
    local V_BIN=( $(prefix_match "vendor/bin/") )
    if [ "${#V_BIN[@]}" -gt "0" ]; then
        write_packages "EXECUTABLES" "true" "" "V_BIN" >> "$ANDROIDMK"
    fi
    local SBIN=( $(prefix_match "sbin/") )
    if [ "${#SBIN[@]}" -gt "0" ]; then
        write_packages "EXECUTABLES" "false" "sbin" "SBIN" >> "$ANDROIDMK"
    fi


    # Actually write out the final PRODUCT_PACKAGES list
    local PACKAGE_COUNT=${#PACKAGE_LIST[@]}

    if [ "$PACKAGE_COUNT" -eq "0" ]; then
        return 0
    fi

    printf '\n%s\n' "PRODUCT_PACKAGES += \\" >> "$PRODUCTMK"
    for (( i=1; i<PACKAGE_COUNT+1; i++ )); do
        local LINEEND=" \\"
        if [ "$i" -eq "$PACKAGE_COUNT" ]; then
            LINEEND=""
        fi
        printf '    %s%s\n' "${PACKAGE_LIST[$i-1]}" "$LINEEND" >> "$PRODUCTMK"
    done
}

#
# write_header:
#
# $1: file which will be written to
#
# writes out the copyright header with the current year.
# note that this is not an append operation, and should
# be executed first!
#
function write_header() {
    if [ -f $1 ]; then
        rm $1
    fi

    YEAR=$(date +"%Y")

    [ "$COMMON" -eq 1 ] && local DEVICE="$DEVICE_COMMON"

    NUM_REGEX='^[0-9]+$'
    if [[ $INITIAL_COPYRIGHT_YEAR =~ $NUM_REGEX ]] && [ $INITIAL_COPYRIGHT_YEAR -le $YEAR ]; then
        if [ $INITIAL_COPYRIGHT_YEAR -lt 2016 ]; then
            printf "# Copyright (C) $INITIAL_COPYRIGHT_YEAR-2016 The CyanogenMod Project\n" > $1
        elif [ $INITIAL_COPYRIGHT_YEAR -eq 2016 ]; then
            printf "# Copyright (C) 2016 The CyanogenMod Project\n" > $1
        fi
        if [ $YEAR -eq 2017 ]; then
            printf "# Copyright (C) 2017 The LineageOS Project\n" >> $1
        elif [ $INITIAL_COPYRIGHT_YEAR -eq $YEAR ]; then
            printf "# Copyright (C) $YEAR The LineageOS Project\n" >> $1
        elif [ $INITIAL_COPYRIGHT_YEAR -le 2017 ]; then
            printf "# Copyright (C) 2017-$YEAR The LineageOS Project\n" >> $1
        else
            printf "# Copyright (C) $INITIAL_COPYRIGHT_YEAR-$YEAR The LineageOS Project\n" >> $1
        fi
    else
        printf "# Copyright (C) $YEAR The LineageOS Project\n" > $1
    fi

    cat << EOF >> $1
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is generated by device/$VENDOR/$DEVICE/setup-makefiles.sh

EOF
}

#
# write_headers:
#
# $1: devices falling under common to be added to guard - optional
# $2: custom guard - optional
#
# Calls write_header for each of the makefiles and creates
# the initial path declaration and device guard for the
# Android.mk
#
function write_headers() {
    write_header "$ANDROIDMK"

    GUARD="$2"
    if [ -z "$GUARD" ]; then
        GUARD="TARGET_DEVICE"
    fi

    cat << EOF >> "$ANDROIDMK"
LOCAL_PATH := \$(call my-dir)

EOF
    if [ "$COMMON" -ne 1 ]; then
        cat << EOF >> "$ANDROIDMK"
ifeq (\$($GUARD),$DEVICE)

EOF
    else
        if [ -z "$1" ]; then
            echo "Argument with devices to be added to guard must be set!"
            exit 1
        fi
        cat << EOF >> "$ANDROIDMK"
ifneq (\$(filter $1,\$($GUARD)),)

EOF
    fi

    write_header "$BOARDMK"
    write_header "$PRODUCTMK"
}

#
# write_footers:
#
# Closes the inital guard and any other finalization tasks. Must
# be called as the final step.
#
function write_footers() {
    cat << EOF >> "$ANDROIDMK"
endif
EOF
}

# Return success if adb is up and not in recovery
function _adb_connected {
    {
        if [[ "$(adb get-state)" == device ]]
        then
            return 0
        fi
    } 2>/dev/null

    return 1
};

#
# parse_file_list:
#
# $1: input file
# $2: blob section in file - optional
#
# Sets PRODUCT_PACKAGES and PRODUCT_COPY_FILES while parsing the input file
#
function parse_file_list() {
    if [ -z "$1" ]; then
        echo "An input file is expected!"
        exit 1
    elif [ ! -f "$1" ]; then
        echo "Input file "$1" does not exist!"
        exit 1
    fi

    if [ -n "$2" ]; then
        echo "Using section \"$2\""
        LIST=$TMPDIR/files.txt
        # Match all lines starting with first line found to start* with '#'
        # comment and contain** $2, and ending with first line to be empty*.
        # *whitespaces (tabs, spaces) at the beginning of lines are discarded
        # **the $2 match is case-insensitive
        cat $1 | sed -n '/^[[:space:]]*#.*'"$2"'/I,/^[[:space:]]*$/ p' > $LIST
    else
        LIST=$1
    fi


    PRODUCT_PACKAGES_LIST=()
    PRODUCT_PACKAGES_HASHES=()
    PRODUCT_PACKAGES_FIXUP_HASHES=()
    PRODUCT_COPY_FILES_LIST=()
    PRODUCT_COPY_FILES_HASHES=()
    PRODUCT_COPY_FILES_FIXUP_HASHES=()

    while read -r line; do
        if [ -z "$line" ]; then continue; fi

        # If the line has a pipe delimiter, a sha1 hash should follow.
        # This indicates the file should be pinned and not overwritten
        # when extracting files.
        local SPLIT=(${line//\|/ })
        local COUNT=${#SPLIT[@]}
        local SPEC=${SPLIT[0]}
        local HASH="x"
        local FIXUP_HASH="x"
        if [ "$COUNT" -gt "1" ]; then
            HASH=${SPLIT[1]}
        fi
        if [ "$COUNT" -gt "2" ]; then
            FIXUP_HASH=${SPLIT[2]}
        fi

        # if line starts with a dash, it needs to be packaged
        if [[ "$SPEC" =~ ^- ]]; then
            PRODUCT_PACKAGES_LIST+=("${SPEC#-}")
            PRODUCT_PACKAGES_HASHES+=("$HASH")
            PRODUCT_PACKAGES_FIXUP_HASHES+=("$FIXUP_HASH")
        else
            PRODUCT_COPY_FILES_LIST+=("$SPEC")
            PRODUCT_COPY_FILES_HASHES+=("$HASH")
            PRODUCT_COPY_FILES_FIXUP_HASHES+=("$FIXUP_HASH")
        fi

    done < <(egrep -v '(^#|^[[:space:]]*$)' "$LIST" | LC_ALL=C sort | uniq)
}

#
# write_makefiles:
#
# $1: file containing the list of items to extract
# $2: make treble compatible makefile - optional
#
# Calls write_product_copy_files and write_product_packages on
# the given file and appends to the Android.mk as well as
# the product makefile.
#
function write_makefiles() {
    parse_file_list "$1"
    write_product_copy_files "$2"
    write_product_packages
}

#
# append_firmware_calls_to_makefiles:
#
# Appends to Android.mk the calls to all images present in radio folder
# (filesmap file used by releasetools to map firmware images should be kept in the device tree)
#
function append_firmware_calls_to_makefiles() {
    cat << EOF >> "$ANDROIDMK"
ifeq (\$(LOCAL_PATH)/radio, \$(wildcard \$(LOCAL_PATH)/radio))

RADIO_FILES := \$(wildcard \$(LOCAL_PATH)/radio/*)
\$(foreach f, \$(notdir \$(RADIO_FILES)), \\
    \$(call add-radio-file,radio/\$(f)))
\$(call add-radio-file,../../../device/$VENDOR/$DEVICE/radio/filesmap)

endif

EOF
}

#
# get_file:
#
# $1: input file
# $2: target file/folder
# $3: source of the file (can be "adb" or a local folder)
#
# Silently extracts the input file to defined target
# Returns success if file can be pulled from the device or found locally
#
function get_file() {
    local SRC="$3"

    if [ "$SRC" = "adb" ]; then
        # try to pull
        adb pull "$1" "$2" >/dev/null 2>&1 && return 0

        return 1
    else
        # try to copy
        cp -r "$SRC/$1"           "$2" 2>/dev/null && return 0
        cp -r "$SRC/${1#/system}" "$2" 2>/dev/null && return 0
        cp -r "$SRC/system/$1"    "$2" 2>/dev/null && return 0

        return 1
    fi
};

#
# oat2dex:
#
# $1: extracted apk|jar (to check if deodex is required)
# $2: odexed apk|jar to deodex
# $3: source of the odexed apk|jar
#
# Convert apk|jar .odex in the corresposing classes.dex
#
function oat2dex() {
    local LINEAGE_TARGET="$1"
    local OEM_TARGET="$2"
    local SRC="$3"
    local TARGET=
    local OAT=
    local HOST="$(uname)"

    if [ -z "$BAKSMALIJAR" ] || [ -z "$SMALIJAR" ]; then
        export BAKSMALIJAR="$LINEAGE_ROOT"/vendor/lineage/build/tools/smali/baksmali.jar
        export SMALIJAR="$LINEAGE_ROOT"/vendor/lineage/build/tools/smali/smali.jar
    fi

    if [ -z "$VDEXEXTRACTOR" ]; then
        export VDEXEXTRACTOR="$LINEAGE_ROOT"/vendor/lineage/build/tools/"$HOST"/vdexExtractor
    fi

    if [ -z "$CDEXCONVERTER" ]; then
        export CDEXCONVERTER="$LINEAGE_ROOT"/vendor/lineage/build/tools/"$HOST"/compact_dex_converter
    fi

    # Extract existing boot.oats to the temp folder
    if [ -z "$ARCHES" ]; then
        echo "Checking if system is odexed and locating boot.oats..."
        for ARCH in "arm64" "arm" "x86_64" "x86"; do
            mkdir -p "$TMPDIR/system/framework/$ARCH"
            if get_file "/system/framework/$ARCH" "$TMPDIR/system/framework/" "$SRC"; then
                ARCHES+="$ARCH "
            else
                rmdir "$TMPDIR/system/framework/$ARCH"
            fi
        done
    fi

    if [ -z "$ARCHES" ]; then
        FULLY_DEODEXED=1 && return 0 # system is fully deodexed, return
    fi

    if [ ! -f "$LINEAGE_TARGET" ]; then
        return;
    fi

    if grep "classes.dex" "$LINEAGE_TARGET" >/dev/null; then
        return 0 # target apk|jar is already odexed, return
    fi

    for ARCH in $ARCHES; do
        BOOTOAT="$TMPDIR/system/framework/$ARCH/boot.oat"

        local OAT="$(dirname "$OEM_TARGET")/oat/$ARCH/$(basename "$OEM_TARGET" ."${OEM_TARGET##*.}").odex"
        local VDEX="$(dirname "$OEM_TARGET")/oat/$ARCH/$(basename "$OEM_TARGET" ."${OEM_TARGET##*.}").vdex"

        if get_file "$OAT" "$TMPDIR" "$SRC"; then
            if get_file "$VDEX" "$TMPDIR" "$SRC"; then
                "$VDEXEXTRACTOR" -o "$TMPDIR/" -i "$TMPDIR/$(basename "$VDEX")" > /dev/null
                # Check if we have to deal with CompactDex
                if [ -f "$TMPDIR/$(basename "${OEM_TARGET%.*}")_classes.cdex" ]; then
                    "$CDEXCONVERTER" "$TMPDIR/$(basename "${OEM_TARGET%.*}")_classes.cdex" &> /dev/null
                    mv "$TMPDIR/$(basename "${OEM_TARGET%.*}")_classes.cdex.new" "$TMPDIR/classes.dex"
                else
                    mv "$TMPDIR/$(basename "${OEM_TARGET%.*}")_classes.dex" "$TMPDIR/classes.dex"
                fi
            else
                java -jar "$BAKSMALIJAR" deodex -o "$TMPDIR/dexout" -b "$BOOTOAT" -d "$TMPDIR" "$TMPDIR/$(basename "$OAT")"
                java -jar "$SMALIJAR" assemble "$TMPDIR/dexout" -o "$TMPDIR/classes.dex"
            fi
        elif [[ "$LINEAGE_TARGET" =~ .jar$ ]]; then
            JAROAT="$TMPDIR/system/framework/$ARCH/boot-$(basename ${OEM_TARGET%.*}).oat"
            JARVDEX="/system/framework/boot-$(basename ${OEM_TARGET%.*}).vdex"
            if [ ! -f "$JAROAT" ]; then
                JAROAT=$BOOTOAT
            fi
            # try to extract classes.dex from boot.vdex for frameworks jars
            # fallback to boot.oat if vdex is not available
            if get_file "$JARVDEX" "$TMPDIR" "$SRC"; then
                "$VDEXEXTRACTOR" -o "$TMPDIR/" -i "$TMPDIR/$(basename "$JARVDEX")" > /dev/null
                # Check if we have to deal with CompactDex
                if [ -f "$TMPDIR/$(basename "${JARVDEX%.*}")_classes.cdex" ]; then
                    "$CDEXCONVERTER" "$TMPDIR/$(basename "${JARVDEX%.*}")_classes.cdex" &> /dev/null
                    mv "$TMPDIR/$(basename "${JARVDEX%.*}")_classes.cdex.new" "$TMPDIR/classes.dex"
                else
                    mv "$TMPDIR/$(basename "${JARVDEX%.*}")_classes.dex" "$TMPDIR/classes.dex"
                fi
            else
                java -jar "$BAKSMALIJAR" deodex -o "$TMPDIR/dexout" -b "$BOOTOAT" -d "$TMPDIR" "$JAROAT/$OEM_TARGET"
                java -jar "$SMALIJAR" assemble "$TMPDIR/dexout" -o "$TMPDIR/classes.dex"
            fi
        else
            continue
        fi

    done

    rm -rf "$TMPDIR/dexout"
}

#
# init_adb_connection:
#
# Starts adb server and waits for the device
#
function init_adb_connection() {
    adb start-server # Prevent unexpected starting server message from adb get-state in the next line
    if ! _adb_connected; then
        echo "No device is online. Waiting for one..."
        echo "Please connect USB and/or enable USB debugging"
        until _adb_connected; do
            sleep 1
        done
        echo "Device Found."
    fi

    # Retrieve IP and PORT info if we're using a TCP connection
    TCPIPPORT=$(adb devices | egrep '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+[^0-9]+' \
        | head -1 | awk '{print $1}')
    adb root &> /dev/null
    sleep 0.3
    if [ -n "$TCPIPPORT" ]; then
        # adb root just killed our connection
        # so reconnect...
        adb connect "$TCPIPPORT"
    fi
    adb wait-for-device &> /dev/null
    sleep 0.3
}

#
# fix_xml:
#
# $1: xml file to fix
#
function fix_xml() {
    local XML="$1"
    local TEMP_XML="$TMPDIR/`basename "$XML"`.temp"

    grep -a '^<?xml version' "$XML" > "$TEMP_XML"
    grep -av '^<?xml version' "$XML" >> "$TEMP_XML"

    mv "$TEMP_XML" "$XML"
}

function get_hash() {
    local FILE="$1"

    if [ "$(uname)" == "Darwin" ]; then
        shasum "${FILE}" | awk '{print $1}'
    else
        sha1sum "${FILE}" | awk '{print $1}'
    fi
}

function print_spec() {
    local SPEC_PRODUCT_PACKAGE="$1"
    local SPEC_SRC_FILE="$2"
    local SPEC_DST_FILE="$3"
    local SPEC_ARGS="$4"
    local SPEC_HASH="$5"
    local SPEC_FIXUP_HASH="$6"

    local PRODUCT_PACKAGE=""
    if [ ${SPEC_PRODUCT_PACKAGE} = true ]; then
        PRODUCT_PACKAGE="-"
    fi
    local SRC=""
    if [ ! -z "${SPEC_SRC_FILE}" ] && [ "${SPEC_SRC_FILE}" != "${SPEC_DST_FILE}" ]; then
        SRC="${SPEC_SRC_FILE}:"
    fi
    local DST=""
    if [ ! -z "${SPEC_DST_FILE}" ]; then
        DST="${SPEC_DST_FILE}"
    fi
    local ARGS=""
    if [ ! -z "${SPEC_ARGS}" ]; then
        ARGS=";${SPEC_ARGS}"
    fi
    local HASH=""
    if [ ! -z "${SPEC_HASH}" ] && [ "${SPEC_HASH}" != "x" ]; then
        HASH="|${SPEC_HASH}"
    fi
    local FIXUP_HASH=""
    if [ ! -z "${SPEC_FIXUP_HASH}" ] && [ "${SPEC_FIXUP_HASH}" != "x" ] && [ "${SPEC_FIXUP_HASH}" != "${SPEC_HASH}" ]; then
        FIXUP_HASH="|${SPEC_FIXUP_HASH}"
    fi
    printf '%s%s%s%s%s%s\n' "${PRODUCT_PACKAGE}" "${SRC}" "${DST}" "${ARGS}" "${HASH}" "${FIXUP_HASH}"
}

# To be overridden by device-level extract-files.sh
# Parameters:
#   $1: spec name of a blob. Can be used for filtering.
#       If the spec is "src:dest", then $1 is "dest".
#       If the spec is "src", then $1 is "src".
#   $2: path to blob file. Can be used for fixups.
#
function blob_fixup() {
    :
}

#
# extract:
#
# Positional parameters:
# $1: file containing the list of items to extract (aka proprietary-files.txt)
# $2: path to extracted system folder, an ota zip file, or "adb" to extract from device
# $3: section in list file to extract - optional. Setting section via $3 is deprecated.
#
# Non-positional parameters (coming after $2):
# --section: preferred way of selecting the portion to parse and extract from
#            proprietary-files.txt
# --kang: if present, this option will activate the printing of hashes for the
#         extracted blobs. Useful with --section for subsequent pinning of
#         blobs taken from other origins.
#
function extract() {
    # Consume positional parameters
    local PROPRIETARY_FILES_TXT="$1"; shift
    local SRC="$1"; shift
    local SECTION=""
    local KANG=false

    # Consume optional, non-positional parameters
    while [ "$#" -gt 0 ]; do
        case "$1" in
        -s|--section)
            SECTION="$2"; shift
            ;;
        -k|--kang)
            KANG=true
            DISABLE_PINNING=1
            ;;
        *)
            # Backwards-compatibility with the old behavior, where $3, if
            # present, denoted an optional positional ${SECTION} argument.
            # Users of ${SECTION} are encouraged to migrate from setting it as
            # positional $3, to non-positional --section ${SECTION}, the
            # reason being that it doesn't scale to have more than 1 optional
            # positional argument.
            SECTION="$1"
            ;;
        esac
        shift
    done

    if [ -z "$OUTDIR" ]; then
        echo "Output dir not set!"
        exit 1
    fi

    parse_file_list "${PROPRIETARY_FILES_TXT}" "${SECTION}"

    # Allow failing, so we can try $DEST and/or $FILE
    set +e

    local FILELIST=( ${PRODUCT_COPY_FILES_LIST[@]} ${PRODUCT_PACKAGES_LIST[@]} )
    local HASHLIST=( ${PRODUCT_COPY_FILES_HASHES[@]} ${PRODUCT_PACKAGES_HASHES[@]} )
    local FIXUP_HASHLIST=( ${PRODUCT_COPY_FILES_FIXUP_HASHES[@]} ${PRODUCT_PACKAGES_FIXUP_HASHES[@]} )
    local PRODUCT_COPY_FILES_COUNT=${#PRODUCT_COPY_FILES_LIST[@]}
    local COUNT=${#FILELIST[@]}
    local OUTPUT_ROOT="$LINEAGE_ROOT"/"$OUTDIR"/proprietary
    local OUTPUT_TMP="$TMPDIR"/"$OUTDIR"/proprietary

    if [ "$SRC" = "adb" ]; then
        init_adb_connection
    fi

    if [ -f "$SRC" ] && [ "${SRC##*.}" == "zip" ]; then
        DUMPDIR="$TMPDIR"/system_dump

        # Check if we're working with the same zip that was passed last time.
        # If so, let's just use what's already extracted.
        MD5=`md5sum "$SRC"| awk '{print $1}'`
        OLDMD5=`cat "$DUMPDIR"/zipmd5.txt`

        if [ "$MD5" != "$OLDMD5" ]; then
            rm -rf "$DUMPDIR"
            mkdir "$DUMPDIR"
            unzip "$SRC" -d "$DUMPDIR"
            echo "$MD5" > "$DUMPDIR"/zipmd5.txt

            # Stop if an A/B OTA zip is detected. We cannot extract these.
            if [ -a "$DUMPDIR"/payload.bin ]; then
                echo "A/B style OTA zip detected. This is not supported at this time. Stopping..."
                exit 1
            # If OTA is block based, extract it.
            elif [ -a "$DUMPDIR"/system.new.dat ]; then
                echo "Converting system.new.dat to system.img"
                python "$LINEAGE_ROOT"/vendor/lineage/build/tools/sdat2img.py "$DUMPDIR"/system.transfer.list "$DUMPDIR"/system.new.dat "$DUMPDIR"/system.img 2>&1
                rm -rf "$DUMPDIR"/system.new.dat "$DUMPDIR"/system
                mkdir "$DUMPDIR"/system "$DUMPDIR"/tmp
                echo "Requesting sudo access to mount the system.img"
                sudo mount -o loop "$DUMPDIR"/system.img "$DUMPDIR"/tmp
                cp -r "$DUMPDIR"/tmp/* "$DUMPDIR"/system/
                sudo umount "$DUMPDIR"/tmp
                rm -rf "$DUMPDIR"/tmp "$DUMPDIR"/system.img
            fi
        fi

        SRC="$DUMPDIR"
    fi

    if [ "$VENDOR_STATE" -eq "0" ]; then
        echo "Cleaning output directory ($OUTPUT_ROOT).."
        rm -rf "${OUTPUT_TMP:?}"
        mkdir -p "${OUTPUT_TMP:?}"
        if [ -d "$OUTPUT_ROOT" ]; then
            mv "${OUTPUT_ROOT:?}/"* "${OUTPUT_TMP:?}/"
        fi
        VENDOR_STATE=1
    fi

    echo "Extracting ${COUNT} files in ${PROPRIETARY_FILES_TXT} from ${SRC}:"

    for (( i=1; i<COUNT+1; i++ )); do

        local SPEC_SRC_FILE=$(src_file "${FILELIST[$i-1]}")
        local SPEC_DST_FILE=$(target_file "${FILELIST[$i-1]}")
        local SPEC_ARGS=$(target_args "${FILELIST[$i-1]}")
        local OUTPUT_DIR=
        local TMP_DIR=
        local SRC_FILE=
        local DST_FILE=
        local IS_PRODUCT_PACKAGE=false

        # Note: this relies on the fact that the ${FILELIST[@]} array
        # contains first ${PRODUCT_COPY_FILES_LIST[@]}, then ${PRODUCT_PACKAGES_LIST[@]}.
        if [ "${i}" -gt "${PRODUCT_COPY_FILES_COUNT}" ]; then
            IS_PRODUCT_PACKAGE=true
        fi

        if [ "${SPEC_ARGS}" = "rootfs" ]; then
            OUTPUT_DIR="${OUTPUT_ROOT}/rootfs"
            TMP_DIR="${OUTPUT_TMP}/rootfs"
            SRC_FILE="/${SPEC_SRC_FILE}"
            DST_FILE="/${SPEC_DST_FILE}"
        else
            OUTPUT_DIR="${OUTPUT_ROOT}"
            TMP_DIR="${OUTPUT_TMP}"
            SRC_FILE="/system/${SPEC_SRC_FILE}"
            DST_FILE="/system/${SPEC_DST_FILE}"
        fi

        # Strip the file path in the vendor repo of "system", if present
        local VENDOR_REPO_FILE="$OUTPUT_DIR/${DST_FILE#/system}"
        local BLOB_DISPLAY_NAME="${DST_FILE#/system/}"
        mkdir -p $(dirname "${VENDOR_REPO_FILE}")

        # Check pinned files
        local HASH="$(echo ${HASHLIST[$i-1]} | awk '{ print tolower($0); }')"
        local FIXUP_HASH="$(echo ${FIXUP_HASHLIST[$i-1]} | awk '{ print tolower($0); }')"
        local KEEP=""
        if [ "$DISABLE_PINNING" != "1" ] && [ "$HASH" != "x" ]; then
            if [ -f "${VENDOR_REPO_FILE}" ]; then
                local PINNED="${VENDOR_REPO_FILE}"
            else
                local PINNED="${TMP_DIR}${DST_FILE#/system}"
            fi
            if [ -f "$PINNED" ]; then
                local TMP_HASH=$(get_hash "${PINNED}")
                if [ "${TMP_HASH}" = "${HASH}" ] || [ "${TMP_HASH}" = "${FIXUP_HASH}" ]; then
                    KEEP="1"
                    if [ ! -f "${VENDOR_REPO_FILE}" ]; then
                        cp -p "$PINNED" "${VENDOR_REPO_FILE}"
                    fi
                fi
            fi
        fi

        if [ "${KANG}" = false ]; then
            printf '  - %s\n' "${BLOB_DISPLAY_NAME}"
        fi

        if [ "$KEEP" = "1" ]; then
            printf '    + keeping pinned file with hash %s\n' "${HASH}"
        else
            FOUND=false
            # Try Lineage target first.
            # Also try to search for files stripped of
            # the "/system" prefix, if we're actually extracting
            # from a system image.
            for CANDIDATE in "${DST_FILE}" "${SRC_FILE}"; do
                get_file ${CANDIDATE} ${VENDOR_REPO_FILE} ${SRC} && {
                    FOUND=true
                    break
                }
            done

            if [ "${FOUND}" = false ]; then
                printf '    !! %s: file not found in source\n' "${BLOB_DISPLAY_NAME}"
                continue
            fi
        fi

        # Blob fixup pipeline has 2 parts: one that is fixed and
        # one that is user-configurable
        local PRE_FIXUP_HASH=$(get_hash ${VENDOR_REPO_FILE})
        # Deodex apk|jar if that's the case
        if [[ "$FULLY_DEODEXED" -ne "1" && "${VENDOR_REPO_FILE}" =~ .(apk|jar)$ ]]; then
            oat2dex "${VENDOR_REPO_FILE}" "${SRC_FILE}" "$SRC"
            if [ -f "$TMPDIR/classes.dex" ]; then
                zip -gjq "${VENDOR_REPO_FILE}" "$TMPDIR/classes.dex"
                rm "$TMPDIR/classes.dex"
                printf '    (updated %s from odex files)\n' "${SRC_FILE}"
            fi
        elif [[ "${VENDOR_REPO_FILE}" =~ .xml$ ]]; then
            fix_xml "${VENDOR_REPO_FILE}"
        fi
        # Now run user-supplied fixup function
        blob_fixup "${BLOB_DISPLAY_NAME}" "${VENDOR_REPO_FILE}"
        local POST_FIXUP_HASH=$(get_hash ${VENDOR_REPO_FILE})

        if [ -f "${VENDOR_REPO_FILE}" ]; then
            local DIR=$(dirname "${VENDOR_REPO_FILE}")
            local TYPE="${DIR##*/}"
            if [ "$TYPE" = "bin" -o "$TYPE" = "sbin" ]; then
                chmod 755 "${VENDOR_REPO_FILE}"
            else
                chmod 644 "${VENDOR_REPO_FILE}"
            fi
        fi

        if [ "${KANG}" =  true ]; then
            print_spec "${IS_PRODUCT_PACKAGE}" "${SPEC_SRC_FILE}" "${SPEC_DST_FILE}" "${SPEC_ARGS}" "${PRE_FIXUP_HASH}" "${POST_FIXUP_HASH}"
        fi

        # Check and print whether the fixup pipeline actually did anything.
        # This isn't done right after the fixup pipeline because we want this print
        # to come after print_spec above, when in kang mode.
        if [ "${PRE_FIXUP_HASH}" != "${POST_FIXUP_HASH}" ]; then
            printf "    + Fixed up %s\n" "${BLOB_DISPLAY_NAME}"
            # Now sanity-check the spec for this blob.
            if [ "${KANG}" = false ] && [ "${FIXUP_HASH}" = "x" ] && [ "${HASH}" != "x" ]; then
                printf "WARNING: The %s file was fixed up, but it is pinned.\n" ${BLOB_DISPLAY_NAME}
                printf "This is a mistake and you want to either remove the hash completely, or add an extra one.\n"
            fi
        fi

    done

    # Don't allow failing
    set -e
}

#
# extract_firmware:
#
# $1: file containing the list of items to extract
# $2: path to extracted radio folder
#
function extract_firmware() {
    if [ -z "$OUTDIR" ]; then
        echo "Output dir not set!"
        exit 1
    fi

    parse_file_list "$1"

    # Don't allow failing
    set -e

    local FILELIST=( ${PRODUCT_COPY_FILES_LIST[@]} )
    local COUNT=${#FILELIST[@]}
    local SRC="$2"
    local OUTPUT_DIR="$LINEAGE_ROOT"/"$OUTDIR"/radio

    if [ "$VENDOR_RADIO_STATE" -eq "0" ]; then
        echo "Cleaning firmware output directory ($OUTPUT_DIR).."
        rm -rf "${OUTPUT_DIR:?}/"*
        VENDOR_RADIO_STATE=1
    fi

    echo "Extracting $COUNT files in $1 from $SRC:"

    for (( i=1; i<COUNT+1; i++ )); do
        local FILE="${FILELIST[$i-1]}"
        printf '  - %s \n' "/radio/$FILE"

        if [ ! -d "$OUTPUT_DIR" ]; then
            mkdir -p "$OUTPUT_DIR"
        fi
        cp "$SRC/$FILE" "$OUTPUT_DIR/$FILE"
        chmod 644 "$OUTPUT_DIR/$FILE"
    done
}

function extract_img_data() {
    local image_file="$1"
    local out_dir="$2"
    local logFile="$TMPDIR/debugfs.log"

    if [ ! -d "$out_dir" ]; then
        mkdir -p "$out_dir"
    fi

    if [[ "$HOST_OS" == "Darwin" ]]; then
        debugfs -R "rdump / \"$out_dir\"" "$image_file" &> "$logFile" || {
            echo "[-] Failed to extract data from '$image_file'"
            abort 1
        }
    else
        debugfs -R 'ls -p' "$image_file" 2>/dev/null | cut -d '/' -f6 | while read -r entry
        do
            debugfs -R "rdump \"$entry\" \"$out_dir\"" "$image_file" >> "$logFile" 2>&1 || {
                echo "[-] Failed to extract data from '$image_file'"
                abort 1
            }
        done
    fi

    local symlink_err="rdump: Attempt to read block from filesystem resulted in short read while reading symlink"
    if grep -Fq "$symlink_err" "$logFile"; then
        echo "[-] Symlinks have not been properly processed from $image_file"
        echo "[!] If you don't have a compatible debugfs version, modify 'execute-all.sh' to disable 'USE_DEBUGFS' flag"
        abort 1
    fi
}

declare -ra VENDOR_SKIP_FILES=(
  "bin/toybox_vendor"
  "bin/toolbox"
  "bin/grep"
  "build.prop"
  "compatibility_matrix.xml"
  "default.prop"
  "etc/NOTICE.xml.gz"
  "etc/vintf/compatibility_matrix.xml"
  "etc/vintf/manifest.xml"
  "etc/wifi/wpa_supplicant.conf"
  "manifest.xml"
  "overlay/DisplayCutoutEmulationCorner/DisplayCutoutEmulationCornerOverlay.apk"
  "overlay/DisplayCutoutEmulationDouble/DisplayCutoutEmulationDoubleOverlay.apk"
  "overlay/DisplayCutoutEmulationTall/DisplayCutoutEmulationTallOverlay.apk"
  "overlay/DisplayCutoutNoCutout/NoCutoutOverlay.apk"
  "overlay/framework-res__auto_generated_rro.apk"
  "overlay/SysuiDarkTheme/SysuiDarkThemeOverlay.apk"
)

function array_contains() {
    local element
    for element in "${@:2}"; do [[ "$element" == "$1" ]] && return 0; done
    return 1
}

function generate_prop_list_from_image() {
    local image_file="$1"
    local image_dir="$TMPDIR/image-temp"
    local output_list="$2"
    local output_list_tmp="$TMPDIR/_proprietary-blobs.txt"
    local -n skipped_vendor_files="$3"

    extract_img_data "$image_file" "$image_dir"

    find "$image_dir" -not -type d | sed "s#^$image_dir/##" | while read -r FILE
    do
        # Skip VENDOR_SKIP_FILES since it will be re-generated at build time
        if array_contains "$FILE" "${VENDOR_SKIP_FILES[@]}"; then
            continue
        fi
        # Skip device defined skipped files since they will be re-generated at build time
        if array_contains "$FILE" "${skipped_vendor_files[@]}"; then
            continue
        fi
        if suffix_match_file ".apk" "$FILE" ; then
            echo "-vendor/$FILE" >> "$output_list_tmp"
        else
            echo "vendor/$FILE" >> "$output_list_tmp"
        fi
    done

    # Sort merged file with all lists
    sort -u "$output_list_tmp" > "$output_list"

    # Clean-up
    rm -f "$output_list_tmp"
}
