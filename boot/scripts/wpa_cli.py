#!/usr/bin/env python3


import argparse
import json
import time
from helpers import run_command, retry


class WPAcli():

    def __init__(self, interface='wlan0'):
        self.iface  = interface

    def run(self, func_name, kwargs):
        func = getattr(self, func_name, None)
        if func:
            return func(**kwargs)
        else:
            print(f'ERROR: {func_name}() not available.')

    def scan(self):

        @retry(RuntimeError, tries=3, delay=1, backoff=1, verbose=True)
        def scan_():
            _scan_status = run_command('wpa_cli -i wlan0 scan')
            scan_status = _scan_status[0] if _scan_status else None
            # if not scan_status or scan_status != 'OK':
            raise RuntimeError('WiFi scan error')
            _wifi_list = run_command('wpa_cli -i wlan0 scan_results')
            wifi_header = [ label.strip() for label in _wifi_list[0].split('/') ]
            wifi_list = [ entry.split('\t') for entry in _wifi_list[1:] ]
            wifis = []
            for entry in wifi_list:
                _wifi = {}
                for idx, label in enumerate(wifi_header):
                    val = ('hidden' if entry[idx].find('x00') != -1 else entry[idx]) if idx < len(entry) else ''
                    _wifi[label] = val
                wifis += [_wifi]
            wifi_json = json.dumps(wifis)
            return wifi_json

        try:
            return scan_()
        except RuntimeError:
            return json.dumps([{'bssid': 'na', 'frequency': 'na', 'signal level': '0', 'flags': 'na', 'ssid': 'na'}])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='WPA cli Manager.')
    parser.add_argument('action')
    parser.add_argument('-i', '--interface', type=str, default='wlan0')
    args, argv  = parser.parse_known_args()
    args_dict = vars(args)
    
    action = args_dict.pop('action')
    interface = args_dict.pop('interface')

    print(WPAcli(interface).run(action, args_dict))
