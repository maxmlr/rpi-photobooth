#!/bin/bash
# photobooth auto startup

source /boot/photobooth.conf

echo
echo --- RPI-photobooth ---
echo

echo "Starting mosquito server with topic photobox/#"
HOME=/root mosquitto_sub -v -t 'photobox/#' & sleep 3
echo "Starting mqtt-launcher [/opt/mqtt-launcher/launcher.photobooth.conf]"
MQTTLAUNCHERCONFIG=/opt/mqtt-launcher/launcher.photobooth.conf /opt/mqtt-launcher/mqtt-launcher.py &
echo "Starting chromium browser in kiosk mode for photobooth app (v${PHOTOBOOTH_RELEASE})"
startx /root/.xinitrc &
