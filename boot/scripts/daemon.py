#!/usr/bin/env python3

"""Daemon."""


from Pyro5.compatibility import Pyro4
from gpio_led import LEDPanel


@Pyro4.expose
@Pyro4.behavior(instance_mode="single")
class Photobooth(object):
    """Photobooth daemon."""

    def __init__(self):
        self.ledPanelCtl = None

    @Pyro4.oneway
    def ledCtl(self, action, resume, brightness, kwargs):
        if not self.ledPanelCtl:
            self.ledPanelCtl = LEDPanel().get_effects()
        self.ledPanelCtl.abort()
        self.ledPanelCtl.run(action, resume, brightness, kwargs)


if __name__ == "__main__":
    daemon = Pyro4.Daemon(host="localhost", port=9090)
    # uri = daemon.register(Photobooth())
    # ns = Pyro4.locateNS()
    # ns.register("ledpanel.control", uri)
    
    # daemon.requestLoop()
    Pyro4.Daemon.serveSimple({
            Photobooth(): 'ledpanel.control',
        },
        daemon=daemon, ns=False, verbose=True
    )
