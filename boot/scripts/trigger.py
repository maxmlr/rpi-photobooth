import sys
import json
import logging
from pathlib import Path
from helpers import run_command
from ctl_ledpanel import LEDpanelControl


CONFIG = '/opt/photobooth/conf/custom/trigger.json'
GPIO_CMD = '/usr/bin/sudo relay'
REMOTE_CMD = '/usr/bin/sudo /usr/bin/mosquitto_pub -h photobooth'


class Trigger():

    def __init__(self, ledpanel=None, logger=None):
        self.actions = {}
        self.read_config()
        self.ledpanel = LEDpanelControl(verbose=True, save=False) if ledpanel is None else ledpanel
        if logger is not None:
            self.log = logger
        else:
            logging.basicConfig(filename='/var/log/api.log', level=logging.DEBUG)
            self.log = logging

    def read_config(self):
        config = Path(CONFIG)
        if config.exists():
            with config.open() as fin:
                config = json.load(fin)
                if config:
                    self.actions = {}
                for action in config['actions']:
                    self.actions[action['trigger']] = {
                        'gpio_raw': {},
                        'gpio': {},
                        'ledpanel': {},
                        'remote': {}
                    }
                    for sub in action['gpio']:
                        self.actions[action['trigger']]['gpio_raw'][sub['name']] = sub['slots']
                        gpio_actions = [[], [], []]
                        for slot in sub['slots']:
                            gpio_actions[0] += [slot['gpio']]
                            gpio_actions[1] += [slot['state']]
                            gpio_actions[2] += [slot['func']]
                        self.actions[action['trigger']]['gpio'][sub['name']] = gpio_actions
                    for sub in action['ledpanel']:
                         self.actions[action['trigger']]['ledpanel'][sub['name']] = sub['slots']
                    for sub in action['remote']:
                         self.actions[action['trigger']]['remote'][sub['name']] = sub['slots']

    def reload_config(self):
        self.read_config()

    def update_config(self, config):
        if config:
            self.actions = {}
        for action in config['actions']:
            self.actions[action['trigger']] = {
                'gpio': action['gpio'],
                'ledpanel': action['ledpanel'],
                'remote': action['remote']
            }

    def fire(self, action, params=''):
        query_action = str(params) if action == "countdown" else "default"

        # gpios, states, funcs
        gpio_actions = self.actions[action]['gpio'][query_action]

        # actions, colors, brightness, args
        ledpanel_actions = self.actions[action]['ledpanel'][query_action]

        # remotes, payloads
        remote_actions = self.actions[action]['remote'][query_action]

        if gpio_actions[0]:
            cmd = f"{GPIO_CMD} {action} {','.join(gpio_actions[0])} {','.join(gpio_actions[1])} {','.join(gpio_actions[2])} {params}"
            run_command(cmd, wait=False)
        for action in ledpanel_actions:
            args_dict = action['args'] if action['args'] != '' else {}
            args_dict['color'] = action['color']
            args_dict['iterations'] = 1
            self.ledpanel.send(action['action'], False, float(action['brightness']), args_dict, None)
        for action in remote_actions:
            cmd = f"{REMOTE_CMD} -m {action['func']}{action['state']} -t photobooth/remote/{action['remoteuid']}"
            run_command(cmd, wait=False)


if __name__ == "__main__":
    t = Trigger()
    t.fire(sys.argv[1])
