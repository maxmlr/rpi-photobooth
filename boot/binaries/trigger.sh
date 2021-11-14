#!/bin/bash
# Trigger photobooth by sending a keypress
# predefined in the photobooth config

if [ $# -eq 0 ]; then
    KEY=space
elif [ $1 = "p" ]; then
    KEY=space
elif [ $1 = "c" ]; then
    KEY=c
fi

[[ ! -f /tmp/trigger.lock ]] && XAUTHORITY=/root/.Xauthority DISPLAY=:0.0 xdotool search --sync --class --onlyvisible chromium-browser windowfocus key $KEY
