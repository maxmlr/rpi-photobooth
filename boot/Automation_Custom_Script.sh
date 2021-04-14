#!/bin/bash
# Automatic setup photobooth and DietPi
# @maxmlr

BEGIN=$(date +%s)

# source photobooth config
source /boot/photobooth.conf

# copy public key
cp -f /boot/authorized_keys /root/.ssh/authorized_keys

# setup WiFi AccessPoint
/boot/install/setup_wifi_ap.sh
chmod go+r /etc/wpa_supplicant/wpa_supplicant.conf
mkdir -p /opt/photobooth/conf
cp -rf /boot/config/wifi/* /opt/photobooth/conf
ln -s /boot/install/install-dongle.sh /usr/local/bin/install-dongle

# install dependencies
apt -y update && \
apt install -y \
    build-essential \
    libmicrohttpd-dev \
    iptables \
    python3-dev \
    python3-venv \
    gphoto2 \
    cups \
    chromium-browser \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    unclutter \
    mosquitto-clients \
    xdotool \
    rsync \
    qrencode \
    jq \
    mosh \
    imagemagick \
    sqlite3 \
    libsqlite3-dev \
    libatlas-base-dev

# optional: if photobooth should be build from source, uncomment the next command.
# note: if the python uinput library should be used for remote trigger (send key_press)
# only build-essential is required.
# curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
# echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# apt install -y yarn build-essential

# Configure managed services
cat /boot/config/dietpi-services_include_exclude >> /boot/dietpi/.dietpi-services_include_exclude

# Edit /boot/config.txt:
# - merge configs from photobooth.conf
for config in "${DIETPI_CONFIG[@]}"
do
    key=`echo "$config" | cut -d"=" -f1 | sed -e s"|\#||g"`
    if tac /boot/config.txt | grep -m1 -q "$key"; then
        config_old=`tac /boot/config.txt | grep -m1 "$key"`
        if [[ "$config" = "$config_old" ]]
        then
            echo "[config] no change: $key"
        else
            update_msg+=( "[config] update - old: `tac /boot/config.txt | grep -m1 "$key"` -> new: $config" )
            tac /boot/config.txt | sed "/$key/ {s/.*/$config/; :loop; n; b loop}" | tac > /tmp/config.txt
            mv /tmp/config.txt /boot/config.txt
        fi
    else
        echo "[config] new: $config"
        echo "$config"  >> /boot/config.txt
    fi
done
# - enable Pi Camera
sed -i -e 's/#start_x=1/start_x=1/g' /boot/config.txt
# - adjust memory split
if [ "$HEADLESS" -eq "0" ]; then
    sed -i -e 's/gpu_mem_256=.*/gpu_mem_256=64/g' /boot/config.txt 
    sed -i -e 's/gpu_mem_512=.*/gpu_mem_512=128/g' /boot/config.txt 
    sed -i -e 's/gpu_mem_1024=.*/gpu_mem_1024=256/g' /boot/config.txt 
fi

# install required Python 3 modules
pip3 install --upgrade pip && \
 pip3 install --trusted-host pypi.python.org -r /boot/requirements.txt

# if the python uinput library should be used for remote trigger (send key_press),
# uncomment the following commands:
# pip install python-uinput
# echo 'uinput' | tee -a /etc/modules

# install flask
mkdir -p /opt/photobooth/flask
python3 -m venv /opt/photobooth/flask/apienv
source /opt/photobooth/flask/apienv/bin/activate
pip install --upgrade pip && \
 pip install wheel && \
 pip install --trusted-host pypi.python.org -r /boot/requirements.txt && \
 pip install --trusted-host pypi.python.org -r /boot/requirements_api.txt
