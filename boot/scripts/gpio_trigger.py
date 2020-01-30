#!/usr/bin/env python3
# Process local gpio trigger event

import time
import subprocess
from gpiozero import Button
from signal import pause


BUTTON_GPIO = 23
last = time.time()


def send_trigger():
    global last
    now = time.time()
    if int(now - last) > 5:
        last = now
        subprocess.call(["trigger"])


button = Button(BUTTON_GPIO)
button.when_pressed = send_trigger
pause()
