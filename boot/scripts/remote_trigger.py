#!/usr/bin/env python
# Sends KEY_SPACE to take a new picture

import time
import uinput


if __name__ == "__main__":
    input_state = True
    if input_state:
        with uinput.Device([uinput.KEY_SPACE]) as device:
            device.emit_combo([uinput.KEY_SPACE])
