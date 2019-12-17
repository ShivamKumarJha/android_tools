#!/bin/bash

# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2019 Shivam Kumar Jha <jha.shivam3@gmail.com>
#
# Helper functions

# Store project path
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null && pwd )"

# Common stuff
source ${PROJECT_DIR}/helpers/common_script.sh

# Arguements check
if [ -z ${1} ] || [ -z ${2} ] || [ -z ${3} ]; then
    echo -e "Usage: bash rebase_kernel.sh <kernel zip link/file> <repo name> <tag suffix>"
    exit 1
fi

# Download compressed kernel source
if [[ "$1" == *"http"* ]]; then
    URL=${1}
    dlrom
else
    URL=$( realpath "$1" )
    echo "Copying file"
    cp -a ${1} ${PROJECT_DIR}/input/
fi
FILE=${URL##*/}
EXTENSION=${URL##*.}
UNZIP_DIR=${FILE/.$EXTENSION/}
[[ -d ${PROJECT_DIR}/kernels/${UNZIP_DIR} ]] && rm -rf ${PROJECT_DIR}/kernels/${UNZIP_DIR}

# Extract file
echo "Extracting file"
mkdir -p ${PROJECT_DIR}/kernels/${UNZIP_DIR}
7z x ${PROJECT_DIR}/input/${FILE} -y -o${PROJECT_DIR}/kernels/${UNZIP_DIR} > /dev/null 2>&1
NEST="$( find ${PROJECT_DIR}/kernels/${UNZIP_DIR} -type f -size +50M \( -name "*.rar*" -o -name "*.zip*" -o -name "*.tar*" \) -printf '%P\n' | head -1)"
if [ ! -z ${NEST} ]; then
    bash ${PROJECT_DIR}/tools/rebase_kernel.sh ${PROJECT_DIR}/kernels/${UNZIP_DIR}/${NEST} ${2} ${3}
    exit
fi
KERNEL_DIR="$(dirname "$(find ${PROJECT_DIR}/kernels/${UNZIP_DIR} -type f -name "AndroidKernel.mk" | head -1)")"
cd ${KERNEL_DIR}

# Find kernel version
KERNEL_VERSION="$( cat Makefile | grep VERSION | head -n 1 | sed "s|.*=||1" | sed "s| ||g" )"
KERNEL_PATCHLEVEL="$( cat Makefile | grep PATCHLEVEL | head -n 1 | sed "s|.*=||1" | sed "s| ||g" )"
[[ -z "$KERNEL_VERSION" ]] && echo -e "Error!" && exit 1
[[ -z "$KERNEL_PATCHLEVEL" ]] && echo -e "Error!" && exit 1
echo "${KERNEL_VERSION}.${KERNEL_PATCHLEVEL}"

# Create release branch
echo "Creating release branch"
git init -q
git config core.fileMode false
git checkout -b release -q
[[ -d "audio-kernel/" ]] && mkdir -p techpack/ && mv audio-kernel/ techpack/audio
[[ -d "techpack/audio" ]] && HAS_AUDIO_KERNEL="y"
git add --all > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "OEM Release" > /dev/null 2>&1

# Find best CAF TAG
git remote add msm https://source.codeaurora.org/quic/la/kernel/msm-${KERNEL_VERSION}.${KERNEL_PATCHLEVEL}
echo "Fetching tags ending with $3"
git fetch msm "refs/tags/*$3:refs/tags/*$3" > /dev/null 2>&1
echo "Finding best CAF base"
cp -a ${PROJECT_DIR}/helpers/best-caf-kernel.py ${KERNEL_DIR}/best-caf-kernel.py
CAF_TAG="$(python ${KERNEL_DIR}/best-caf-kernel.py "*$3" )"
[[ -z "$CAF_TAG" ]] && echo -e "Error!" && exit 1
echo ${CAF_TAG}
rm -rf ${KERNEL_DIR}/best-caf-kernel.py

# Rebase to best CAF tag
git checkout -q "refs/tags/${CAF_TAG}" -b "release-${CAF_TAG}"

# techpack/audio subtree
if [[ ${HAS_AUDIO_KERNEL} == "y" ]]; then
    echo "Adding techpack/audio subtree"
    git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" subtree add --prefix techpack/audio git://codeaurora.org/platform/vendor/opensource/audio-kernel/ ${CAF_TAG} > /dev/null 2>&1
fi

# Apply OEM modifications
echo "Applying OEM modifications"
git diff "release-${CAF_TAG}" release | git apply --reject > /dev/null 2>&1
# dtsi
[[ -d "arch/arm/boot/dts" ]] && git add "arch/arm/boot/dts" > /dev/null 2>&1
[[ -d "arch/arm64/boot/dts" ]] && git add "arch/arm64/boot/dts" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add dtsi modifications" > /dev/null 2>&1
# defconfig
[[ -d "arch/arm/configs/" ]] && git add "arch/arm/configs/" > /dev/null 2>&1
[[ -d "arch/arm64/configs/" ]] && git add "arch/arm64/configs/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add defconfig modifications" > /dev/null 2>&1
# Remaining arch
[[ -d "arch/" ]] && git add "arch/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add remaining arch modifications" > /dev/null 2>&1
# block
[[ -d "block/" ]] && git add "block/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add block modifications" > /dev/null 2>&1
# crypto
[[ -d "crypto/" ]] && git add "crypto/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add crypto modifications" > /dev/null 2>&1
# binder
[[ -d "drivers/android/" ]] && git add "drivers/android/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add binder modifications" > /dev/null 2>&1
# base
[[ -d "drivers/base/" ]] && git add "drivers/base/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add drivers/base modifications" > /dev/null 2>&1
# block
[[ -d "drivers/block/" ]] && git add "drivers/block/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add drivers/block modifications" > /dev/null 2>&1
# camera
[[ -d "drivers/media/platform/msm/" ]] && git add "drivers/media/platform/msm/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add camera modifications" > /dev/null 2>&1
# char
[[ -d "drivers/char/" ]] && git add "drivers/char/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add drivers/char modifications" > /dev/null 2>&1
# clk
[[ -d "drivers/clk/" ]] && git add "drivers/clk/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add drivers/clk modifications" > /dev/null 2>&1
# DRM
[[ -d "drivers/gpu/drm/" ]] && git add "drivers/gpu/drm/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add DRM modifications" > /dev/null 2>&1
# GPU
[[ -d "drivers/gpu/" ]] && git add "drivers/gpu/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add GPU modifications" > /dev/null 2>&1
# touchscreen
[[ -d "drivers/input/touchscreen/" ]] && git add "drivers/input/touchscreen/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add touchscreen modifications" > /dev/null 2>&1
# input
[[ -d "drivers/input/" ]] && git add "drivers/input/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add input modifications" > /dev/null 2>&1
# LEDs
[[ -d "drivers/leds/" ]] && git add "drivers/leds/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add LEDs modifications" > /dev/null 2>&1
# mmc
[[ -d "drivers/mmc/" ]] && git add "drivers/mmc/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add mmc modifications" > /dev/null 2>&1
# NFC
[[ -d "drivers/nfc/" ]] && git add "drivers/nfc/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add NFC modifications" > /dev/null 2>&1
# power
[[ -d "drivers/power/" ]] && git add "drivers/power/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add Power modifications" > /dev/null 2>&1
# scsi
[[ -d "drivers/scsi/" ]] && git add "drivers/scsi/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add scsi modifications" > /dev/null 2>&1
# soc
[[ -d "drivers/soc/" ]] && git add "drivers/soc/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add soc modifications" > /dev/null 2>&1
# thermal
[[ -d "drivers/thermal/" ]] && git add "drivers/thermal/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add thermal modifications" > /dev/null 2>&1
# USB
[[ -d "drivers/usb/" ]] && git add "drivers/usb/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add USB modifications" > /dev/null 2>&1
# Remaining drivers
[[ -d "drivers/" ]] && git add "drivers/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add remaining drivers modifications" > /dev/null 2>&1
# FS
[[ -d "fs/" ]] && git add "fs/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add FS modifications" > /dev/null 2>&1
# Headers
[[ -d "include/" ]] && git add "include/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add Headers modifications" > /dev/null 2>&1
# kernel/
[[ -d "kernel/" ]] && git add "kernel/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add kernel/ modifications" > /dev/null 2>&1
# mm/
[[ -d "mm/" ]] && git add "mm/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add mm/ modifications" > /dev/null 2>&1
# net/
[[ -d "net/" ]] && git add "net/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add net/ modifications" > /dev/null 2>&1
# security/
[[ -d "security/" ]] && git add "security/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add security modifications" > /dev/null 2>&1
# sound/
[[ -d "sound/" ]] && git add "sound/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add sound modifications" > /dev/null 2>&1
# techpack/
[[ -d "techpack/" ]] && git add "techpack/" > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add techpack modifications" > /dev/null 2>&1
# Remaining OEM modifications
git add --all > /dev/null 2>&1
git -c "user.name=ShivamKumarJha" -c "user.email=jha.shivam3@gmail.com" commit -sm "Add remaining OEM modifications" > /dev/null 2>&1

# Push to GitHub
if [[ ${ORGMEMBER} == "y" ]] && [[ ! -z ${GIT_TOKEN} ]]; then
    echo "Pushing to GitHub"
    curl -s -X POST -H "Authorization: token ${GIT_TOKEN}" -d '{"name": "'"$2"'","description": "'"CAF Rebased kernel source"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' "https://api.github.com/orgs/AndroidBlobs/repos" > /dev/null 2>&1
    git push https://"$GIT_TOKEN"@github.com/AndroidBlobs/"$2".git --all --force > /dev/null 2>&1
elif [[ ! -z ${GITHUB_USER} ]] && [[ ! -z ${GIT_TOKEN} ]]; then
    echo "Pushing to GitHub"
    curl https://api.github.com/user/repos\?access_token=$GIT_TOKEN -d '{"name": "'"$2"'","description": "'"CAF Rebased kernel source"'","private": false,"has_issues": true,"has_projects": false,"has_wiki": true}' > /dev/null 2>&1
    git push https://"$GIT_TOKEN"@github.com/"$GITHUB_USER"/"$2".git --all --force > /dev/null 2>&1
fi

# Telegram
if [ ! -z ${GIT_TOKEN} ] && [ ! -z ${TG_API} ] && [[ ${ORGMEMBER} == "y" ]]; then
    printf "<b>Repo: $2</b>" > ${PROJECT_DIR}/working/tg.html
    printf "\n<b>Base CAF tag: $CAF_TAG</b>" >> ${PROJECT_DIR}/working/tg.html
    printf "\n<b>Kernel: ${KERNEL_VERSION}.${KERNEL_PATCHLEVEL}</b>" >> ${PROJECT_DIR}/working/tg.html
    [[ "$1" == *"http"* ]] && printf "\n<a href=\"$1\">Kernel source</a>" >> ${PROJECT_DIR}/working/tg.html
    printf "\n<a href=\"https://github.com/AndroidBlobs/$2/\">Kernel tree</a>" >> ${PROJECT_DIR}/working/tg.html
    CHAT_ID="@dummy_dt"
    HTML_FILE=$(cat ${PROJECT_DIR}/working/tg.html)
    curl -s "https://api.telegram.org/bot${TG_API}/sendmessage" --data "text=${HTML_FILE}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" > /dev/null 2>&1
fi
