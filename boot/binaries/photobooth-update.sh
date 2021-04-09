#!/bin/bash

ACTION=${1:-"rpi-photobooth"}
PHOTOBOOTH_RELEASE=$2

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

if [[ "$DEVICE_TYPE" = "client" ]]; then
cd /tmp
[ -d "/tmp/rpi-photobooth-client" ] && rm -rf /tmp/rpi-photobooth-client
git clone https://github.com/maxmlr/rpi-photobooth-client.git
find /tmp/rpi-photobooth-client/boot -maxdepth 1 -not -iname '*.txt' -not -iname "*.conf" -exec cp -rf '{}' /boot \;
cp -f /tmp/rpi-photobooth-client/boot/requirements.txt /boot
cp -f /tmp/rpi-photobooth-client/boot/photobooth.conf /tmp
rm -rf /tmp/rpi-photobooth-client
cd - > /dev/null 
fi

# Run update depending on specified action
[[ "$ACTION" == "rpi-photobooth" ]] && echo "Updating base system..." && /boot/update/rpi-photobooth.sh
[[ "$ACTION" == "photobooth-web" ]] && echo "Updating photobooth ..." && /boot/update/photobooth-web.sh $PHOTOBOOTH_RELEASE

# customize banner
sed -i -e 's|aENABLED\[1\]=[0,1]|aENABLED\[1\]=1|' /boot/dietpi/.dietpi-banner
sed -i -e 's|aENABLED\[3\]=[0,1]|aENABLED\[3\]=1|' /boot/dietpi/.dietpi-banner
sed -i -e 's|aENABLED\[7\]=[0,1]|aENABLED\[7\]=1|' /boot/dietpi/.dietpi-banner
sed -i -e 's|aENABLED\[10\]=[0,1]|aENABLED\[10\]=1|' /boot/dietpi/.dietpi-banner
sed -i -e 's|aDESCRIPTION\[10\]=.*|aDESCRIPTION\[10\]="Photobooth"|' /boot/dietpi/.dietpi-banner
sed -i -e 's|aENABLED\[11\]=[0,1]|aENABLED\[11\]=0|' /boot/dietpi/.dietpi-banner
sed -i -e 's|aENABLED\[12\]=[0,1]|aENABLED\[12\]=0|' /boot/dietpi/.dietpi-banner
echo "photobooth-status banner" > /boot/dietpi/.dietpi-banner_custom

# Cleanup
#...

# TODO merge /boot/photobooth.conf
echo "Please manually update your config file: /boot/photobooth.conf with changes in /tmp/photobooth.conf:"
diff /tmp/photobooth.conf /boot/photobooth.conf

# Reboot
echo
read -p "-> Press enter to reboot <-"
echo
echo "Rebooting now..." && reboot
echo
