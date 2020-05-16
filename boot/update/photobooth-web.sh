#!/bin/bash

echo "Currently installed photobooth release: v`cat /var/www/html/version.html`"

if [ $# -eq 0 ]
  then
    echo "Please specify desired photobooth release: (e.g. `cat /var/www/html/version.html`)."
    exit
fi

PHOTOBOOTH_RELEASE=$1

# update photobooth
echo "Updating photobooth web-interface..."
cp -f /var/www/html/config/my.config.inc.php /tmp/my.config.inc.php
cd /var/www/html
wget -O photobooth.tar.gz https://github.com/andreknieriem/photobooth/releases/download/v${PHOTOBOOTH_RELEASE}/photobooth-${PHOTOBOOTH_RELEASE}.tar.gz && tar xzf photobooth.tar.gz && rm photobooth.tar.gz
echo "v${PHOTOBOOTH_RELEASE}" > /var/www/html/version.html
cd - > /dev/null

# photobooth updates and config
cp -rf /boot/photobooth/manager /var/www/html/
cd /var/www/html/manager
composer install
cd - > /dev/null
cp -f /boot/photobooth/my.config.inc.php /var/www/html/config/latest.my.config.inc.php
mv /tmp/my.config.inc.php /var/www/html/config/my.config.inc.php

# create ai folders
mkdir -p /var/www/html/data/ai

# copy captive portal content
cp -rf /boot/captive /var/www/html
mkdir -p /var/www/html/captive/css
cp -f /var/www/html/resources/css/style.css /var/www/html/captive/css
cp -f /var/www/html/resources/css/rounded.css /var/www/html/captive/css
cp -f /var/www/html/node_modules/font-awesome/css/font-awesome.css /var/www/html/captive/css
cp -f /var/www/html/node_modules/normalize.css/normalize.css /var/www/html/captive/css
cp -rf /var/www/html/resources/fonts /var/www/html/captive
cp -rf /var/www/html/node_modules/font-awesome/fonts /var/www/html/captive
ln -sf /opt/photobooth/flask/api/static /var/www/html/captive
[[ -f /var/www/html/captive/images/bg ]] || convert /var/www/html/resources/img/bg.jpg -quality 25 -resize 1920x1080\> /var/www/html/captive/images/bg

# install vnstat-viewer
rm -rf 
wget https://github.com/dalbenknicker/vnstat-viewer/archive/master.zip && \
 unzip master.zip && mv vnstat-viewer-master/* vnstat-viewer-master/.[!.]* /var/www/html/vnstat && \
 rm -rf master.zip vnstat-viewer-master
cd /var/www/html/vnstat
composer install
cd - > /dev/null
cp -f /boot/config/vnstat-viewer.php /var/www/html/vnstat/include/config.php
grep -qF '<div id="main">' /var/www/html/vnstat/templates/main.tpl || sed -i '/graph.tpl/i <div id="main">' /var/www/html/vnstat/templates/main.tpl
grep -qF '<\div>' /var/www/html/vnstat/templates/main.tpl || sed -i '/gscript.tpl/a <\/div>' /var/www/html/vnstat/templates/main.tpl

# make nginx user owner of /var/www/
chown -R www-data:www-data /var/www/

# photobooth hook
grep -qF photobooth.js /var/www/html/index.php || sed -i '/<\/body>/i \\t<script type="text\/javascript" src="\/static\/js\/photobooth.js"><\/script>' /var/www/html/index.php

echo "Please manually check updates in the photobooth webinterface configs:"
echo " - old: /var/www/html/config/my.config.inc.php"
echo " - new: /var/www/html/config/latest.my.config.inc.php"

echo "Update successful."
