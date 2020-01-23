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
bash -c 'cat >> /DietPi/dietpi/.dietpi-services_include_exclude' << EOF
- hostapd
- dnsmasq
- raspap
EOF

# Edit /DietPi/config.txt
[[ -z "$HDMI_OUT" ]] || echo "$HDMI_OUT" >> /DietPi/config.txt
sed -i -e 's/#start_x=1/start_x=1/g' /DietPi/config.txt

# install required python modules
pip install paho-mqtt
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
wget https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && rm photobooth-${PHOTOBOOTH_RELEASE}.tar.gz
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
chown -R www-data:www-data /var/www/
cd ~/

# photobooth config
bash -c 'cat > /var/www/html/config/my.config.inc.php' << EOF
<?php
\$config = array (
  'show_fork' => false,
  'previewFromCam' => true,
  'previewCamTakesPic' => false,
  'background_image' => 'url(../img/bg.jpg)',
  'background_admin' => 'url(../img/bg.jpg)',
  'background_chroma' => 'url(../img/bg.jpg)',
  'webserver_ip' => 'photobooth',
  'rounded_corners' => true,
  'photo_key' => '32',
  'collage_key' => '67',
  'start_screen_subtitle' => 'By Max and Max',
  'take_picture' =>
  array (
    'cmd' => 'raspistill -n -o %s -q 100 -t 1 | echo Done',
    //'cmd' => 'gphoto2 --capture-image-and-download --filename=%s',
    'msg' => 'Done',
    //'msg' => 'New file is in location',
  ),
);
EOF
chown -R www-data:www-data /var/www/html/config/my.config.inc.php

# Pi Camera setup - not required for dietpi
#bash -c 'cat >> /etc/modules' << EOF
#bcm2835-v4l2
#EOF
 
# access to USB device and printer and Pi Camera
gpasswd -a www-data plugdev
gpasswd -a www-data lp
gpasswd -a www-data lpadmin
gpasswd -a www-data video

# change www root in /etc/lighttpd/lighttpd.conf
sed -i -e 's/\/var\/www/\/var\/www\/html/g' /etc/lighttpd/lighttpd.conf

# install mqtt-launcher
cd /opt
git clone https://github.com/jpmens/mqtt-launcher.git
cd mqtt-launcher
bash -c 'cat > /opt/mqtt-launcher/launcher.photobooth.conf' << EOF
logfile         = '/var/log/mqtt_launcher.photobooth.log'
mqtt_broker     = 'localhost'       # default: 'localhost'.
mqtt_port       = 1883              # default: 1883
mqtt_clientid   = 'mqtt-launcher-1'
mqtt_username   = None
mqtt_password   = None
mqtt_tls        = None              # default: No TLS

topiclist = {

    # topic                     payload value       program & arguments
    "photobooth/remote" :   {
                                'trigger'       :   [ '/opt/mqtt-launcher/bin/trigger.sh' ],
                            },
}
EOF
mkdir bin
bash -c 'cat > /opt/mqtt-launcher/bin/trigger.sh' << EOF
#!/bin/bash
XAUTH_FILE=\`ls /tmp/serverauth* | head -n1\`
XAUTHORITY=\${XAUTH_FILE} DISPLAY=:0.0 xdotool search --sync --class --onlyvisible chromium-browser windowfocus key space
EOF
chmod +x bin/trigger.sh mqtt-launcher.py
cd ~/

# chromium settings
# TODO check if required
#sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /root/.config/chromium/Default/Preferences
#sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /root/.config/chromium/Default/Preferences

# add xorg settings
bash -c 'cat > /root/.xinitrc' << EOF
#!/bin/sh
xset -dpms
xset s off
xset s noblank

/usr/bin/unclutter -idle 0 -root & \
chromium-browser \
        --no-sandbox \
        --start-fullscreen \
        --window-size=1920,1080 \
        --kiosk \
        --incognito \
        --noerrdialogs \
        --disable-infobars \
        --disable-translate \
        --use-fake-ui-for-media-stream \
        --no-first-run \
        --fast \
        --fast-start \
        --disable-features=TranslateUI \
        --disk-cache-dir=/dev/null \
        --password-store=basic \
        --app=http://localhost/
EOF

# Populate /var/lib/dietpi/dietpi-autostart/custom.sh
bash -c 'cat > /var/lib/dietpi/dietpi-autostart/custom.sh' << EOF
#!/bin/bash
# photobooth custom start
# see /var/lib/dietpi/postboot.d/
EOF

# Add photobooth kiosk autostart postboot service
bash -c 'cat > /var/lib/dietpi/postboot.d/20-start-kiosk.sh' << EOF
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
echo "Starting chromium browser in kiosk mode for photobooth app (v\${PHOTOBOOTH_RELEASE})"
startx /root/.xinitrc &
EOF

# Add manual timesync postboot service
bash -c 'cat > /var/lib/dietpi/postboot.d/30-timesync.sh' << EOF
#!/bin/bash
# Start timesync in background
echo "Starting manual timesync (async)"
systemctl start systemd-timesyncd.service & sleep 60 && systemctl stop systemd-timesyncd.service &
EOF

# Services
systemctl disable hostapd.service

# Copy scripts to /usr/bin
for binary in /boot/bin/*.sh; do cp $binary /usr/bin/`basename $binary .sh`; done

# Optimizations
sed -i -e 's/CONFIG_NTP_MODE=.*/CONFIG_NTP_MODE=0/g' /DietPi/dietpi.txt

# Cleanup
apt-get clean
apt-get autoremove -y
