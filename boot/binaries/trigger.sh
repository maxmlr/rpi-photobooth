#!/bin/bash
# Trigger photobooth by sending a keypress
# predefined in the photobooth config

XAUTH_FILE=`ls /tmp/serverauth* | head -n1`
XAUTHORITY=${XAUTH_FILE} DISPLAY=:0.0 xdotool search --sync --class --onlyvisible chromium-browser windowfocus key space
