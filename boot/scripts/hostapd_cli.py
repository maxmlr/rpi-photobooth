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
    captive_portal_status_cmd = '/usr/bin/sudo /usr/bin/ndsctl json'
    restart_cmd = '/usr/bin/sudo /usr/sbin/service hostapd restart'
    lsusb_cmd = '/usr/bin/lsusb'

    def __init__(self, config=None):
        self.hostapd_conf = config if config else self.hostapd_conf
        self.config = read_config(self.hostapd_conf)
        self.mode = self.getMode()

    def get_config(self, key):
        return self.config.get(key, None)

    def set_config(self, key, val):
        if key[0] == '#':
            run_command(f'/usr/bin/sudo /bin/sed -i "s|^#*{key[1:]}=.*|{key}={val}|" {self.hostapd_conf}')
        else:
            run_command(f'/usr/bin/sudo /bin/sed -i "s|^#*{key}=.*|{key}={val}|" {self.hostapd_conf}')
        self.config = read_config(self.hostapd_conf)

    def get_inet_passthrough(self):
        output = run_command(self.read_inet_passthrough_cmd)
        if output:
            return output[0]
        else:
            return None

    def set_inet_passthrough(self, state):
        run_command(f'{self.write_inet_passthrough_cmd}={state}')

    def getMode(self):
        mode = 0
        for out in run_command(self.lsusb_cmd):
            if out.lower().find('edimax') != -1:
                mode += 1
        return mode

    def get_status(self):
        output = run_command(self.captive_portal_status_cmd)
        if output:
            parsed = ''
            for line in output:
                if parsed.startswith('ndsctl:'):
                    return None
                if parsed and parsed[-1] == "}" and line == "{":
                    break
                parsed += line
            return parsed
        else:
            return None

    def restart(self):
        run_command(self.restart_cmd)


if __name__ == "__main__":
    h = Hostapd()
    print(h.config, h.mode)
