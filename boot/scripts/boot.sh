#!/bin/bash
# boot service

# check correct splash screen settings
[[ `grep -c tty3 /boot/cmdline.txt` -eq 0 ]] && sed -i -e "s/tty1/tty3/g" /boot/cmdline.txt
[[ `grep -c splash /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ splash &/' /boot/cmdline.txt
[[ `grep -c logo.nologo /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ logo.nologo &/' /boot/cmdline.txt
[[ `grep -c vt.global_cursor_default /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ vt.global_cursor_default=0 &/' /boot/cmdline.txt
[[ `grep -c loglevel /boot/cmdline.txt` -eq 0 ]] && sed -i 's/$/ loglevel=3 &/' /boot/cmdline.txt
[[ `grep -c vt.global_cursor_default=0 /boot/cmdline.txt` -eq 0 ]] && sed -i -e "s/vt.global_cursor_default=[0,1]/vt.global_cursor_default=0/g" /boot/cmdline.txt

dongles=$(lsusb | grep -ic edimax)
[[ -d /opt/photobooth/conf/ap-default ]] && ln -fs /opt/photobooth/conf/ap-default/interfaces /etc/network/interfaces
if [[ -d /opt/photobooth/conf/ap-$dongles ]]
then
    ln -fs /opt/photobooth/conf/ap-$dongles/interfaces /etc/network/interfaces
    ln -fs /opt/photobooth/conf/ap-$dongles/hostapd.conf /etc/hostapd/hostapd.conf
    if [[ -f /opt/photobooth/conf/ap-$dongles/hostapd2.conf ]] 
    then
        ln -fs /opt/photobooth/conf/ap-$dongles/hostapd2.conf /etc/hostapd/hostapd2.conf
        systemctl start hostapd@hostapd2
    else
        rm -f /etc/hostapd/hostapd2.conf
    fi
    ln -fs /opt/photobooth/conf/ap-$dongles/dnsmasq.conf /etc/dnsmasq.d/photobooth.conf
    ln -fs /opt/photobooth/conf/ap-$dongles/nodogsplash.conf /etc/nodogsplash/nodogsplash.conf
fi
