#!/bin/bash
# Start uap0 and wlan0 in specific order 

echo "Starting WiFi AP..."
ifdown --force wlan0 > /tmp/ap-startup.log 2>&1
ifdown --force uap0 >> /tmp/ap-startup.log 2>&1
ifup uap0 >> /tmp/ap-startup.log 2>&1
ifup wlan0 >> /tmp/ap-startup.log 2>&1
echo "WiFi AP enabled."
