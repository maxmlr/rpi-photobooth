#!/bin/bash

#########################
# --- Network Setup --- #
#########################

# Setup wlan0 interface
cat > /etc/systemd/network/08-wlan0.network << EOF
[Match]
Name=wlan0
[Network]
IPForward=yes
# If you need a static ip address, then toggle commenting next four lines (example)
DHCP=yes
#Address=192.168.10.60/24
#Gateway=192.168.10.1
#DNS=84.200.69.80 1.1.1.1
EOF

# Setup uap0 interface
cat > /etc/systemd/network/12-uap0.network << EOF
[Match]
Name=uap0
[Network]
Address=192.168.50.1/24
DHCPServer=no
[DHCPServer]
DNS=8.8.8.8 1.1.1.1
EOF

apt -y update && \
apt install -y \
    dnsmasq \
    hostapd \
    nftables \
    vnstat

# disable debian networking (and dhcpcd if availabe/enabled)
systemctl mask networking.service dhcpcd.service
mv /etc/network/interfaces /etc/network/interfaces~ && touch /etc/network/interfaces

# This not required as systemd-resolved.service will not be enabled
#sed -i '1i resolvconf=NO' /etc/resolv.conf

# enable systemd-networkd but not: systemd-resolved.service
systemctl enable systemd-networkd.service

# This not required as systemd-resolved.service will not be enabled
#ln -sf /etc/resolvconf/run/resolv.conf /etc/resolv.conf

# Note: DAEMON_CONF in /etc/default/hostapd is set later to /etc/hostapd/hostapd.conf

# Resolve conflict with network.target
sed -i -e 's/After=network.target/#After=network.target/g' /lib/systemd/system/hostapd.service

# Add interface uap0 to the hostapd.service
mkdir -p /etc/systemd/system/hostapd.service.d
cat > /etc/systemd/system/hostapd.service.d/override.conf << EOF
[Unit]
Wants=wpa_supplicant@wlan0.service

[Service]
ExecStartPre=/sbin/iw dev wlan0 interface add uap0 type __ap
ExecStopPost=-/sbin/iw dev uap0 del
EOF

# Extend wpa_supplicant
ln -s /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
systemctl disable wpa_supplicant.service
systemctl enable wpa_supplicant@wlan0.service

mkdir -p /etc/systemd/system/wpa_supplicant@wlan0.service.d
cat > /etc/systemd/system/wpa_supplicant@wlan0.service.d/override.conf << EOF
[Unit]
BindsTo=hostapd.service
After=hostapd.service

[Service]
ExecStartPost=/usr/sbin/nft add table nat
ExecStartPost=/usr/sbin/nft add chain nat postrouting { type nat hook postrouting priority 100 \; }
ExecStartPost=/usr/sbin/nft add rule nat postrouting ip saddr 192.168.50.0/24 oif wlan0 masquerade
ExecStopPost=-/usr/sbin/nft flush table nat
ExecStopPost=-/usr/sbin/nft delete table nat
EOF

# Reload systemctl deamon
systemctl daemon-reload 


########################
# --- RaspAP Setup --- #
########################

# Add RaspAP commands required by www-data user to sudoers list
cat > /etc/sudoers.d/raspap << EOF
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
systemctl enable hostapd.service

# Move the raspap service to the correct location and enable it. (deprecated)
#mv /boot/service/raspap.service /lib/systemd/system
#systemctl daemon-reload && systemctl enable raspap.service

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
cp /boot/scripts/raspap.servicestart.sh /etc/raspap/hostapd/servicestart.sh
chown root:www-data /etc/raspap/hostapd/servicestart.sh
chmod 750 /etc/raspap/hostapd/servicestart.sh

# add photobooth host to /etc/banner_add_hosts
cat > /etc/banner_add_hosts << EOF
192.168.50.1 photobooth
EOF

# Populate web-manager hostapd config
cat > /etc/raspap/hostapd.ini << EOF
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
