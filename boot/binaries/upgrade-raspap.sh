#!/bin/bash

# git pull - update repo at /var/www/html/rpi.
echo "Upgrading RaspAP..."
git --work-tree=/var/www/html/rpi --git-dir=/var/www/html/rpi/.git pull origin master

# Move the high-res favicons to the web root.
mv /var/www/html/rpi/app/icons/* /var/www/html/rpi

# Set the files ownership to www-data user.
chown -R www-data:www-data /var/www/html/rpi

# Move the RaspAP configuration file to the correct location.
mv /var/www/html/rpi/raspap.php /etc/raspap/
chown -R www-data:www-data /etc/raspap

# Move the HostAPD logging and service control shell scripts to the correct location.
mv /var/www/html/rpi/installers/*log.sh /etc/raspap/hostapd

# Set ownership and permissions for logging and service control scripts.
chown -c root:www-data /etc/raspap/hostapd/*.sh
chmod 750 /etc/raspap/hostapd/*.sh

# Copy the configuration files for dhcpcd, dnsmasq, and hostapd.
mv /var/www/html/rpi/config/default_hostapd /etc/default/hostapd

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

# Restart the hostapd and raspap service.
echo "Restarting hostapd and raspap services..."
systemctl restart hostapd.service
systemctl restart raspap.service

echo "Upgrade successful."
