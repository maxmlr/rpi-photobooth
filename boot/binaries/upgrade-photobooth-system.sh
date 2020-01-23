#!/bin/bash

echo "Downloading current rpi-photobooth..."
cd /tmp
[ -d "/tmp/rpi-photobooth" ] && rm -rf /tmp/rpi-photobooth
git clone https://github.com/maxmlr/rpi-photobooth.git
find /tmp/rpi-photobooth/boot -maxdepth 1 -not -iname '*.txt' -exec cp -rf '{}' /boot \;
[ -e "/tmp/rpi-photobooth/release-notes.txt" ] && \
    cp /tmp/rpi-photobooth/release-notes.txt /boot/release-notes.txt && \
    cat /boot/release-notes.txt && \
    echo
echo "Release notes were also save at: /boot/release-notes.txt"
echo
rm -rf /tmp/rpi-photobooth
cd -

echo "Upgrading rpi-photobooth base system (reboot required)..."
source /boot/photobooth.conf

# TODO update RaspAP ?

# TODO update photobooth web-interface ?

# TODO update managed services

# TODO update /DietPi/config.txt

# TODO update python modules

# TODO update lighttpd

# TODO update mqtt-launcher

# TODO update xorg settings

# TODO update /var/lib/dietpi/dietpi-autostart/custom.sh

# TODO update /var/lib/dietpi/postboot.d/

# TODO update systemctl services

# TODO update /DietPi/dietpi.txt

# Cleanup

# Reboot
read -p "-> Press enter to reboot <-"
echo "Rebooting now..." && reboot
