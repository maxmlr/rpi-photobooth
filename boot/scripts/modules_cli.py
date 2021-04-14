#!/usr/bin/env python3


import os
import argparse
import time
from pathlib import Path
from helpers import run_command


class Modules():

    registration_log = Path('/tmp/clients_registered.log')
    available_log = Path('/tmp/clients_available.log')
    discover_cmd = '/usr/bin/sudo /usr/bin/mosquitto_pub -m discover -t photobooth/link'

    def __init__(self):
        self.registered = self.read_registration()
        self.available = self.read_available()

    def read_registration(self):
        parsed = {}
        if self.registration_log.exists():
            with self.registration_log.open() as fin:
                for line in fin:
                    line = line.strip()
                    if line:
                        date, details = line.split(' - ')
                        hostname, mac = details.split()
                        mac = mac[1:-1]
                        parsed[hostname] = (date, mac)
        return parsed

    def read_available(self):
        parsed = {}
        if self.available_log.exists():
            with self.available_log.open() as fin:
                for line in fin:
                    line = line.strip()
                    if line:
                        hostname, ip = line.split('@')
                        parsed [hostname] = ip
        return parsed

    def discover(self):
        if self.available_log.exists():
            os.remove(self.available_log)
        run_command(self.discover_cmd)
        time.sleep(3)
        self.available = self.read_available()

    def get_clients(self):
        registered = dict([ (k,v) for k,v in self.registered.items() if k.startswith('photobooth-c') ])
        available = dict([ (k,v) for k,v in self.available.items() if k.startswith('photobooth-c') ])
        return {"registered": registered, "available": available}

    def get_remotes(self):
        registered = dict([ (k,v) for k,v in self.registered.items() if k.startswith('photobooth-r') ])
        available = dict([ (k,v) for k,v in self.available.items() if k.startswith('photobooth-r') ])
        return {"registered": registered, "available": available}


if __name__ == "__main__":
    m = Modules()
    print(m.get_clients())
    m.discover()
    print(m.get_remotes())
