#!/bin/bash

ACTION=$1
GPIO=$2
STATE=$3
echo "GPIO: ${ACTION}, ${GPIO} -> ${STATE}" >> /tmp/gpio.log

[[ -e /sys/class/gpio/gpio${GPIO} ]] || echo "${GPIO}" > /sys/class/gpio/export && echo "out" > /sys/class/gpio/gpio${GPIO}/di$

echo "${STATE}" > /sys/class/gpio/gpio${GPIO}/value

#echo "${GPIO}" > /sys/class/gpio/unexport