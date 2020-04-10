#!/usr/bin/env python3


import os
import argparse
import json
import time
from io import StringIO
from configparser import ConfigParser
from helpers import run_command, retry


class Hostapd():

    hostapd_conf = '/etc/hostapd/hostapd.conf'

    def read_config(self):
        config = StringIO()
        config.write('[dummysection]\n')
        config.write(open(self.hostapd_conf).read())
        config.seek(0, os.SEEK_SET)
        cp = ConfigParser()
        cp.read_file(config)
        return dict(cp._sections['dummysection'])

if __name__ == "__main__":
    print(Hostapd().read_config())
