#!/bin/bash
update_msg=()

# source photobooth config
source /boot/photobooth.conf

# install dependencies
apt -y update

if [[ "$DEVICE_TYPE" = "server" ]]; then
apt install -y \
    build-essential \
    libmicrohttpd-dev \
    iptables \
    python3-dev \
    python3-venv \
    uwsgi \
    uwsgi-emperor \
    uwsgi-plugin-python3 \
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
    mosh
fi

if [[ "$DEVICE_TYPE" = "client" ]]; then
apt install -y \
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
    mosh
fi

# Configure managed services
sort -u /boot/config/dietpi-services_include_exclude /DietPi/dietpi/.dietpi-services_include_exclude > /DietPi/dietpi/.dietpi-services_include_exclude

# Edit /DietPi/config.txt:
# - add photobooth.conf
for config in "${DIETPI_CONFIG[@]}"
do
    key=`echo "$config" | cut -d"=" -f1 | sed -e s"|\#||g"`
    if tac /DietPi/config.txt | grep -m1 -q "$key"; then
        config_old=`tac /DietPi/config.txt | grep -m1 "$key"`
        if [[ "$config" = "$config_old" ]]
        then
            echo "[config] no change: $key" 
            # tac /DietPi/config.txt | sed "/$key/ {s/.*/$config/; :loop; n; b loop}" | tac > /tmp/config.txt
            # mv /tmp/config.txt /DietPi/config.txt
        else
            update_msg+=( "[config] update - old: `tac /DietPi/config.txt | grep -m1 "$key"` -> new: $config (Please update manually in /DietPi/config.txt if required)" )
        fi
    else
        echo "[config] new: $config"
        echo "$config"  >> /DietPi/config.txt
    fi
done

# install required Python 3 modules
pip3 install --upgrade pip && \
 pip3 install --trusted-host pypi.python.org -r /boot/requirements.txt

# if the python uinput library should be used for remote trigger (send key_press),
# uncomment the following commands:
# pip install python-uinput
# echo 'uinput' | tee -a /etc/modules

# install flask
if [[ "$DEVICE_TYPE" = "server" ]]; then
source /opt/photobooth/flask/apienv/bin/activate
pip install --upgrade pip && \
pip install --trusted-host pypi.python.org -r /boot/requirements.txt && \
pip install flask flask-cors bootstrap-flask Flask-FontAwesome
deactivate
cp -rf /boot/api /opt/photobooth/flask/
cat > /opt/photobooth/flask/apienv/lib/python3.7/site-packages/photobooth.pth << EOF
/opt/photobooth/python
EOF
chown -R www-data:www-data /opt/photobooth/flask/api

# register flask apps
mv /opt/photobooth/flask/api/api.ini /etc/uwsgi/apps-available/
ln -sf /etc/uwsgi/apps-available/api.ini /etc/uwsgi/apps-enabled/

# restart uwsgi
systemctl restart uwsgi

# install nodogsplash
systemctl stop nodogsplash.service
wget -O nodogsplash.tar.gz https://github.com/nodogsplash/nodogsplash/archive/v${NODOGSPLASH_RELEASE}.tar.gz && tar xzf nodogsplash.tar.gz && rm nodogsplash.tar.gz
cd nodogsplash-${NODOGSPLASH_RELEASE}
make && make install
cd - > /dev/null
rm -rf nodogsplash-${NODOGSPLASH_RELEASE}
cp /boot/config/nodogsplash.conf /etc/nodogsplash/nodogsplash.conf
systemctl start nodogsplash.service

