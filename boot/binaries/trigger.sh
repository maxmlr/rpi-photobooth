#!/bin/bash
# Trigger photobooth by sending a keypress
# predefined in the photobooth config

[[ ! -f /tmp/trigger.lock ]] && XAUTHORITY=/root/.Xauthority DISPLAY=:0.0 xdotool search --sync --class --onlyvisible chromium-browser windowfocus key space
