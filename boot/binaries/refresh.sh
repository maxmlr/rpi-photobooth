#!/bin/bash
# Trigger photobooth refresh

XAUTHORITY=/root/.Xauthority DISPLAY=:0.0 xdotool search --sync --class --onlyvisible chromium-browser windowfocus key F5
