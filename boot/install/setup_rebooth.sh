#!/bin/bash

while [[ $(grep -c "Installation completed" /var/tmp/dietpi/logs/dietpi-firstrun-setup.log) == 0 ]]
do
    sleep 5
done
sleep 30
reboot
