#!/bin/bash

ACTION="$1"
HOSTNAME="$2"
MAC="$3"

if [[ "$ACTION" = "send" ]]
then
    /usr/bin/mosquitto_pub -h photobooth -m `hostname`/"`ip addr show wlan0 | grep link/ether | awk '{print $2}'`" -t photobooth/link/register
elif [[ "$ACTION" = "recieve" ]]
then
    echo `date` - $HOSTNAME [$MAC] >> /tmp/clients_registered.log
    /usr/bin/ndsctl trust $MAC
fi
