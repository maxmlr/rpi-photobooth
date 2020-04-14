#!/bin/bash

ACTION=${1:-"rpi-photobooth"}
PHOTOBOOTH_RELEASE=$2
PHOTOBOOTH_UPDATE=$3

echo "Downloading current rpi-photobooth..."
cd /tmp
[ -d "/tmp/rpi-photobooth" ] && rm -rf /tmp/rpi-photobooth
git clone https://github.com/maxmlr/rpi-photobooth.git
find /tmp/rpi-photobooth/boot -maxdepth 1 -not -iname '*.txt' -not -iname "*.conf" -exec cp -rf '{}' /boot \;
cp -f /tmp/rpi-photobooth/boot/requirements.txt /boot
cp -f /tmp/rpi-photobooth/boot/photobooth.conf /tmp
[ -e "/tmp/rpi-photobooth/release-notes.txt" ] && \
    cp /tmp/rpi-photobooth/release-notes.txt /boot/release-notes.txt && \
    cat /boot/release-notes.txt && \
    echo
echo "Release notes can be found at: /boot/release-notes.txt"
echo
rm -rf /tmp/rpi-photobooth
cd - > /dev/null 

# Source photobooth config
source /boot/photobooth.conf

# Run update depending on specified action
[[ "$ACTION" == "rpi-photobooth" ]] && echo "Updating base system..." && /boot/update/rpi-photobooth.sh
[[ "$ACTION" == "photobooth-web" ]] && echo "Updating photobooth ..." && /boot/update/photobooth-web.sh $PHOTOBOOTH_RELEASE $PHOTOBOOTH_UPDATE

# Cleanup
#...

# TODO merge /boot/photobooth.conf
echo "Please manually update your config file: /boot/photobooth.conf with changes in /tmp/photobooth.conf:"
diff /tmp/photobooth.conf /boot/photobooth.conf

# Reboot
echo
read -p "-> Press enter to reboot <-"
echo "Rebooting now..." && reboot