deactivate
cp -rf /boot/api /opt/photobooth/flask/
cat > /opt/photobooth/flask/apienv/lib/python3.7/site-packages/photobooth.pth << EOF
/opt/photobooth/python
EOF
echo "SECRET_KEY=$(python3 -c 'import os; print(os.urandom(16))')" >> /opt/photobooth/flask/api/app/.env
echo "API_KEY=$(openssl rand -base64 42)" >> /opt/photobooth/flask/api/app/.env
mkdir -p /opt/photobooth/data/facerecognition /opt/photobooth/data/db
chown -R www-data:www-data /opt/photobooth/flask/api /opt/photobooth/data/facerecognition /opt/photobooth/data/db
mkdir -p /opt/photobooth/conf/custom
cp /boot/config/trigger.json /opt/photobooth/conf/custom/trigger.json
chown www-data:www-data /opt/photobooth/conf/custom/trigger.json

# install ai components
# note: dependencies installed earlier -> libatlas-base-dev
apt install -y \
    libjpeg-dev \
    libtiff5-dev \
    libjasper-dev \
    libpng-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libopenexr-dev \
    libilmbase23 \
    libhdf5-dev \
    libhdf5-serial-dev \
    libhdf5-103 \
    libqtwebkit4 \
    libqt4-test
source /opt/photobooth/flask/apienv/bin/activate
pip install --trusted-host pypi.python.org -r /boot/requirements_ai.txt
deactivate

# install nodogsplash
wget -O nodogsplash.tar.gz https://github.com/nodogsplash/nodogsplash/archive/v${NODOGSPLASH_RELEASE}.tar.gz && tar xzf nodogsplash.tar.gz && rm nodogsplash.tar.gz
cd nodogsplash-${NODOGSPLASH_RELEASE}
make && make install
cd - > /dev/null
rm -rf nodogsplash-${NODOGSPLASH_RELEASE}
cp /boot/config/wifi/ap-default/nodogsplash.conf /etc/nodogsplash/nodogsplash.conf
cp /boot/config/nginx-nodogsplash.conf /etc/nginx/sites-available/nodogsplash
ln -s /etc/nginx/sites-available/nodogsplash /etc/nginx/sites-enabled

