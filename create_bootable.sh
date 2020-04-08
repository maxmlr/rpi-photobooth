#!/bin/bash

MOUNT_POINT=/Volumes/boot
GIT_REPOSITORY_SERVER=https://github.com/maxmlr/rpi-photobooth.git
GIT_REPOSITORY_CLIENT=https://github.com/maxmlr/rpi-photobooth-client.git

dietpi=${1}
git=${2:-'server'}
wifi_config=${3}
photobooth_config=${4}
device=`mount | grep ${MOUNT_POINT} | cut -d" " -f1`

if [[ $git =~ ^server$ ]]
then
    echo "Installing Photobooth Server [latest]"
elif [[ $git =~ ^client$ ]]
then
    echo "Installing Photobooth Client [latest]"
else
    echo "Installing local repository [${git}]"
fi

create_sd () {
    sd_card=$1
    mountpoint=$2
    repo=/tmp/rpi-photobooth
    if [[ $git =~ ^server$ ]]
    then
        echo "Cloning server repository..."
        git clone ${GIT_REPOSITORY_SERVER} ${repo}
    elif [[ $git =~ ^client$ ]]
    then
        echo "Cloning client repository..."
        git clone ${GIT_REPOSITORY_CLIENT} ${repo}
    else
        repo="${git}"
    fi
    diskutil umount ${mountpoint}
    echo "Writing image `basename ${dietpi}` to [${sd_card}]"
    sudo dd \
        if="${dietpi}" \
        of="${sd_card}" bs=1m
    sleep 5
    cp -rf "${repo}"/boot/* ${mountpoint}
    if [ ! -z ${wifi_config+x} ]
    then
        echo "Copying user defined wifi config: ${wifi_config}"
        cp -f ${wifi_config} ${mountpoint}
    else
        echo "Using default wifi config"
    fi
    if [ ! -z ${photobooth_config+x} ]
    then
        echo "Copying user defined photobooth config: ${photobooth_config}"
        cp -f ${photobooth_config} ${mountpoint}
    else
        echo "Using default photobooth config"
    fi
    echo "Unmounting..."
    diskutil umount ${mountpoint}
    echo "Done."
}
if [ -z ${device+x} ]
then
    read -r -n 1 -p "Formatting device ${device} [`mount | grep ${MOUNT_POINT}`] [Y/n]? "
fi

if [[ $REPLY =~ ^[Yy]$ ]]
then
    create_sd "${device}" "${MOUNT_POINT}"
else
    if [ -z ${device+x} ]
    then
        read -r -p "Enter absolute path of mount point: " MOUNT_POINT
        read -r -n 1 -p "Formatting device ${device} [`mount | grep ${MOUNT_POINT}`] [Y/n]? "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            create_sd "${device}" "${MOUNT_POINT}"
        else
            echo "Aborted."
        fi
    else
        read -r -p "Enter device: " device
        read -r -n 1 -p "Formatting device ${device} [Y/n]? "
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            create_sd "${device}" "${MOUNT_POINT}"
        else
            echo "Aborted."
        fi
    fi
fi
