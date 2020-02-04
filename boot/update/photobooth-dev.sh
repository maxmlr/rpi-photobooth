#!/bin/bash

# Update web interface
echo "Updating photobooth web-interface to current master branch..."
cd /var/www/html
wget -O photobooth_update.zip https://github.com/maxmlr/photobooth/archive/master.zip && unzip photobooth_update.zip && rm photobooth_update.zip
cp -r photobooth-master/* . && rm -rf photobooth-master/
echo "v${PHOTOBOOTH_RELEASE} [ git master ]" > /var/www/html/version.html
chown -R www-data:www-data /var/www/
cd -

echo "Update successful."
