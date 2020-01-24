#!/bin/bash

echo "Currently installed photobooth release: v`cat /var/www/html/version.html`"

if [ $# -eq 0 ]
  then
    echo "Please specify photobooth release for upgrade (e.g. `cat /var/www/html/version.html`)."
    exit
fi

PHOTOBOOTH_RELEASE=$1

# git pull - update repo at /var/www/html/rpi.
echo "Upgrading photobooth web-interface..."
git --work-tree=/var/www/html --git-dir=/var/www/html/.git pull origin master

# update photobooth
cd /var/www/html
wget https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && rm photobooth-${PHOTOBOOTH_RELEASE}.tar.gz
echo "v${PHOTOBOOTH_RELEASE}" > /var/www/html/version.html
chown -R www-data:www-data /var/www/
cd -

echo "Upgrade successful."
