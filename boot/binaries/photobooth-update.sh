#!/bin/bash

ACTION=${1:-"rpi-photobooth"}
PHOTOBOOTH_RELEASE=$2
PHOTOBOOTH_UPDATE=$3

echo "Downloading current rpi-photobooth..."
cd /tmp
[ -d "/tmp/rpi-photobooth" ] && rm -rf /tmp/rpi-photobooth
git clone https://github.com/maxmlr/rpi-photobooth.git
find /tmp/rpi-photobooth/boot -maxdepth 1 -not -iname '*.txt' -not -iname "*.conf" -exec cp -rf '{}' /boot \;
[ -e "/tmp/rpi-photobooth/release-notes.txt" ] && \
    cp /tmp/rpi-photobooth/release-notes.txt /boot/release-notes.txt && \
    cat /boot/release-notes.txt && \
    echo
echo "Release notes can be found at: /boot/release-notes.txt"
echo
rm -rf /tmp/rpi-photobooth
cd -

# TODO merge /boot/photobooth.conf

# Source photobooth config
source /boot/photobooth.conf

# Run update depending on specified action
[[ "$ACTION" == "rpi-photobooth" ]] && echo "Updating rpi-photobooth base system..." && /boot/update/rpi-photobooth.sh
[[ "$ACTION" == "photobooth-web" ]] && echo "Updating rpi-photobooth base system..." && /boot/update/photobooth-web.sh $PHOTOBOOTH_RELEASE $PHOTOBOOTH_UPDATE
[[ "$ACTION" == "raspap.sh" ]] && echo "Updating rpi-photobooth base system..." && /boot/update/raspap.sh

# Cleanup
#...

# Reboot
read -p "-> Press enter to reboot <-"
echo "Rebooting now..." && reboot
