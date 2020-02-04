#!/bin/bash
# If required export GPIO, then set state

ACTION=$1
IFS=',' read -ra GPIOS <<< "$2"
IFS=',' read -ra STATES <<< "$3"
IFS=',' read -ra FUNCSS <<< "$4"
PARAMS="${@:5}"
for i in "${!GPIOS[@]}"; do
    GPIO=${GPIOS[$i]}
    STATE=${STATES[$i]}
    echo "GPIO: ${ACTION}, ${GPIO} -> ${STATE} [${PARAMS}]" >> /tmp/gpio.log

    [[ -e /sys/class/gpio/gpio${GPIO} ]] || echo "${GPIO}" > /sys/class/gpio/export && echo "out" > /sys/class/gpio/gpio${GPIO}/direction

    echo "${STATE}" > /sys/class/gpio/gpio${GPIO}/value

    #echo "${GPIO}" > /sys/class/gpio/unexport
done
