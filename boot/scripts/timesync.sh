#!/bin/bash
# Start timesync in background
echo "Starting manual timesync (async)"
systemctl start systemd-timesyncd.service & sleep 60 && systemctl stop systemd-timesyncd.service &
