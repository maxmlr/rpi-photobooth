#!/bin/bash
# photobooth kiosk service

source /boot/photobooth.conf

if [[ "$BOOT_TO_KIOSK" -eq 1 ]] || [[ "$KIOSK_ENABLED" -eq 1 ]]
then
    echo "Photobooth v${PHOTOBOOTH_RELEASE}"
    startx /root/.xinitrc
else
    echo "Kiosk mode disabled via config file (/boot/photobooth.conf)."
fi
