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
sed -i -e "s/<MAC_ADDRESS>/$MAC_ADDRESS_UPDATED/g" /etc/network/interfaces

# Replace brcmfmac driver
# fixes WiFi freezes; references:
# https://github.com/raspberrypi/linux/issues/2453#issuecomment-610206733
# https://community.cypress.com/docs/DOC-19375
# https://community.cypress.com/servlet/JiveServlet/download/19375-1-53475/cypress-fmac-v5.4.18-2020_0402.zip
mv /lib/firmware/brcm/brcmfmac43455-sdio.bin~ /lib/firmware/brcm/brcmfmac43455-sdio.bin~
mv /lib/firmware/brcm/brcmfmac43455-sdio.clm_blob /lib/firmware/brcm/brcmfmac43455-sdio.clm_blob~
cp /boot/firmware/wifi/brcmfmac43455-sdio.bin /lib/firmware/brcm/
cp /boot/firmware/wifi/brcmfmac43455-sdio.clm_blob /lib/firmware/brcm/
