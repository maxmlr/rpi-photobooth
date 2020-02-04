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
cd /var/www/html
wget -O photobooth.tar.gz https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth.tar.gz && rm photobooth.tar.gz
wget -O photobooth_update.tar.gz https://github.com/maxmlr/photobooth/archive/v${PHOTOBOOTH_UPDATE}.tar.gz && tar xzf photobooth_update.tar.gz && rm photobooth_update.tar.gz
cp -r photobooth-${PHOTOBOOTH_UPDATE}/* . && rm -rf photobooth-${PHOTOBOOTH_UPDATE}/
echo "v${PHOTOBOOTH_RELEASE} [${PHOTOBOOTH_UPDATE}]" > /var/www/html/version.html
chown -R www-data:www-data /var/www/
cd -

echo "Update successful."