# setup boot splash screen
[[ `grep -c tty3 /boot/cmdline.txt` -eq 0 ]] && sed -i -e "s/tty1/tty3/g" /boot/cmdline.txt
[[ `grep -c splash /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ splash &/' /boot/cmdline.txt
[[ `grep -c logo.nologo /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ logo.nologo &/' /boot/cmdline.txt
[[ `grep -c vt.global_cursor_default /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ vt.global_cursor_default=0 &/' /boot/cmdline.txt
[[ `grep -c loglevel /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ loglevel=3 &/' /boot/cmdline.txt
sed -i -e "s/vt.global_cursor_default=[0,1]/vt.global_cursor_default=0/g" /boot/cmdline.txt

# install ngrok
mkdir -p /opt/ngrok
wget -O ngrok-stable-linux-arm.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip && \
 unzip ngrok-stable-linux-arm.zip && \
 rm ngrok-stable-linux-arm.zip
mv ngrok /opt/ngrok/
ln -s /opt/ngrok/ngrok /usr/local/bin/ngrok
cp /boot/config/ngrok.yml /opt/ngrok/
sed -i -e "s/authtoken:.*/authtoken: $NGROK_TOKEN/g" /opt/ngrok/ngrok.yml
#sed -i -e "s/metadata:.*/metadata: '{\"device\": \"<photobooth-device-id>\"}'/g" /opt/ngrok/ngrok.yml

# create webroot directory
mkdir -p /var/www/html

# move default files
mkdir /var/www/dietpi && mv /var/www/*.php /var/www/*.html -t /var/www/dietpi

# create self signed ssl certificates
# cd /etc/lighttpd
# openssl req -x509 -nodes -new -sha256 -days 365 -newkey rsa:2048 \
#     -keyout server.pem -out server.pem \
#     -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=photobooth"
# chmod 400 server.pem
# lighty-enable-mod ssl
# cd ~/

# install composer
wget https://raw.githubusercontent.com/composer/getcomposer.org/ba1f97192942f1d0de9557258c5009ac6bd7b17d/web/installer -O - -q | php -- --quiet && mv composer.phar /usr/local/bin/composer

# install photobooth
cd /var/www/html
wget -O photobooth.tar.gz https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth.tar.gz && rm photobooth.tar.gz
# optional: if photobooth should be build from source, uncomment:
# PHOTOBOOTH_RELEASE="build-latest"
# cd /var/www/ && rm -rf html
# git clone https://github.com/andreknieriem/photobooth html
# cd /var/www/html
# git submodule update --init
# rm yarn.lock
# yarn install
# yarn build
echo "v${PHOTOBOOTH_RELEASE}" > /var/www/html/version.html
cd - > /dev/null

# photobooth updates and config
cp -rf /boot/photobooth/manager /var/www/html/
cd /var/www/html/manager
composer install --no-interaction
cd - > /dev/null
cp -f /boot/photobooth/my.config.inc.php /var/www/html/config/my.config.inc.php

# create ai folders
mkdir -p /var/www/html/data/ai

# copy captive portal content
cp -rf /boot/captive /var/www/html
mkdir -p /var/www/html/captive/css
cp -f /var/www/html/resources/css/style.css /var/www/html/captive/css
cp -f /var/www/html/resources/css/rounded.css /var/www/html/captive/css
cp -f /var/www/html/node_modules/font-awesome/css/font-awesome.css /var/www/html/captive/css
cp -f /var/www/html/node_modules/normalize.css/normalize.css /var/www/html/captive/css
cp -rf /var/www/html/resources/fonts /var/www/html/captive
cp -rf /var/www/html/node_modules/font-awesome/fonts /var/www/html/captive
ln -sf /opt/photobooth/flask/api/static /var/www/html/captive
convert /var/www/html/resources/img/bg.jpg -quality 25 -resize 1920x1080\> /var/www/html/captive/images/bg

# install vnstat-viewer
wget https://github.com/dalbenknicker/vnstat-viewer/archive/master.zip && \
 unzip master.zip && mv vnstat-viewer-master /var/www/html/vnstat && \
 rm -rf master.zip vnstat-viewer-master
cd /var/www/html/vnstat
composer install --no-interaction
cd - > /dev/null
cp -f /boot/config/vnstat-viewer.php /var/www/html/vnstat/include/config.php
chown -R www-data:www-data /var/www/html/vnstat
grep -qF '<div id="main">' /var/www/html/vnstat/templates/main.tpl || sed -i '/graph.tpl/i <div id="main">' /var/www/html/vnstat/templates/main.tpl
grep -qF '<\div>' /var/www/html/vnstat/templates/main.tpl || sed -i '/gscript.tpl/a <\/div>' /var/www/html/vnstat/templates/main.tpl

# make nginx user owner of /var/www/
chown -R www-data:www-data /var/www/

# photobooth hook
grep -qF photobooth.js /var/www/html/index.php || sed -i '/<\/body>/i \\t<script type="text\/javascript" src="\/static\/js\/photobooth.js"><\/script>' /var/www/html/index.php

# load v4l2 driver module for Pi Camera seems not necessary using dietpi; only remove blacklisting
#echo "bcm2835-v4l2" >> /etc/modules
mv /etc/modprobe.d/dietpi-disable_rpi_camera.conf /etc/modprobe.d/dietpi-disable_rpi_camera.conf~

# access to USB device and printer and Pi Camera
gpasswd -a www-data plugdev
gpasswd -a www-data lp
gpasswd -a www-data lpadmin
gpasswd -a www-data video

# change www root
sed -i -e 's/\/var\/www/\/var\/www\/html/g' /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled

# copy nginx config
cp /boot/config/nginx-photobooth-manager.conf /etc/nginx/sites-dietpi/photobooth-manager.conf

# copy mqtt config
cp /boot/config/mqtt-broker.photobooth.conf /etc/mosquitto/conf.d/photobooth.conf

# install mqtt-launcher
cd /opt && git clone https://github.com/maxmlr/mqtt-launcher.git
cp /boot/config/photobooth.mqtt.conf /opt/mqtt-launcher/launcher.photobooth.conf
sed -i -e "s|mqtt_clientid   =.*|mqtt_clientid   = 'photobooth-${DEVICE_TYPE::1}${DEVICE_ID:(-8)}'|" /opt/mqtt-launcher/launcher.photobooth.conf
chmod +x /opt/mqtt-launcher/mqtt-launcher.py
cd - > /dev/null

# chromium settings
mkdir -p /root/.config/chromium/Default
cp /boot/config/chromium.pref /root/.config/chromium/Default/Preferences
sed -i "s|\"bottom\":.*|\"bottom\":${DISPLAY_RESOLUTION_Y}|" /root/.config/chromium/Default/Preferences
sed -i "s|\"right\":.*|\"right\":${DISPLAY_RESOLUTION_X}|" /root/.config/chromium/Default/Preferences
# TODO check if required
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /root/.config/chromium/Default/Preferences
#sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /root/.config/chromium/Default/Preferences

# add xorg settings
cp /boot/config/xinitrc /root/.xinitrc

# add scripts
mkdir -p /opt/photobooth/bin
cp /boot/scripts/start-kiosk.sh /opt/photobooth/bin/start-kiosk.sh
cp /boot/scripts/timesync.sh /opt/photobooth/bin/timesync.sh
cp /boot/scripts/boot.sh /opt/photobooth/bin/boot.sh
cp /boot/scripts/reboot.sh /opt/photobooth/bin/reboot.sh
cp /boot/scripts/register.sh /opt/photobooth/bin/register.sh
cp /boot/scripts/wifi_action.sh /opt/photobooth/bin/wifi_action.sh
cp /boot/scripts/wifi_connect.sh /opt/photobooth/bin/wifi_connect.sh
chmod +x /opt/photobooth/bin/*.sh

# add bash profile
cp /boot/scripts/profile_photobooth.sh /etc/profile.d/photobooth.sh

# copy images
mkdir -p /opt/photobooth/img/
cp -rf /boot/img/* /opt/photobooth/img/

# copy binaries to /usr/bin
for binary in /boot/binaries/*.sh; do cp $binary /usr/bin/`basename $binary .sh`; chmod +x /usr/bin/`basename $binary .sh`; done

# copy python scripts to /opt/photobooth/python
mkdir -p /opt/photobooth/python
for pymodule in /boot/scripts/*/; do cp -rf $pymodule /opt/photobooth/python/; done
for pyscript in /boot/scripts/*.py; do cp $pyscript /opt/photobooth/python/`basename $pyscript`; chmod +x /opt/photobooth/python/`basename $pyscript`; done

# add symlinks to  /usr/local/bin/
ln -s /opt/photobooth/python/ctl_ledpanel.py /usr/local/bin/ledpanel

# copy services to /usr/local/lib/systemd/system, reload daemon and enable services
mkdir -p /usr/local/lib/systemd/system/
for service in /boot/service/*.service; do cp $service /usr/local/lib/systemd/system/`basename $service`; chmod -x /usr/local/lib/systemd/system/`basename $service`; done
for service in /boot/service/*.timer; do cp $service /usr/local/lib/systemd/system/`basename $service`; chmod -x /usr/local/lib/systemd/system/`basename $service`; done
# reload services
systemctl daemon-reload
# unmask services
systemctl unmask vnstat.service
# enable services
for service in /boot/service/*.service; do systemctl enable `basename $service`; done
for service in /boot/service/*.timer; do systemctl enable `basename $service`; done

# disable services
systemctl disable getty@tty1.service

# add sudo permissions
cat > /etc/sudoers.d/gpio << EOF
www-data ALL=(ALL) NOPASSWD:/usr/bin/gpio
www-data ALL=(ALL) NOPASSWD:/usr/bin/relay
EOF
cat > /etc/sudoers.d/remote << EOF
www-data ALL=(ALL) NOPASSWD:/bin/systemctl start ngrok*
www-data ALL=(ALL) NOPASSWD:/bin/systemctl stop ngrok*
EOF
cat > /etc/sudoers.d/api << EOF
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] scan_results
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] scan
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] reconfigure
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] select_network
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] list_network
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] add_network
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] set_network [0-9] *
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] enable_network [0-9]
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] set update_config 1
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] save_config
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] select_network [0-9]
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] status
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] reconnect
www-data ALL=(ALL) NOPASSWD:/opt/photobooth/bin/wifi_connect.sh wlan[0-9] [0-9]
www-data ALL=(ALL) NOPASSWD:/bin/sed -i * /etc/hostapd/hostapd.conf
www-data ALL=(ALL) NOPASSWD:/usr/sbin/service hostapd restart
www-data ALL=(ALL) NOPASSWD:/sbin/reboot --no-wall
www-data ALL=(ALL) NOPASSWD:/opt/photobooth/bin/reboot.sh [0-9]
www-data ALL=(ALL) NOPASSWD:/sbin/ifup wlan[0-9]
www-data ALL=(ALL) NOPASSWD:/sbin/ifdown wlan[0-9]
www-data ALL=(ALL) NOPASSWD:/usr/bin/chgrp www-data /tmp/ndsctl.sock
www-data ALL=(ALL) NOPASSWD:/usr/bin/chmod g+w /tmp/ndsctl.sock
www-data ALL=(ALL) NOPASSWD:/usr/bin/ndsctl json
www-data ALL=(ALL) NOPASSWD:/usr/bin/ndsctl trust *
www-data ALL=(ALL) NOPASSWD:/sbin/sysctl -n net.ipv4.ip_forward
www-data ALL=(ALL) NOPASSWD:/sbin/sysctl -w net.ipv4.ip_forward=[0-1]
www-data ALL=(ALL) NOPASSWD:/usr/local/bin/ledpanel *
www-data ALL=(ALL) NOPASSWD:/usr/bin/convert *
www-data ALL=(ALL) NOPASSWD:/usr/bin/mosquitto_pub *
EOF

# optimizations
#- disable NTP during boot
sed -i -e 's/CONFIG_NTP_MODE=.*/CONFIG_NTP_MODE=0/g' /boot/dietpi.txt
#- fix chromium not able to access GPU
#- https://github.com/tipam/pi3d/issues/177
ln -fs /usr/lib/chromium-browser/swiftshader/libEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so
ln -fs /usr/lib/chromium-browser/swiftshader/libEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1
ln -fs /usr/lib/chromium-browser/swiftshader/libGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so
ln -fs /usr/lib/chromium-browser/swiftshader/libGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2
ldconfig -l

# customize banner
cp /boot/config/dietpi-banner /boot/dietpi/.dietpi-banner
echo "photobooth-status banner" > /boot/dietpi/.dietpi-banner_custom

# cleanup
apt-get clean && apt-get autoremove -y

# Disable eth0
if [[ -z ${DEBUG+x} ]]
then
 sed -i -e 's|.*allow-hotplug eth0|#allow-hotplug eth0|' /etc/network/interfaces
 ifdown eth0 &> /dev/null
fi

# trigger delayed dietpi restart
systemctl start setup-reboot.service

END=$(date +%s)

echo " --- Photobooth setup finished --- "
echo "  + duration : $(( (END - BEGIN) / 60 )) minutes"
[ $? -eq 0 ] || echo "  + status : ERRORS"
echo "$(date) -> Reboot to finish photobooth setup..."
exit 0
