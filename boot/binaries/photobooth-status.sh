#!/bin/bash

/DietPi/dietpi/dietpi-cpuinfo
echo " --- Services health ---"
echo "  + running: `systemctl list-units --state=running --all | tail -n2 | head -n1`"
echo "  + failed : `systemctl list-units --state=failed --all | head -n1`"
echo
