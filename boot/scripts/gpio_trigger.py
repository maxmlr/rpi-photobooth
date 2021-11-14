#!/usr/bin/env python3
# Process local gpio trigger event

import time
import subprocess
from gpiozero import Button
from signal import pause


BUTTON1_GPIO = 23
BUTTON2_GPIO = 26
last = time.time()
timeout = 5


def send_trigger(action):
    global last
    now = time.time()
    if int(now - last) > timeout:
        last = now
        subprocess.call(["trigger", action])


def send_button1():
    send_trigger(action="p")


def send_button2():
    send_trigger(action="c")


button1 = Button(BUTTON1_GPIO)
button2 = Button(BUTTON2_GPIO)


button1.when_pressed = send_button1
button2.when_pressed = send_button2


pause()
