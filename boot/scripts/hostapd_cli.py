#!/usr/bin/env python3


import os
import argparse
import json
import time
from helpers import run_command, retry, read_config


class Hostapd():

    hostapd_conf = '/etc/hostapd/hostapd.conf'
    read_inet_passthrough_cmd = '/usr/bin/sudo /sbin/sysctl -n net.ipv4.ip_forward'
    write_inet_passthrough_cmd = '/usr/bin/sudo /sbin/sysctl -w net.ipv4.ip_forward'

    def __init__(self):
        self.config = read_config(self.hostapd_conf)

    def get_config(self, key):
        return self.config.get(key, None)

    def set_config(self, key, val):
        if key[0] == '#':
            run_command(f'sudo /bin/sed -i "s|^#*{key[1:]}=.*|{key}={val}|" {self.hostapd_conf}')
        else:
            run_command(f'sudo /bin/sed -i "s|^#*{key}=.*|{key}={val}|" {self.hostapd_conf}')
        self.config = read_config(self.hostapd_conf)

    def get_inet_passthrough(self):
        output = run_command(self.read_inet_passthrough_cmd)
        if output:
            return output[0]
        else:
            return None

    def set_inet_passthrough(self, state):
        run_command(f'{self.write_inet_passthrough_cmd}={state}')


if __name__ == "__main__":
    print(Hostapd().config)
