#!/bin/bash
# When wireless client AP mode is enabled, this script handles starting
# up network services in a specific order and timing to avoid race condi$

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=raspap
DESC="Service control for RaspAP"
CONFIGFILE="/etc/raspap/hostapd.ini"

positional=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -i|--interface)
    interface="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--seconds)
    seconds="$2"
    shift # past argument
    shift # past value
    ;;
esac
done
set -- "${positional[@]}"

#echo "Stopping network services..."
systemctl stop hostapd.service
#systemctl stop dnsmasq.service
#systemctl stop dhcpcd.service

if [ -r "$CONFIGFILE" ]; then
    declare -A config
    while IFS=" = " read -r key value; do
        config["$key"]="$value"
    done < "$CONFIGFILE"

    if [ "${config[WifiAPEnable]}" = 1 ]; then
        if [ "${interface}" = "uap0" ]; then
            #echo "Removing uap0 interface..."
            #iw dev uap0 del

            #echo "Adding uap0 interface to ${config[WifiManaged]}"
            #iw dev ${config[WifiManaged]} interface add uap0 type __ap
            # Bring up uap0 interface
            #ifup uap0

            echo "Enabling IP forwarding and NAT..."
            sysctl -w net.ipv4.ip_forward=1
            #iptables -t nat -A POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE
            nft add table nat
            nft add chain nat postrouting { type nat hook postrouting priority 100 \; }
            nft add rule nat postrouting ip saddr 192.168.50.0/24 oif wlan0 masquerade
            #nft list ruleset
        fi
    fi
fi

# Start services, mitigating race conditions
echo "Starting network services..."
systemctl start hostapd.service
sleep "${seconds}"

#systemctl start dhcpcd.service
#sleep "${seconds}"

systemctl restart dnsmasq.service

sleep 1

ifdown --force wlan0 > /tmp/ap-startup.log 2>&1
ifdown --force uap0 > /tmp/ap-startup.log 2>&1
ifup uap0 > /tmp/ap-startup.log 2>&1
ifup wlan0 > /tmp/ap-startup.log 2>&1

echo "RaspAP service start DONE"
