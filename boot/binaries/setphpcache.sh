#!/bin/bash

if [[ "$1" -eq 0 ]]
then
    mv /etc/php/7.3/mods-available/apcu.ini /etc/php/7.3/mods-available/apcu.ini~ && \
    mv /etc/php/7.3/mods-available/opcache.ini /etc/php/7.3/mods-available/opcache.ini~ && \
    systemctl restart php7.3-fpm.service
elif [[ "$1" -eq 1 ]]
    mv /etc/php/7.3/mods-available/apcu.ini~ /etc/php/7.3/mods-available/apcu.ini && \
    mv /etc/php/7.3/mods-available/opcache.ini~ /etc/php/7.3/mods-available/opcache.ini && \
    systemctl restart php7.3-fpm.service
fi
