#!/bin/bash

# Populate `/etc/network/interfaces.d/ap0`
bash -c 'cat > /etc/network/interfaces.d/uap0' << EOF
auto uap0
allow-hotplug uap0
iface uap0 inet static
address 192.168.50.1
netmask 255.255.255.0
EOF

# Populate `/etc/udev/rules.d/70-persistent-net.rules`
MAC_ADDRESS="$(cat /sys/class/net/wlan0/address)"
bash -c 'cat > /etc/udev/rules.d/70-persistent-net.rules' << EOF
SUBSYSTEM=="ieee80211", ACTION=="add|change", ATTR{macaddress}=="${MAC_ADDRESS}", KERNEL=="phy0", \
  RUN+="/sbin/iw phy phy0 interface add uap0 type __ap", \
  RUN+="/bin/ip link set uap0 address ${MAC_ADDRESS}
EOF

apt -y update && \
apt install -y \
    dnsmasq \
    hostapd \
    nftables \
    vnstat

bash -c 'cat > /etc/sudoers.d/raspap' << EOF
www-data ALL=(ALL) NOPASSWD:/sbin/ifdown
www-data ALL=(ALL) NOPASSWD:/sbin/ifup
www-data ALL=(ALL) NOPASSWD:/bin/cat /etc/wpa_supplicant/wpa_supplicant.conf
www-data ALL=(ALL) NOPASSWD:/bin/cat /etc/wpa_supplicant/wpa_supplicant-wlan[0-9].conf
www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/wifidata /etc/wpa_supplicant/wpa_supplicant.conf
www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/wifidata /etc/wpa_supplicant/wpa_supplicant-wlan[0-9].conf
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] scan_results
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] scan
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] reconfigure
www-data ALL=(ALL) NOPASSWD:/sbin/wpa_cli -i wlan[0-9] select_network
www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/hostapddata /etc/hostapd/hostapd.conf
www-data ALL=(ALL) NOPASSWD:/bin/systemctl start hostapd.service
www-data ALL=(ALL) NOPASSWD:/bin/systemctl stop hostapd.service
www-data ALL=(ALL) NOPASSWD:/bin/systemctl start dnsmasq.service
www-data ALL=(ALL) NOPASSWD:/bin/systemctl stop dnsmasq.service
www-data ALL=(ALL) NOPASSWD:/bin/systemctl start openvpn-client@client
www-data ALL=(ALL) NOPASSWD:/bin/systemctl stop openvpn-client@client
www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/openvpn.ovpn /etc/openvpn/client/client.conf
www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/authdata /etc/openvpn/client/login.conf
www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/dnsmasqdata /etc/dnsmasq.conf
www-data ALL=(ALL) NOPASSWD:/bin/cp /tmp/dhcpddata /etc/dhcpcd.conf
www-data ALL=(ALL) NOPASSWD:/sbin/shutdown -h now
www-data ALL=(ALL) NOPASSWD:/sbin/reboot
www-data ALL=(ALL) NOPASSWD:/sbin/ip link set wlan[0-9] down
www-data ALL=(ALL) NOPASSWD:/sbin/ip link set wlan[0-9] up
www-data ALL=(ALL) NOPASSWD:/sbin/ip -s a f label wlan[0-9]
www-data ALL=(ALL) NOPASSWD:/bin/cp /etc/raspap/networking/dhcpcd.conf /etc/dhcpcd.conf
www-data ALL=(ALL) NOPASSWD:/etc/raspap/hostapd/enablelog.sh
www-data ALL=(ALL) NOPASSWD:/etc/raspap/hostapd/disablelog.sh
www-data ALL=(ALL) NOPASSWD:/etc/raspap/hostapd/servicestart.sh
www-data ALL=(ALL) NOPASSWD:/etc/raspap/lighttpd/configport.sh
www-data ALL=(ALL) NOPASSWD:/etc/raspap/openvpn/configauth.sh
EOF

# git clone the files to /var/www/html/rpi.
mkdir -p /var/www/html
[ -d "/var/www/html/rpi" ] && rm -rf /var/www/html/rpi
git clone https://github.com/billz/raspap-webgui /var/www/html/rpi

