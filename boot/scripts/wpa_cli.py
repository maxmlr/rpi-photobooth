#!/usr/bin/env python3


import argparse
import json
import time
from collections import OrderedDict
from helpers import run_command, retry


class WPAcli():

    wpa_supplicant_conf = '/etc/wpa_supplicant/wpa_supplicant.conf'
    wpa_cli_bin = '/usr/bin/sudo /sbin/wpa_cli'
    dev_up = '/usr/bin/sudo /sbin/ifup'
    dev_down = '/usr/bin/sudo /sbin/ifdown'
    wifi_connect = '/usr/bin/sudo /opt/photobooth/bin/wifi_connect.sh'

    def __init__(self, interface='wlan0'):
        self.iface = interface
        self.config = self.read_config()
        self.wpa_status = f'{self.wpa_cli_bin} -i {self.iface} status'
        self.wpa_scan = f'{self.wpa_cli_bin} -i {self.iface} scan'
        self.wpa_scan_results = f'{self.wpa_cli_bin} -i {self.iface} scan_results'
        self.wpa_list = f'{self.wpa_cli_bin} -i {self.iface} list_network'
        self.wpa_add = f'{self.wpa_cli_bin} -i {self.iface} add_network'
        self.wpa_set_ssid = f'{self.wpa_cli_bin} -i {self.iface} set_network 1 ssid'
        self.wpa_scan_ssid = f'{self.wpa_cli_bin} -i {self.iface} set_network 1 scan_ssid 1'
        self.wpa_key_mgmt = f'{self.wpa_cli_bin} -i {self.iface} set_network 1 key_mgmt'
        self.wpa_psk = f'{self.wpa_cli_bin} -i {self.iface} set_network 1 psk'
        self.wpa_enable = f'{self.wpa_cli_bin} -i {self.iface} enable_network 1'
        self.wpa_update_conf = f'{self.wpa_cli_bin} -i {self.iface} set update_config 1'
        self.wpa_save_conf = f'{self.wpa_cli_bin} -i {self.iface} save_config'
        self.wpa_select = f'{self.wpa_cli_bin} -i {self.iface} select_network'
        self.wpa_reconnect = f'{self.wpa_cli_bin} -i {self.iface} reconnect'

    def read_config(self):
        with open(self.wpa_supplicant_conf) as f:
            return WpaSupplicantConf(f.readlines())

    def run(self, func_name, kwargs):
        func = getattr(self, func_name, None)
        if func:
            return func(**kwargs)
        else:
            print(f'ERROR: {func_name}() not available.')

    def exec_wpa_cli(self, cmd, statusOnly=True, quiet=True):
        if not quiet:
            print(cmd)
        wpa_cli_out = run_command(cmd)
        if statusOnly:
            return wpa_cli_out[0] if wpa_cli_out else None
        else:
            return wpa_cli_out

    def status(self):
        wpa_status_out = self.exec_wpa_cli(self.wpa_status, statusOnly=False)
        wpa_status_tuples = [_.split("=") for _ in wpa_status_out]
        wpa_status_tuples = [_ for _ in wpa_status_tuples if len(_) == 2]
        if not wpa_status_tuples:
            print(f'ERROR: {wpa_status_out} is not a valid wpa_status response.')
            return {}
        else:
            return dict(wpa_status_tuples)

    def scan(self, isRecursive=False):

        @retry(RuntimeError, tries=5, delay=1, backoff=1, verbose=True)
        def scan_():
            scan_status = self.exec_wpa_cli(self.wpa_scan)
            if not scan_status or scan_status != 'OK':
                raise RuntimeError('WiFi scan error')
            wifi_scan_list_out = self.exec_wpa_cli(self.wpa_scan_results, statusOnly=False)
            if not wifi_scan_list_out:
                raise RuntimeError('WiFi scan result error')
            wifi_scan_header = [ label.strip() for label in wifi_scan_list_out[0].split('/') ]
            wifi_scan_list = [ entry.split('\t') for entry in wifi_scan_list_out[1:] ]
            wifis = []   
            for entry in wifi_scan_list:
                _wifi = {}
                for idx, label in enumerate(wifi_scan_header):
                    val = ('hidden' if entry[idx].find('x00') != -1 else entry[idx]) if idx < len(entry) else ''
                    _wifi[label] = val
                wifis += [_wifi]
            if not isRecursive and len(wifis) == 1:
                return self.scan(isRecursive=True)
            else:
                return wifis

        try:
            return scan_()
        except RuntimeError:
            return []

    def set_network(self, ssid, psk, key_mgmt='WPA-PSK', quiet=True):
        wpa_saved_id_max = None
        wpa_list_out = self.exec_wpa_cli(self.wpa_list, statusOnly=False, quiet=quiet)
        for wpa_saved in wpa_list_out:
            if wpa_saved.startswith('network id'):
                continue
            wpa_saved_id = wpa_saved.split()[0]
            try:
                wpa_saved_id_max = int(wpa_saved_id)
            except ValueError as err:
                print(f'ERROR: {wpa_saved} is not a valid wpa_cli network id.')
                break
        if not wpa_list_out or wpa_saved_id_max == None:
            return (1, 'WPA_CLI list error')
        
        wpa_new_id = None
        if wpa_saved_id_max == 0:
            wpa_add_status = self.exec_wpa_cli(self.wpa_add, quiet=quiet)
            try:
                wpa_new_id = int(wpa_add_status)
            except ValueError as err:
                print(f'ERROR: {wpa_add_status} is not a valid wpa_cli added network id.')
            if not wpa_add_status or wpa_new_id == None:
                return (2, 'WPA_CLI add error')
        else:
            wpa_new_id = wpa_saved_id_max

        wpa_set_ssid_status = self.exec_wpa_cli(f'{self.wpa_set_ssid} \'"{ssid}"\'', quiet=quiet)
        if wpa_set_ssid_status != 'OK':
            return (3, 'WPA_CLI set ssid error')
        
        wpa_scan_ssid_status = self.exec_wpa_cli(self.wpa_scan_ssid, quiet=quiet)
        if wpa_scan_ssid_status != 'OK':
            return (4, 'WPA_CLI set scan_ssid error')

        if not psk:
            psk = '        '
            key_mgmt = 'NONE'
        wpa_key_mgmt_status = self.exec_wpa_cli(f'{self.wpa_key_mgmt} {key_mgmt}', quiet=quiet)
        if wpa_key_mgmt_status != 'OK':
            return (5, 'WPA_CLI set key_mgmt error')
            
        wpa_psk_status = self.exec_wpa_cli(f'{self.wpa_psk} \'"{psk}"\'', quiet=quiet)
        if wpa_psk_status != 'OK':
            return (6, 'WPA_CLI set psk error')

        wpa_enable_status = self.exec_wpa_cli(self.wpa_enable, quiet=quiet)
        if wpa_enable_status != 'OK':
            return (7, 'WPA_CLI enable network error')

        wpa_update_conf_status = self.exec_wpa_cli(self.wpa_update_conf, quiet=quiet)
        if wpa_update_conf_status != 'OK':
            return (8, 'WPA_CLI update config error')

        wpa_save_conf_status = self.exec_wpa_cli(self.wpa_save_conf, quiet=quiet)
        if wpa_save_conf_status != 'OK':
            return (9, 'WPA_CLI save config error')

        # wpa_select_status = self.exec_wpa_cli(f'{self.wpa_select} 1', quiet=quiet)
        # if wpa_select_status != 'OK':
        #     return (10, 'WPA_CLI select network error')

        return (0, 'Successfully changed network')

    def connect(self, ssid, psk, key_mgmt='WPA-PSK', quiet=True):
        connect_status = self.set_network(ssid, psk, key_mgmt, quiet)
        if connect_status[0] > 0:
            return connect_status
        network = 0 if ssid == next(iter(self.config.networks())) else 1
        wifi_connect_out = run_command(f'{self.wifi_connect} {self.iface} {network}')
        wifi_connect_status = wifi_connect_out[-1]
        status = self.status().get('wpa_state')
        if wifi_connect_status == 'success' and status == 'COMPLETED':
            connect_status = (0, status)
        else:
            connect_status = (11, 'ERROR')
        return connect_status


