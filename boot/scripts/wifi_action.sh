#!/bin/bash

# redirect all output into a logfile
exec 1>> /tmp/wifi.log 2>&1

case "$1" in
wlan0|wlan1|wlan2)
    case "$2" in
    CONNECTED)
        # do stuff on connect with wlanX
        echo $(date) - $1 connected
        /opt/photobooth/bin/register.sh send
        /usr/bin/refresh
        ;;
    DISCONNECTED)
        # do stuff on disconnect with wlanX
        echo $(date) - $1 disconnected
        while [[ "$(wpa_cli -i $1 status | grep wpa_state | sed -r 's/^wpa_state=//')" != "COMPLETED" ]]
        do
            echo $(date) - $1 reconnecting...
            wpa_cli -i $1 reconnect > /dev/null
            sleep 5
        done
        ;;
    *)
        >&2 echo $(date) - empty or undefined event for $1: "$2"
        exit 1
        ;;
    esac
    ;;

*)
    >&2 echo empty or undefined interface: "$1"
    exit 1
    ;;
esac
