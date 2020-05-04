#!/usr/bin/env python3

"""Daemon."""


from Pyro5.api import Daemon, expose, behavior, serve, current_context, oneway
from gpio_led import LEDPanel


@expose
@behavior(instance_mode="single")
class Photobooth(object):
    """Photobooth daemon."""

    def __init__(self):
        self.ledPanelCtl = None

    @oneway
    def ledCtl(self, action, resume, brightness, kwargs):
        if not self.ledPanelCtl:
            self.ledPanelCtl = LEDPanel().get_effects()
        self.ledPanelCtl.abort()
        self.ledPanelCtl.run(action, resume, brightness, kwargs)


if __name__ == "__main__":
    daemon = Daemon(host="localhost", port=9090) 
    uri = daemon.register(Photobooth, 'ledpanel.control')

    daemon.requestLoop()
