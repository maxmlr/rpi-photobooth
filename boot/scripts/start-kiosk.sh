#!/bin/bash
# photobooth kiosk service

source /boot/photobooth.conf

echo "Photobooth v${PHOTOBOOTH_RELEASE}"
startx /root/.xinitrc