class ParseError(ValueError):
    pass


class WpaSupplicantConf:

    def __init__(self, lines):
        self._fields = OrderedDict()
        self._networks = OrderedDict()

        network = None
        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            if line == "}":
                if network is None:
                    raise ParseError("unxpected '}'")

                ssid = network.pop('ssid', None)
                if ssid is None:
                    raise ParseError('missing "ssid" for network')
                self._networks[dequote(ssid)] = network
                network = None
                continue

            parts = [x.strip() for x in line.split('=', 1)]
            if len(parts) != 2:
                raise ParseError("invalid line: %{!r}".format(line))

            left, right = parts

            if right == '{':
                if left != 'network':
                    raise ParseError('unsupported section: "{}"'.format(left))
                if network is not None:
                    raise ParseError("can't nest networks")

                network = OrderedDict()
            else:
                if network is None:
                    self._fields[left] = right
                else:
                    network[left] = right

    def fields(self):
        return self._fields

    def networks(self):
        return self._networks

    def add_network(self, ssid, **attrs):
        self._networks[ssid] = attrs

    def remove_network(self, ssid):
        self._networks.pop(ssid, None)

    def write(self, f):
        for name, value in self._fields.items():
            f.write("{}={}\n".format(name, value))

        for ssid, info in self._networks.items():
            f.write("\nnetwork={\n")
            f.write('    ssid="{}"\n'.format(ssid))
            for name, value in info.items():
                f.write("    {}={}\n".format(name, value))
            f.write("}\n")


def dequote(v):
    if len(v) < 2:
        return v
    if v.startswith('"') and v.endswith('"'):
        return v[1:-1]
    return v


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='WPA cli Manager.')
    parser.add_argument('action')
    parser.add_argument('-i', '--interface', type=str, default='wlan0')
    args, argv  = parser.parse_known_args()
    args_dict = vars(args)
    
    action = args_dict.pop('action')
    interface = args_dict.pop('interface')

    i = iter([_.replace('-','') for _ in argv])
    print(json.dumps(WPAcli(interface).run(action, {**args_dict, **dict(zip(i, i))})))
