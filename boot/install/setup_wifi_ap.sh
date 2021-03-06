#!/bin/bash

# install dependencies
apt install -y \
    build-essential \
    libsqlite3-dev \
    multiarch-support \
    hostapd \
    dnsmasq

# install vnstat
useradd -r -s /bin/false vnstat
wget https://github.com/vergoh/vnstat/releases/download/v2.6/vnstat-2.6.tar.gz
tar xzf vnstat-2.6.tar.gz && rm vnstat-2.6.tar.gz
cd vnstat-2.6
./configure && make && make install
cd - > /dev/null

# install libssl1.0.0
wget https://dietpi.com/downloads/binaries/all/libssl1.0.0_1.0.1t-1+deb8u7_armhf.deb -O 126.deb
dpkg --force-hold,confdef,confold -i 126.deb
rm 126.deb

# use dietpi hostapd
# ARM_VERSION=$(uname -m)
# ARM_VERSION=${ARM_VERSION:0:5}
# WIFI_DRIVER="nl80211" # rtl8188c
# wget https://dietpi.com/downloads/binaries/all/hostapd_2.5_all.zip -O 60.zip
# unzip -o 60.zip
# chmod +x hostapd-* hostapd_*
# mv hostapd-$WIFI_DRIVER-$ARM_VERSION $(which hostapd)
# mv hostapd_cli-$ARM_VERSION $(which hostapd_cli)
# rm 60.zip hostapd-* hostapd_*

# copy wlan1/2 device configuration
cp /boot/config/wifi/wlan1.conf /etc/network/interfaces.d/wlan1
cp /boot/config/wifi/wlan2.conf /etc/network/interfaces.d/wlan2

# add hostapd.service override (bridge)
mkdir -p /etc/systemd/system/hostapd.service.d
cat > /etc/systemd/system/hostapd.service.d/override.conf << EOF
[Service]
ExecStartPost=/sbin/sysctl -w net.ipv4.ip_forward=1
ExecStartPost=/usr/sbin/iptables -t nat -A POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
ExecStopPost=-/usr/sbin/iptables -t nat -D POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
ExecStopPost=-/sbin/sysctl -w net.ipv4.ip_forward=0
EOF

# Add photobooth host to /etc/banner_add_hosts
cat > /etc/banner_add_hosts << EOF
192.168.50.1 photobooth
EOF

# Copy configs
cp /boot/config/wifi/ap-default/hostapd.conf /etc/hostapd/hostapd.conf
cp /boot/config/wifi/ap-default/dnsmasq.conf /etc/dnsmasq.d/photobooth.conf

# Reload systemctl deamon
systemctl daemon-reload

# Unmask and enable the hostapd service.
systemctl unmask hostapd.service
systemctl enable hostapd.service
