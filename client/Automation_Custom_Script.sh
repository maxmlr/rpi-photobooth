#!/bin/bash
# Automatic setup photobooth-client and DietPi
# @maxmlr

# source photobooth config
source /boot/photobooth.conf

# copy public key
cp -f /boot/authorized_keys /root/.ssh/authorized_keys

# setup WiFi AccessPoint
#/boot/install/setup_wifi_ap.sh
mkdir -p /opt/photobooth/conf
cp -rf /boot/config/wifi/* /opt/photobooth/conf
chmod +x /boot/install/install-dongle.sh && ln -s /boot/install/install-dongle.sh /usr/local/bin/install-dongle

# install dependencies
apt -y update && \
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
    mosh \
    imagemagick

# Configure managed services
cat /boot/config/dietpi-services_include_exclude >> /DietPi/dietpi/.dietpi-services_include_exclude

# Edit /DietPi/config.txt:
# - merge configs from photobooth.conf
for config in "${DIETPI_CONFIG[@]}"
do
    key=`echo "$config" | cut -d"=" -f1 | sed -e s"|\#||g"`
    if tac /DietPi/config.txt | grep -m1 -q "$key"; then
        config_old=`tac /DietPi/config.txt | grep -m1 "$key"`
        if [[ "$config" = "$config_old" ]]
        then
            echo "[config] no change: $key"
        else
            update_msg+=( "[config] update - old: `tac /DietPi/config.txt | grep -m1 "$key"` -> new: $config" )
            tac /DietPi/config.txt | sed "/$key/ {s/.*/$config/; :loop; n; b loop}" | tac > /tmp/config.txt
            mv /tmp/config.txt /DietPi/config.txt
        fi
    else
        echo "[config] new: $config"
        echo "$config"  >> /DietPi/config.txt
    fi
done
# - enable Pi Camera
#sed -i -e 's/#start_x=1/start_x=1/g' /DietPi/config.txt
# - adjust memory split
if [ "$HEADLESS" -eq "0" ]; then
    sed -i -e 's/gpu_mem_256=.*/gpu_mem_256=64/g' /DietPi/config.txt 
    sed -i -e 's/gpu_mem_512=.*/gpu_mem_512=128/g' /DietPi/config.txt 
    sed -i -e 's/gpu_mem_1024=.*/gpu_mem_1024=256/g' /DietPi/config.txt 
fi

# install required Python 3 modules
pip3 install --upgrade pip && \
 pip3 install --trusted-host pypi.python.org -r /boot/requirements.txt

# if the python uinput library should be used for remote trigger (send key_press),
# uncomment the following commands:
# pip install python-uinput
# echo 'uinput' | tee -a /etc/modules

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

# load v4l2 driver module for Pi Camera seems not necessary using dietpi; only remove blacklisting
#echo "bcm2835-v4l2" >> /etc/modules
mv /etc/modprobe.d/dietpi-disable_rpi_camera.conf /etc/modprobe.d/dietpi-disable_rpi_camera.conf~

# access to USB device and printer and Pi Camera
gpasswd -a www-data plugdev
gpasswd -a www-data lp
gpasswd -a www-data lpadmin
gpasswd -a www-data video

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

# add /var/lib/dietpi/dietpi-autostart/custom.sh
cp /boot/scripts/dietpi-custom.sh /var/lib/dietpi/dietpi-autostart/custom.sh

# add scripts
mkdir -p /opt/photobooth/bin
cp /boot/scripts/start-kiosk.sh /opt/photobooth/bin/start-kiosk.sh
cp /boot/scripts/timesync.sh /opt/photobooth/bin/timesync.sh
cp /boot/scripts/boot.sh /opt/photobooth/bin/boot.sh
cp /boot/scripts/reboot.sh /opt/photobooth/bin/reboot.sh
cp /boot/scripts/register.sh /opt/photobooth/bin/register.sh
cp /boot/scripts/wifi_action.sh /opt/photobooth/bin/wifi_action.sh
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
# ...
# enable services
for service in /boot/service/*.service; do systemctl enable `basename $service`; done
for service in /boot/service/*.timer; do systemctl enable `basename $service`; done

# disable services
systemctl disable getty@tty1.service

# disable services not required for client
systemctl disable api nodogsplash

# add sudo permissions
cat > /etc/sudoers.d/gpio << EOF
www-data ALL=(ALL) NOPASSWD:/usr/bin/gpio
www-data ALL=(ALL) NOPASSWD:/usr/bin/relay
EOF
cat > /etc/sudoers.d/remote << EOF
www-data ALL=(ALL) NOPASSWD:/bin/systemctl start ngrok*
www-data ALL=(ALL) NOPASSWD:/bin/systemctl stop ngrok*
EOF

#- disable NTP during boot
sed -i -e 's/CONFIG_NTP_MODE=.*/CONFIG_NTP_MODE=0/g' /DietPi/dietpi.txt
#- fix chromium not able to access GPU
#- https://github.com/tipam/pi3d/issues/177
ln -fs /usr/lib/chromium-browser/swiftshader/libEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so
ln -fs /usr/lib/chromium-browser/swiftshader/libEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1
ln -fs /usr/lib/chromium-browser/swiftshader/libGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so
ln -fs /usr/lib/chromium-browser/swiftshader/libGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2
ldconfig -l

# customize banner
cp /boot/config/dietpi-banner /DietPi/dietpi/.dietpi-banner
echo "photobooth-status banner" > /DietPi/dietpi/.dietpi-banner_custom

# cleanup
apt-get clean && apt-get autoremove -y

# Disable eth0
sed -i -e 's|.*allow-hotplug eth0|#allow-hotplug eth0|' /etc/network/interfaces
ifdown eth0 &>/dev/null

# setup photobooth wifi
cp -f /boot/config/wpa_supplicant.conf /etc/wpa_supplicant

if [ $? -eq 0 ]
then
  echo "Photobooth setup finished successfully"
  echo
  echo "    --- PLEASE REBOOT TO FINISH---    "
  echo
  exit 0
else
  echo "Photobooth setup finished with errors" >&2
  exit 0
fi
