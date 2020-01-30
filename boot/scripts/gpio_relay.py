#!/usr/bin/env python3

import sys
import time
import gpiozero
from signal import pause


relay = None


def set_relay(status):
    if status:
        print("Setting relay: ON")
        relay.on()
    else:
        print("Setting relay: OFF")
        relay.off()


def toggle_relay():
    print("toggling relay")
    relay.toggle()


def main_loop():
    # start by turning the relay off
    set_relay(False)
    while 1:
        # then toggle the relay every second until the app closes
        toggle_relay()
        # wait a second
        time.sleep(1)


if __name__ == "__main__":

    global realy

    RELAY_PIN = int(sys.argv[1])
    STATUS = int(sys.argv[2])

    # create a relay object.
    # Triggered by the output pin going low: active_high=False.
    # Initially off: initial_value=False
    relay = gpiozero.OutputDevice(RELAY_PIN, active_high=False, initial_value=False)

    set_relay(STATUS)
    pause()
    #relay.toggle()
