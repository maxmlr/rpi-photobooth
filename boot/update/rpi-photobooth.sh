#!/bin/bash

# Update binaries
for binary in /boot/binaries/*.sh; do cp $binary /usr/bin/`basename $binary .sh`; chmod +x /usr/bin/`basename $binary .sh`; done

# TODO update managed services

# TODO update /DietPi/config.txt

# TODO update python modules

# TODO update lighttpd

# TODO update mqtt-launcher

# TODO update xorg settings

# TODO update /var/lib/dietpi/dietpi-autostart/custom.sh

# TODO update /var/lib/dietpi/postboot.d/

# TODO update systemctl services

# TODO update /DietPi/dietpi.txt
