#!/bin/bash
# Automatic setup photobooth and DietPi
# @maxmlr

# Source photobooth config
source /boot/photobooth.conf

# Install RaspAP WiFi AccessPoint Manager
/boot/install/setup-raspap.sh

# setup access point
# deprecated: /boot/install/setup-wifi-ap.sh -a photobooth "" -u photobooth
apt -y update && \
apt install -y \
    gphoto2 \
    cups \
    chromium-browser \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    unclutter \
    mosquitto-clients \
    xdotool

# optional: if photobooth should be build from source, uncomment the next command.
# note: if the python uinput library should be used for remote trigger (send key_press)
# only build-essential is required.
# curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
# echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# apt install -y yarn build-essential

# Configure managed services
cat /boot/config/dietpi-services_include_exclude >> /DietPi/dietpi/.dietpi-services_include_exclude

# Edit /DietPi/config.txt:
# - set HDMI monitor resolution
[[ -z "$HDMI_OUT" ]] || echo "$HDMI_OUT" >> /DietPi/config.txt
# - enable Pi Camera
sed -i -e 's/#start_x=1/start_x=1/g' /DietPi/config.txt

# install required Python 3 modules
# TODO change to pip3 
pip3 install paho-mqtt gpiozero
# if the python uinput library should be used for remote trigger (send key_press),
# uncomment the following commands:
# pip install python-uinput
# echo 'uinput' | tee -a /etc/modules

# create lighttpd webroot directory
mkdir -p /var/www/html

# move lighttpd default files
mkdir /var/www/admin && mv /var/www/*.php /var/www/*.html -t /var/www/admin

# create self signed ssl certificates
cd /etc/lighttpd
openssl req -x509 -nodes -new -sha256 -days 365 -newkey rsa:2048 \
    -keyout server.pem -out server.pem \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=photobooth"
chmod 400 server.pem
lighty-enable-mod ssl
cd ~/

# install photobooth
echo "Installing photobooth"
cd /var/www/html
wget -O photobooth.tar.gz https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth.tar.gz && rm photobooth.tar.gz
wget -O photobooth_update.tar.gz https://github.com/maxmlr/photobooth/archive/v${PHOTOBOOTH_UPDATE}.tar.gz && tar xzf photobooth_update.tar.gz && rm photobooth_update.tar.gz
cp -r photobooth-${PHOTOBOOTH_UPDATE}/. . && rm -rf photobooth-${PHOTOBOOTH_UPDATE}/
# optional: if photobooth should be build from source, uncomment:
# PHOTOBOOTH_RELEASE="build-latest"
# cd /var/www/ && rm -rf html
# git clone https://github.com/maxmlr/photobooth html
# cd /var/www/html
# git submodule update --init
# rm yarn.lock
# yarn install
# yarn build
echo "v${PHOTOBOOTH_RELEASE} [${PHOTOBOOTH_UPDATE}]" > /var/www/html/version.html
chown -R www-data:www-data /var/www/
cd -

# photobooth config
cp /boot/config/photobooth.webinterface.php /var/www/html/config/my.config.inc.php
chown -R www-data:www-data /var/www/html/config/my.config.inc.php

# Pi Camera setup - not required for dietpi
#echo "bcm2835-v4l2" >> /etc/modules'
 
# access to USB device and printer and Pi Camera
gpasswd -a www-data plugdev
gpasswd -a www-data lp
gpasswd -a www-data lpadmin
gpasswd -a www-data video

# change www root in /etc/lighttpd/lighttpd.conf
sed -i -e 's/\/var\/www/\/var\/www\/html/g' /etc/lighttpd/lighttpd.conf

# install mqtt-launcher
cd /opt && git clone https://github.com/maxmlr/mqtt-launcher.git
cp /boot/config/photobooth.mqtt.conf /opt/mqtt-launcher/launcher.photobooth.conf
chmod +x /opt/mqtt-launcher/mqtt-launcher.py
cd -

# chromium settings
# TODO check if required
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /root/.config/chromium/Default/Preferences
#sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /root/.config/chromium/Default/Preferences

# add xorg settings
cp /boot/config/xinitrc /root/.xinitrc

# Add /var/lib/dietpi/dietpi-autostart/custom.sh
cp /boot/scripts/dietpi-custom.sh /var/lib/dietpi/dietpi-autostart/custom.sh

# Add photobooth kiosk autostart postboot service
cp /boot/scripts/start-kiosk.sh /var/lib/dietpi/postboot.d/20-start-kiosk.sh

# Add manual timesync postboot service
cp /boot/scripts/timesync.sh /var/lib/dietpi/postboot.d/30-timesync.sh

# Services
systemctl disable hostapd.service

# Copy binaries to /usr/bin
for binary in /boot/binaries/*.sh; do cp $binary /usr/bin/`basename $binary .sh`; chmod +x /usr/bin/`basename $binary .sh`; done

# Copy python scripts to /opt/photobooth/python
mkdir -p /opt/photobooth/python
for pyscript in /boot/scripts/*.py; do cp $pyscript /opt/photobooth/python/`basename $pyscript .py`; chmod +x /opt/photobooth/python/`basename $pyscript .py`; done

# Add sudo permissions
bash -c 'cat > /etc/sudoers.d/raspap' << EOF
www-data ALL=(ALL) NOPASSWD:/usr/bin/gpio
www-data ALL=(ALL) NOPASSWD:/usr/bin/relay
EOF

# Optimizations
sed -i -e 's/CONFIG_NTP_MODE=.*/CONFIG_NTP_MODE=0/g' /DietPi/dietpi.txt

# Cleanup
apt-get clean
apt-get autoremove -y
