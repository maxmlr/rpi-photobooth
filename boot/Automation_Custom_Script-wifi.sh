#!/bin/bash
# Simultaneous AP and Managed Mode Wifi on Raspberry Pi
# based on https://github.com/lukicdarkoo/rpi-wifi

# Error management
set -o errexit
set -o pipefail
set -o nounset

usage() {
    cat 1>&2 <<EOF
Configures simultaneous AP and Managed Mode Wifi on Raspberry Pi

USAGE:
    rpi-wifi -a <ap_ssid> [<ap_password>] -c <client_ssid> [<client_password>]
    
    rpi-wifi -a MyAP myappass -c MyWifiSSID mywifipass

PARAMETERS:
    -a, --ap      	AP SSID & password
    -c, --client    Client SSID & password
    -i, --ip        AP IP
    -u, --url       AP URL

FLAGS:
    -n, --no-internet   Disable IP forwarding
    -h, --help          Show this help
EOF
    exit 0
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--client)
    CLIENT_SSID="$2"
    CLIENT_PASSPHRASE="$3"
    shift
    shift
    shift
    ;;
    -a|--ap)
    AP_SSID="$2"
    AP_PASSPHRASE="$3"
    shift
    shift
    shift
    ;;
    -i|--ip)
    ARG_AP_IP="$2"
    shift
    shift
    ;;
    -u|--url)
    ARG_AP_URL="$2"
    shift
    shift
    ;;
    -h|--help)
    usage
    shift
	;;
    -n|--no-internet)
    NO_INTERNET="true"
    shift
    ;;
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]-na}"

[ ${AP_SSID+x} ] || usage

MAC_ADDRESS="$(cat /sys/class/net/wlan0/address)"
AP_IP=${ARG_AP_IP:-'192.168.10.1'}
AP_IP_BEGIN=`echo "${AP_IP}" | sed -e 's/\.[0-9]\{1,3\}$//g'`
AP_URL=${ARG_AP_URL:-'raspberrypi'}

# Install dependencies
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt -y update && apt -y install dnsmasq hostapd iptables-persistent

# Populate `/etc/udev/rules.d/70-persistent-net.rules`
bash -c 'cat > /etc/udev/rules.d/70-persistent-net.rules' << EOF
SUBSYSTEM=="ieee80211", ACTION=="add|change", ATTR{macaddress}=="${MAC_ADDRESS}", KERNEL=="phy0", \
  RUN+="/sbin/iw phy phy0 interface add ap0 type __ap", \
  RUN+="/bin/ip link set ap0 address ${MAC_ADDRESS}
EOF

# Populate `/etc/dnsmasq.conf`
bash -c 'cat > /etc/dnsmasq.conf' << EOF
interface=lo,ap0
no-dhcp-interface=lo,wlan0
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=${AP_IP_BEGIN}.50,${AP_IP_BEGIN}.150,12h
addn-hosts=/etc/banner_add_hosts
EOF

# Populate `/etc/banner_add_hosts`
bash -c 'cat > /etc/banner_add_hosts' << EOF
192.168.10.1 ${AP_URL}
EOF

# Populate `/etc/hostapd/hostapd.conf`
bash -c 'cat > /etc/hostapd/hostapd.conf' << EOF
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
interface=ap0
driver=nl80211
ssid=${AP_SSID}
hw_mode=g
channel=11
wmm_enabled=0
macaddr_acl=0
auth_algs=1
$([ $AP_PASSPHRASE ] && echo "wpa=2")
$([ $AP_PASSPHRASE ] && echo "wpa_passphrase=${AP_PASSPHRASE}")
$([ $AP_PASSPHRASE ] && echo "wpa_key_mgmt=WPA-PSK")
$([ $AP_PASSPHRASE ] && echo "wpa_pairwise=TKIP CCMP")
$([ $AP_PASSPHRASE ] && echo "rsn_pairwise=CCMP")
EOF

if [ ! -z ${CLIENT_SSID+x} ]
then
# Populate `/etc/wpa_supplicant/wpa_supplicant.conf`
bash -c 'cat > /etc/wpa_supplicant/wpa_supplicant.conf' << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="${CLIENT_SSID}"
    scan_ssid=1
    key_mgmt=WPA-PSK
    $([ $CLIENT_PASSPHRASE ] && echo "psk=\"${CLIENT_PASSPHRASE}\"")
}
EOF
fi

# Populate `/etc/network/interfaces.d/ap0`
bash -c 'cat > /etc/network/interfaces.d/ap0' << EOF
allow-hotplug ap0
iface ap0 inet static
address ${AP_IP}
netmask 255.255.255.0
hostapd /etc/hostapd/hostapd.conf
EOF

# Populate `/bin/start_wifi.sh`
bash -c 'cat > /bin/rpi-wifi.sh' << EOF
echo 'Starting Wifi AP and client...'
sleep 30
/sbin/iw dev wlan0 interface add ap0 type __ap
/sbin/ifdown --force wlan0 && /sbin/ifdown --force ap0 && /sbin/ifup ap0 && /sbin/ifup wlan0
$([ "${NO_INTERNET-}" != "true" ] && echo "/sbin/sysctl -w net.ipv4.ip_forward=1")
$([ "${NO_INTERNET-}" != "true" ] && echo "/usr/sbin/iptables -t nat -A POSTROUTING -s ${AP_IP_BEGIN}.0/24 ! -d ${AP_IP_BEGIN}.0/24 -j MASQUERADE")
$([ "${NO_INTERNET-}" != "true" ] && echo "/bin/systemctl restart dnsmasq")
EOF
chmod +x /bin/rpi-wifi.sh

# Configure cron job
# bash -c 'cat > /etc/systemd/system/rpi-wifi.service' << EOF
# [Unit]
# Description=Simultaneous AP and Managed Mode Wifi on Raspberry Pi
# Requires=network.target
# After=network.target  
#
# [Service]
# ExecStart=/bin/bash -c 'rpi-wifi.sh'
# User=root
#
# [Install]
# WantedBy=multi-user.target
# EOF
# systemctl daemon-reload
# systemctl enable rpi-wifi.service
crontab -l | { cat; echo "@reboot /bin/rpi-wifi.sh"; } | crontab -

# mask hostapd to avoid auto start of service
systemctl mask hostapd

# Finish
echo "Wifi configuration is finished! Please reboot your Raspberry Pi to apply changes..."