# Move the high-res favicons to the web root.
mv /var/www/html/rpi/app/icons/* /var/www/html/rpi

# Set the files ownership to www-data user.
chown -R www-data:www-data /var/www/html/rpi

# Move the RaspAP configuration file to the correct location.
mkdir /etc/raspap
mv /var/www/html/rpi/raspap.php /etc/raspap/
chown -R www-data:www-data /etc/raspap

# Move the HostAPD logging and service control shell scripts to the correct location.
mkdir /etc/raspap/hostapd
mv /var/www/html/rpi/installers/*log.sh /etc/raspap/hostapd
mv /var/www/html/rpi/installers/service*.sh /etc/raspap/hostapd

# Set ownership and permissions for logging and service control scripts.
chown -c root:www-data /etc/raspap/hostapd/*.sh
chmod 750 /etc/raspap/hostapd/*.sh

# Force a reload of new settings in /etc/rc.local.
#systemctl restart rc-local.service
#systemctl daemon-reload

# Unmask and enable the hostapd service.
systemctl unmask hostapd.service
#systemctl enable hostapd.service

# Move the raspap service to the correct location and enable it.
mv /var/www/html/rpi/installers/raspap.service /lib/systemd/system
systemctl enable raspap.service

# Copy the configuration files for dhcpcd, dnsmasq, and hostapd.
mv /var/www/html/rpi/config/default_hostapd /etc/default/hostapd
mv /var/www/html/rpi/config/hostapd.conf /etc/hostapd/hostapd.conf
mv /var/www/html/rpi/config/dnsmasq.conf /etc/dnsmasq.conf
mv /var/www/html/rpi/config/dhcpcd.conf /etc/dhcpcd.conf
mv /var/www/html/rpi/config/config.php /var/www/html/rpi/includes/

# Change according to photobooth requirements
cp /boot/config/hostapd.conf /etc/hostapd/hostapd.conf
cp /boot/config/dnsmasq.conf /etc/dnsmasq.conf
cp /boot/config/dhcpcd.conf /etc/dhcpcd.conf
cp /boot/config/raspap.config.php /var/www/html/rpi/includes/config.php
chown www-data:www-data /var/www/html/rpi/includes/config.php
cp /boot/service/raspap.servicestart.sh /etc/raspap/hostapd/servicestart.sh
chown root:www-data /etc/raspap/hostapd/servicestart.sh
chmod 750 /etc/raspap/hostapd/servicestart.sh

# Add Wifi-AP postboot service
cp /boot/service/start-wifi-ap.sh /var/lib/dietpi/postboot.d/10-start-wifi-ap.sh

# add photobooth host to /etc/banner_add_hosts
bash -c 'cat > /etc/banner_add_hosts' << EOF
192.168.50.1 photobooth
EOF

# Populate web-manager hostapd config
bash -c 'cat > /etc/raspap/hostapd.ini' << EOF
LogEnable = 1
WifiAPEnable = 1
WifiManaged = wlan0
EOF
chown www-data:www-data /etc/raspap/hostapd.ini

# (Optional) Optimize PHP
#sed -i -E 's/^session\.cookie_httponly\s*=\s*(0|([O|o]ff)|([F|f]alse)|([N|n]o))\s*$/session.cookie_httponly = 1/' /etc/php/7.1/cgi/php.ini
#sed -i -E 's/^;?opcache\.enable\s*=\s*(0|([O|o]ff)|([F|f]alse)|([N|n]o))\s*$/opcache.enable = 1/' /etc/php/7.1/cgi/php.ini
#phpenmod opcache

# (Optional) Install OpenVPN, enable option in RaspAP config and enable openvpn-client service
#apt-get install openvpn
#sed -i "s/\('RASPI_OPENVPN_ENABLED', \)false/\1true/g" /var/www/html/rpi/includes/config.php
#systemctl enable openvpn-client@client

# (Optional) Create OpenVPN auth control scripts, set ownership and permissions
#mkdir /etc/raspap/openvpn
#cp /var/www/html/rpi/installers/configauth.sh /etc/raspap/openvpn
#chown -c root:www-data /etc/raspap/openvpn/*.sh
#chmod 750 /etc/raspap/openvpn/*.sh
