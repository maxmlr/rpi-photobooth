#!/bin/bash

[[ "$1" = "hostname" ]] && MSG="`hostname`@`hostname -I`" || MSG=$1
TOPIC=$2

/usr/bin/mosquitto_pub -h photobooth -m "${MSG}" -t "${TOPIC}"
