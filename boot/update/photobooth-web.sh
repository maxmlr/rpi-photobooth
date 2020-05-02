#!/bin/bash

echo "Currently installed photobooth release: v`cat /var/www/html/version.html`"

if [ $# -eq 0 ]
  then
    echo "Please specify desired photobooth release and udpate versions: (e.g. `cat /var/www/html/version.html`)."
    exit
fi

PHOTOBOOTH_RELEASE=$1
PHOTOBOOTH_UPDATE=$2

# Update web interface
echo "Updating photobooth web-interface..."
cp /var/www/html/config/my.config.inc.php /tmp/my.config.inc.php
cd /var/www/html
wget -O photobooth.tar.gz https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth.tar.gz && rm photobooth.tar.gz
# TODO: replace master with v${PHOTOBOOTH_UPDATE}
wget -O photobooth_update.tar.gz https://github.com/maxmlr/photobooth/archive/master.tar.gz && tar xzf photobooth_update.tar.gz && rm photobooth_update.tar.gz
# TODO: replace master with ${PHOTOBOOTH_UPDATE}
cp -r photobooth-master/* . && rm -rf photobooth-master/
echo "v${PHOTOBOOTH_RELEASE} [${PHOTOBOOTH_UPDATE}]" > /var/www/html/version.html
chown -R www-data:www-data /var/www/
cd - > /dev/null

# photobooth config
cp -f /boot/config/photobooth.webinterface.php /var/www/html/config/my.config.inc_latest.php
chown -R www-data:www-data /var/www/html/config/my.config.inc_latest.php
mv /tmp/my.config.inc.php /var/www/html/config/my.config.inc.php
chown -R www-data:www-data /var/www/html/config/my.config.inc.php
echo "Please manually check updates in the photobooth webinterface configs:"
echo " - old: /var/www/html/config/my.config.inc.php"
echo " - new: /var/www/html/config/my.config.inc_latest.php"

echo "Update successful."
