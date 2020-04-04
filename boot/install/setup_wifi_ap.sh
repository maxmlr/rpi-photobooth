#!/bin/bash

# Install dependencies
apt install -y \
    dnsmasq \
    hostapd \
    nftables \
    vnstat

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

# disable debian networking (and dhcpcd if availabe/enabled)
systemctl mask networking.service dhcpcd.service
mv /etc/network/interfaces /etc/network/interfaces~ && touch /etc/network/interfaces

# enable systemd-networkd (NOT: systemd-resolved.service)
systemctl enable systemd-networkd.service

# Only required when systemd-resolved.service is enabled
#sed -i '1i resolvconf=NO' /etc/resolv.conf
#ln -sf /etc/resolvconf/run/resolv.conf /etc/resolv.conf

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

# Add photobooth host to /etc/banner_add_hosts
cat > /etc/banner_add_hosts << EOF
192.168.50.1 photobooth
EOF

# Copy configs
cp /boot/config/hostapd.conf /etc/hostapd/hostapd.conf
cp /boot/config/dnsmasq.conf /etc/dnsmasq.conf
cp /boot/config/dhcpcd.conf /etc/dhcpcd.conf

# Update hostapd defaults
sed -i -e 's/#DAEMON_CONF=.*/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd

# Unmask and enable the hostapd service.
systemctl unmask hostapd.service
systemctl enable hostapd.service

# Reload systemctl deamon
systemctl daemon-reload
