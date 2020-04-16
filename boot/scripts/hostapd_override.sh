#!/bin/bash
# photobooth hostapd service override

if [[ "$1" == "pre" ]]
then
    [[ -f /tmp/hostapd_up.lock ]] || /sbin/iw dev wlan0 interface add uap0 type __ap
elif [[ "$1" == "post" ]]
then
    [[ -f /tmp/hostapd_up.lock ]] || /sbin/iw dev uap0 del
fi
