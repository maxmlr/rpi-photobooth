#!/bin/bash

########################
# --- RaspAP Setup --- #
########################

# git clone the files to /var/www/html/rpi and source install script
mkdir -p /var/www/html
raspap_webroot_dir="/var/www/html/rpi"
[ -d "$raspap_webroot_dir" ] && rm -rf $raspap_webroot_dir
git clone --single-branch --branch master https://github.com/billz/raspap-webgui $raspap_webroot_dir
git --git-dir=$raspap_webroot_dir/.git --work-tree=$raspap_webroot_dir checkout tags/$RASPAP_RELEASE -b $RASPAP_RELEASE

# Source RaspAP install script and overwrite defaults
source $raspap_webroot_dir/installers/common.sh
set +o errexit
set +o errtrace
export assume_yes=0
export ovpn_option=0
export webroot_dir="$raspap_webroot_dir"

# RaspAP install helper functions
# Outputs a RaspAP Install log line
function _install_log() {
    echo -e "\033[1;32mRaspAP Install: $*\033[m"
}

# Outputs a RaspAP Install Error log line and exits with status code 1
function _install_error() {
    echo -e "\033[1;37;41mRaspAP Install Error: $*\033[m"
    exit 1
}

# Outputs a RaspAP Warning line
function _install_warning() {
    echo -e "\033[1;33mWarning: $*\033[m"
}

# Outputs a RaspAP divider
function _install_divider() {
    echo -e "\033[1;32m***************************************************************$*\033[m"
}

# RaspAP setup
# Note: vnstat and qrencode were installed earlier 
_get_linux_distro
_create_raspap_directories
_check_for_old_configs
_change_file_ownership
_create_hostapd_scripts
_create_lighttpd_scripts
_move_config_file
# _default_configuration ?
if [ ! -f "$webroot_dir/includes/config.php" ]; then
    sudo cp "$webroot_dir/config/config.php" "$webroot_dir/includes/config.php"
fi
# _configure_networking ?
# _patch_system_files ?
if [ ! -f $raspap_sudoers ]; then
    _install_log "Adding raspap.sudoers to ${raspap_sudoers}"
    sudo cp "$webroot_dir/installers/raspap.sudoers" $raspap_sudoers || _install_error "Unable to apply raspap.sudoers to $raspap_sudoers"
    sudo chmod 0440 $raspap_sudoers || _install_error "Unable to change file permissions for $raspap_sudoers"
fi
# _install_complete ?

# Unmask and enable the hostapd service.
systemctl unmask hostapd.service
systemctl enable hostapd.service

# Change according to photobooth requirements
cp /boot/config/hostapd.conf /etc/hostapd/hostapd.conf
cp /boot/config/dnsmasq.conf /etc/dnsmasq.conf
cp /boot/config/dhcpcd.conf /etc/dhcpcd.conf
cp /boot/config/raspap.config.php /var/www/html/rpi/includes/config.php
sed -i -E "s/('RASPI_VERSION', )'.*'/\1'$RASPAP_RELEASE'/g" /var/www/html/rpi/includes/config.php
chown www-data:www-data /var/www/html/rpi/includes/config.php

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
