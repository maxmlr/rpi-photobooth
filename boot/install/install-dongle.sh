#!/bin/bash

# Install drivers for Edimax EW-7822UTC
wget -q http://downloads.fars-robotics.net/wifi-drivers/install-wifi -O install-wifi && \
 chmod +x install-wifi && \
 UPDATE_SELF=0 ./install-wifi && \
 rm -f install-wifi
