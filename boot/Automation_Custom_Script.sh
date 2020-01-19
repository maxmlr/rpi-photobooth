#!/bin/bash
# Automatic setup photobooth and DietPi
# @maxmlr

PHOTOBOOTH_RELEASE="2.1.0"

# setup access point
/boot/Automation_Custom_Script-wifi.sh -a photobooth "" -u photobooth

# add repository for yarn; install yarn and other dependencies
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt update && \
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
# optional: if photobooth should be build from source, uncomment:
# apt install -y yarn build-essential

# install required python modules
pip install paho-mqtt

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
mkdir /var/www/html && cd /var/www/html
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

# Pi Camera setup - not required for dietpi
#bash -c 'cat >> /etc/modules' << EOF
#bcm2835-v4l2
#EOF

# Enable Pi Camera
sed -i -e 's/#start_x=1/start_x=1/g' /DietPi/config.txt
 
# access to USB device and printer and picam
gpasswd -a www-data plugdev
gpasswd -a www-data lp
gpasswd -a www-data lpadmin
gpasswd -a www-data video

# mask accesspoint service
dietpi-services mask hostapd

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
# mqtt_username = 'jane'
# mqtt_password = 'secret'

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

# add xorg settings=
bash -c 'cat > /root/.xinitrc' << EOF
#!/bin/sh
xset -dpms
xset s off
xset s noblank

/usr/bin/unclutter & \
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
echo "Starting mosquito server with topic photobox/#"
echo "Starting mqtt-launcher [/opt/mqtt-launcher/launcher.photobooth.conf]"
echo "Starting chromium browser in kiosk mode for photobooth app (`cat /var/www/html/version.html`)"
sleep 10 && startx /root/.xinitrc &
sleep 3 && mosquitto_sub -v -t 'photobox/#' &
sleep 3 && MQTTLAUNCHERCONFIG=/opt/mqtt-launcher/launcher.photobooth.conf /opt/mqtt-launcher/mqtt-launcher.py &
EOF
