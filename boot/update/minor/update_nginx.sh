#!/bin/bash

# install rsync
apt install rsync

# edit photobooth.conf
echo "BOOT_TO_KIOSK=1" >> /boot/photobooth.conf

# get updates
wget -O /root/.xinitrc https://raw.githubusercontent.com/maxmlr/rpi-photobooth/master/boot/config/xinitrc
wget -O /opt/photobooth/bin/start_kiosk.sh https://raw.githubusercontent.com/maxmlr/rpi-photobooth/master/boot/scripts/start-kiosk.sh
wget -O /etc/nginx/sites-dietpi/photobooth-manager.conf https://raw.githubusercontent.com/maxmlr/rpi-photobooth/master/boot/config/nginx-photobooth-manager.conf

# get web update
/boot/update/photobooth-web.sh "2.1.0" "2.1.0"

# restart nginx
systemctl restart nginx.service

# disable php cache
mv /etc/php/7.3/mods-available/apcu.ini /etc/php/7.3/mods-available/apcu.ini~ && \
mv /etc/php/7.3/mods-available/opcache.ini /etc/php/7.3/mods-available/opcache.ini~ && \
systemctl restart php7.3-fpm.service