# setup boot splash screen
[[ `grep -c tty3 /boot/cmdline.txt` -eq 0 ]] && sed -i -e "s/tty1/tty3/g" /boot/cmdline.txt
[[ `grep -c splash /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ splash &/' /boot/cmdline.txt
[[ `grep -c logo.nologo /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ logo.nologo &/' /boot/cmdline.txt
[[ `grep -c vt.global_cursor_default /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ vt.global_cursor_default=0 &/' /boot/cmdline.txt
sed -i -e "s/vt.global_cursor_default=[0,1]/vt.global_cursor_default=0/g" /boot/cmdline.txt
fi

# install ngrok
systemctl stop ngrok@"ssh\x20http".service
mkdir -p /opt/ngrok
wget -O ngrok-stable-linux-arm.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip && \
 unzip ngrok-stable-linux-arm.zip && \
 rm ngrok-stable-linux-arm.zip
mv ngrok /opt/ngrok/
ln -sf /opt/ngrok/ngrok /usr/local/bin/ngrok
cp /boot/config/ngrok.yml /opt/ngrok/
sed -i -e "s/authtoken:.*/authtoken: $NGROK_TOKEN/g" /opt/ngrok/ngrok.yml
#sed -i -e "s/metadata:.*/metadata: '{\"device\": \"<photobooth-device-id>\"}'/g" /opt/ngrok/ngrok.yml
systemctl start ngrok@"ssh\x20http".service

if [[ "$DEVICE_TYPE" = "server" ]]; then
# create webroot directory
mkdir -p /var/www/html

# copy captive protal
cp -rf /boot/captive /var/www/html

# create self signed ssl certificates
# cd /etc/lighttpd
# openssl req -x509 -nodes -new -sha256 -days 365 -newkey rsa:2048 \
#     -keyout server.pem -out server.pem \
#     -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=photobooth"
# chmod 400 server.pem
# lighty-enable-mod ssl
# cd ~/

# install photobooth
echo "Installing photobooth"
cp /var/www/html/config/my.config.inc.php /tmp/my.config.inc.php
cd /var/www/html
wget -O photobooth.tar.gz https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth.tar.gz && rm photobooth.tar.gz
# TODO: replace master with v${PHOTOBOOTH_UPDATE}
wget -O photobooth_update.tar.gz https://github.com/maxmlr/photobooth/archive/master.tar.gz && tar xzf photobooth_update.tar.gz && rm photobooth_update.tar.gz
# TODO: replace master with ${PHOTOBOOTH_UPDATE}
cp -r photobooth-master/* . && rm -rf photobooth-master/
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
cd - > /dev/null

# photobooth config
cp /boot/config/photobooth.webinterface.php /var/www/html/config/my.config.inc_latest.php
chown -R www-data:www-data /var/www/html/config/my.config.inc_latest.php
mv /tmp/my.config.inc.php /var/www/html/config/my.config.inc.php
chown -R www-data:www-data /var/www/html/config/my.config.inc.php
update_msg+=( "Please manually check updates in the photobooth webinterface configs:" )
update_msg+=( " - old: /var/www/html/config/my.config.inc.php" )
update_msg+=( " - new: /var/www/html/config/my.config.inc_latest.php" )
fi

# load v4l2 driver module for Pi Camera seems not necessary using dietpi; only remove blacklisting
#echo "bcm2835-v4l2" >> /etc/modules
mv /etc/modprobe.d/dietpi-disable_rpi_camera.conf /etc/modprobe.d/dietpi-disable_rpi_camera.conf~ 2&> /dev/null

# access to USB device and printer and Pi Camera
gpasswd -a www-data plugdev
gpasswd -a www-data lp
gpasswd -a www-data lpadmin
gpasswd -a www-data video

if [[ "$DEVICE_TYPE" = "server" ]]; then
# change www root
sed -i -e 's/\/var\/www;/\/var\/www\/html;/g' /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled

# copy nginx config
cp /boot/config/nginx-photobooth-manager.conf /etc/nginx/sites-dietpi/photobooth-manager.conf
fi

# install mqtt-launcher
cd /opt/mqtt-launcher && git pull
cp /boot/config/photobooth.mqtt.conf /opt/mqtt-launcher/launcher.photobooth.conf
chmod +x /opt/mqtt-launcher/mqtt-launcher.py
cd - > /dev/null

# chromium settings
# TODO check if required
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /root/.config/chromium/Default/Preferences
#sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /root/.config/chromium/Default/Preferences

# add xorg settings
cp /boot/config/xinitrc /root/.xinitrc

# add /var/lib/dietpi/dietpi-autostart/custom.sh
cp /boot/scripts/dietpi-custom.sh /var/lib/dietpi/dietpi-autostart/custom.sh

# add scripts
mkdir -p /opt/photobooth/bin
cp /boot/scripts/start-kiosk.sh /opt/photobooth/bin/start-kiosk.sh
cp /boot/scripts/timesync.sh /opt/photobooth/bin/timesync.sh
cp /boot/scripts/health.sh /opt/photobooth/bin/health.sh
chmod +x /opt/photobooth/bin/*.sh

# add bash profile
cp /boot/scripts/profile_photobooth.sh /etc/profile.d/photobooth.sh

# services
# ...

# copy images
mkdir -p /opt/photobooth/img/
cp -rf /boot/img/* /opt/photobooth/img/

# copy binaries to /usr/bin
for binary in /boot/binaries/*.sh; do cp $binary /usr/bin/`basename $binary .sh`; chmod +x /usr/bin/`basename $binary .sh`; done

# copy python scripts to /opt/photobooth/python
mkdir -p /opt/photobooth/python
for pyscript in /boot/scripts/*.py; do cp $pyscript /opt/photobooth/python/`basename $pyscript`; chmod +x /opt/photobooth/python/`basename $pyscript`; done

# add symlinks to  /usr/local/bin/
ln -sf /opt/photobooth/python/ctl_ledpanel.py /usr/local/bin/ledpanel

# copy services to /lib/systemd/system/, reload daemon and enable services
for service in /boot/service/*.service; do cp $service /lib/systemd/system/`basename $service`; chmod -x /lib/systemd/system/`basename $service`; done
for service in /boot/service/*.timer; do cp $service /lib/systemd/system/`basename $service`; chmod -x /lib/systemd/system/`basename $service`; done
systemctl daemon-reload
for service in /boot/service/*.service; do systemctl enable `basename $service`; done
for service in /boot/service/*.timer; do systemctl enable `basename $service`; done

if [[ "$DEVICE_TYPE" = "client" ]]; then
# disable services not required for client
systemctl disable api nodogsplash
fi

# add sudo permissions
cat > /etc/sudoers.d/gpio << EOF
www-data ALL=(ALL) NOPASSWD:/usr/bin/gpio
www-data ALL=(ALL) NOPASSWD:/usr/bin/relay
EOF
cat > /etc/sudoers.d/remote << EOF
www-data ALL=(ALL) NOPASSWD:/bin/systemctl start ngrok*
www-data ALL=(ALL) NOPASSWD:/bin/systemctl stop ngrok*
EOF
if [[ "$DEVICE_TYPE" = "server" ]]; then
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
EOF
fi

if [[ "$DEVICE_TYPE" = "server" ]]; then
# optimizations
sed -i -e 's/CONFIG_NTP_MODE=.*/CONFIG_NTP_MODE=0/g' /DietPi/dietpi.txt
fi

# cleanup
apt-get clean && apt-get autoremove -y

echo
echo
echo " --- Important update notes --- "
echo
for msg in "${update_msg[@]}"
do
    echo "$msg"
done

if [ $? -eq 0 ]
then
  echo "Photobooth update finished successfully"
  exit 0
else
  echo "Photobooth update finished with errors" >&2
  exit 0
fi
