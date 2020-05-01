#!/bin/bash

# Install dependencies
apt install -y \
    dnsmasq \
    hostapd \
    vnstat

# Resolve conflict with network.target
sed -i -e 's/After=network.target/#After=network.target/g' /lib/systemd/system/hostapd.service

# Add interface uap0 to the hostapd.service
mkdir -p /etc/systemd/system/hostapd.service.d
cat > /etc/systemd/system/hostapd.service.d/override.conf << EOF
[Unit]
Wants=wpa_supplicant@wlan0.service

[Service]
ExecStartPre=/sbin/iw dev wlan0 interface add uap0 type __ap
ExecStartPre=/bin/ip link set uap0 address 02:a6:32:62:f0:b1
ExecStopPost=-/sbin/iw dev uap0 del
StartLimitInterval=30
StartLimitBurst=10
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
ExecStartPre=/sbin/sysctl -w net.ipv4.ip_forward=1
ExecStartPre=/usr/sbin/iptables -t nat -A POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
ExecStopPost=-/usr/sbin/iptables -t nat -D POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
ExecStopPost=-/sbin/sysctl -w net.ipv4.ip_forward=0
EOF

# Add photobooth host to /etc/banner_add_hosts
cat > /etc/banner_add_hosts << EOF
192.168.50.1 photobooth
EOF

# Copy configs
cp /boot/config/hostapd.conf /etc/hostapd/hostapd.conf
cp /boot/config/dnsmasq.conf /etc/dnsmasq.d/photobooth

# Reload systemctl deamon
systemctl daemon-reload

# Unmask and enable the hostapd service.
systemctl unmask hostapd.service
systemctl enable hostapd.service

# Copy network configuration and set correct MAC address
cp /boot/config/interfaces.conf /etc/network/interfaces
MAC_ADDRESS="$(cat /sys/class/net/wlan0/address)"
MAC_ADDRESS_UPDATED=${MAC_ADDRESS%?}0
MAC_ADDRESS_UPDATED=02${MAC_ADDRESS_UPDATED:2}
sed -i -e "s/<MAC_ADDRESS>/$MAC_ADDRESS_UPDATED/g" /etc/network/interfaces
