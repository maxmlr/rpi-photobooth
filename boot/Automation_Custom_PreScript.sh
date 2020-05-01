#!/bin/bash
# Custom pre setup photobooth and DietPi
# @maxmlr

# Set device id and model in photobooth.conf
echo "DEVICE_ID=\"`cat /proc/cpuinfo | grep --ignore-case serial | cut -d ":" -f2 | sed -e 's/^[[:space:]]*//'`\"" >> /boot/photobooth.conf 
echo "DEVICE_MODEL=\"`cat /proc/cpuinfo | grep Model | cut -d ":" -f2 | sed -e 's/^[[:space:]]*//'`\"" >> /boot/photobooth.conf
echo "DEVICE_TYPE=\"server\"" >> /boot/photobooth.conf

source /boot/photobooth.conf

# Set uniue hostname in dietpi.txt
[[ -f /boot/dietpi.txt ]] && sed -i -e s"|AUTO_SETUP_NET_HOSTNAME=.*|AUTO_SETUP_NET_HOSTNAME=photobooth-${DEVICE_TYPE::1}${DEVICE_ID:(-8)}|g" /boot/dietpi.txt
[[ -f /DietPi/dietpi.txt ]] && sed -i -e s"|AUTO_SETUP_NET_HOSTNAME=.*|AUTO_SETUP_NET_HOSTNAME=photobooth-${DEVICE_TYPE::1}${DEVICE_ID:(-8)}|g" /DietPi/dietpi.txt

# Replace brcmfmac driver
# fixes WiFi freezes; references:
# https://github.com/raspberrypi/linux/issues/2453#issuecomment-610206733
# https://community.cypress.com/docs/DOC-19375
# https://community.cypress.com/servlet/JiveServlet/download/19375-1-53475/cypress-fmac-v5.4.18-2020_0402.zip
# mv /lib/firmware/brcm/brcmfmac43455-sdio.bin /lib/firmware/brcm/brcmfmac43455-sdio.bin~
# mv /lib/firmware/brcm/brcmfmac43455-sdio.clm_blob /lib/firmware/brcm/brcmfmac43455-sdio.clm_blob~
# cp /boot/firmware/wifi/brcmfmac43455-sdio.bin /lib/firmware/brcm/
# cp /boot/firmware/wifi/brcmfmac43455-sdio.clm_blob /lib/firmware/brcm/

# Enable eth0
sed -i -e 's|#*allow-hotplug eth0|allow-hotplug eth0|' /etc/network/interfaces
ifup eth0 &>/dev/null
