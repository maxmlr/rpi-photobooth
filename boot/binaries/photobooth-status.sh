#!/bin/bash

# Import Photobooth config

. /boot/photobooth.conf

# Import DietPi-Globals --------------------------------------------------------------
. /DietPi/dietpi/func/dietpi-globals
G_PROGRAM_NAME='DietPi-CPU_info'
G_CHECK_ROOT_USER
G_INIT
# Import DietPi-Globals --------------------------------------------------------------

CPU_TEMP_PRINT=''
	Obtain_Cpu_Temp(){

		CPU_TEMP_PRINT=$(print_full_info=1 G_OBTAIN_CPU_TEMP)

	}

CPU_GOV_CURRENT='N/A'
Obtain_Cpu_Gov(){

    if [[ -f '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor' ]]; then

        CPU_GOV_CURRENT=$(</sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

    fi

}

Obtain_Cpu_Temp
Obtain_Cpu_Gov

# Photobooth System Info
echo -e "\n \e[38;5;154m─────────────────────────────────────────────────────\e[0m\n \e[1mPhotobooth v${PHOTOBOOTH_RELEASE} [custom: v${PHOTOBOOTH_UPDATE}]\n \e[38;5;154m─────────────────────────────────────────────────────\e[0m"
echo -e " Device Type  \e[90m|\e[0m     $DEVICE_TYPE"
echo -e " Device ID    \e[90m|\e[0m     $DEVICE_ID"
echo -e " Hostname     \e[90m|\e[0m     $(hostname)"
echo -e " Model        \e[90m|\e[0m     $DEVICE_MODEL"
echo -e " Display      \e[90m|\e[0m     ${DISPLAY_RESOLUTION_X}x${DISPLAY_RESOLUTION_Y}"
echo -e " Headless     \e[90m|\e[0m     $([[ $HEADLESS -eq 0 ]] && echo "no" || echo "yes" )"
echo -e " Kiosk mode   \e[90m|\e[0m     $([[ $BOOT_TO_KIOSK -eq 0 ]] && echo "no" || echo "yes" )"
echo -e " ngrok        \e[90m|\e[0m     $([[ -z "$NGROK_TOKEN" ]] && echo "-" || echo "token ok" )"
echo -e " photomateur  \e[90m|\e[0m     $([[ -z "$PHOTOMATEUR_API_TOKEN" ]] && echo "-" || echo "token ok" )"
echo -e " Service up   \e[90m|\e[0m     `systemctl list-units --state=running --all | tail -n2 | head -n1`"
echo -e " Service fail \e[90m|\e[0m     `systemctl list-units --state=failed --all | head -n1`"
if [[ "$1" != "banner" ]]
then
echo -e " Architecture \e[90m|\e[0m     $(uname -m)"
echo -e " Temperature  \e[90m|\e[0m     $CPU_TEMP_PRINT"
echo -e " Governor     \e[90m|\e[0m     $CPU_GOV_CURRENT"
if [[ $CPU_GOV_CURRENT == 'ondemand' || $CPU_GOV_CURRENT == 'conservative' ]]; then
    echo -e " Throttle up  \e[90m|\e[0m     $(grep -m1 '^[[:blank:]]*CONFIG_CPU_USAGE_THROTTLE_UP=' /DietPi/dietpi.txt | sed 's/^[^=]*=//')% CPU usage"
fi
echo
fi
