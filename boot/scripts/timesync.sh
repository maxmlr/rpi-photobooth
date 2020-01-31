#!/bin/bash
# Start timesync in background

systemctl start systemd-timesyncd.service & sleep 60 && systemctl stop systemd-timesyncd.service
