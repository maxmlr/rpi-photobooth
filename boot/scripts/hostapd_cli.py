#!/usr/bin/env python3


import os
import argparse
import json
import time
from helpers import run_command, retry, read_config


class Hostapd():

    hostapd_conf = '/etc/hostapd/hostapd.conf'

    def __init__(self):
        self.config = read_config(self.hostapd_conf)

    def get_config(self, key):
        return self.config.get(key, None)

    def set_config(self, key, val):
        run_command(f'sudo /bin/sed -i "s|.*{key}=.*|{key}={val}|" {self.hostapd_conf}')
        self.config = read_config(self.hostapd_conf)

if __name__ == "__main__":
    print(Hostapd().read_config())
