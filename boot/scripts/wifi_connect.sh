#!/bin/bash

interface=${1:-wlan0}
network=${2:-0}

echo > /tmp/wifi_connect.log

dhc_tmp_lease=/tmp/dhclient.$interface.leases
dhc_tmp_lease6=/tmp/dhclient6.$interface.leases
if [[ "$network" -eq 0 ]]
then
   dhc_lease=/var/lib/dhcp/dhclient.$interface.leases
   dhc_lease6=/var/lib/dhcp/dhclient6.$interface.leases
else
   dhc_lease=$dhc_tmp_lease
   dhc_lease6=$dhc_tmp_lease6
fi

current=$(wpa_cli -i $interface status | grep -e ^id= | sed -r 's/^id=//')

if iwgetid $interface >> /tmp/wifi_connect.log; then
   # echo "resetting..."
   # wpa_cli terminate >> /tmp/wifi_connect.log
   ip addr flush $interface
   # ip link set dev $interface down
   # ip link set dev $interface up
   sleep 1
fi

# echo "reconnecting..."
# echo > /tmp/wifi_connect_wpa.log && wpa_supplicant -B -P /run/wpa_supplicant.$interface.pid -i $interface -D nl80211,wext -c /etc/wpa_supplicant/wpa_supplicant.conf -f /tmp/wifi_connect_wpa.log
start_at=$(date +"%Y-%m-%d %H:%M:%S")
wpa_cli -i $interface log_level DEBUG >> /tmp/wifi_connect.log
wpa_cli -i $interface select_network $network >> /tmp/wifi_connect.log

n=0
until [ "$n" -ge 10 ]
do
   n=$((n+1)) 
   sleep 1
   journalctl --since "$start_at" | grep -c "Already associated with the selected network" > /dev/null && break
   journalctl --since "$start_at" | grep -c "WPA: Key negotiation completed" > /dev/null && break
done

if [ $? -eq 0 ] 
then
   dhclient -r -pf /var/run/dhclient.$interface.pid $interface >> /tmp/wifi_connect.log
   rm -f $dhc_tmp_lease $dhc_tmp_lease6
   timeout 15 dhclient -4 -v -i -pf /var/run/dhclient.$interface.pid -lf $dhc_lease -I -df $dhc_lease6 $interface >> /tmp/wifi_connect.log 2>&1
   echo "success"
   exit 0
else
   if [[ "$current" -eq 0 ]]
   then
      dhc_lease=/var/lib/dhcp/dhclient.$interface.leases
      dhc_lease6=/var/lib/dhcp/dhclient6.$interface.leases
   else
      dhc_lease=$dhc_tmp_lease
      dhc_lease6=$dhc_tmp_lease6
   fi
   wpa_cli -i $interface select_network $current >> /tmp/wifi_connect.log
   sleep 1
   dhclient -r -pf /var/run/dhclient.$interface.pid $interface >> /tmp/wifi_connect.log
   timeout 15 dhclient -4 -v -i -pf /var/run/dhclient.$interface.pid -lf $dhc_lease -I -df $dhc_lease6 $interface >> /tmp/wifi_connect.log 2>&1
   echo "error"
fi

wpa_cli -i $interface log_level INFO >> /tmp/wifi_connect.log
exit 1
