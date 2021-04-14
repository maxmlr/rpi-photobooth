import sys
import json
import logging
from pathlib import Path
from helpers import run_command
from ctl_ledpanel import LEDpanelControl


CONFIG = '/opt/photobooth/conf/custom/trigger.json'
GPIO_CMD = '/usr/bin/sudo relay'
REMOTE_CMD = '/usr/bin/sudo /usr/bin/mosquitto_pub'


class Trigger():

    def __init__(self, ledpanel=None, logger=None):
        self.actions = {}
        self.read_config()
        self.ledpanel = LEDpanelControl(verbose=True, save=False) if ledpanel is None else ledpanel
        if logger is not None:
            self.log = logger
        else:
            logging.basicConfig(filename='/var/log/flask/api.log', level=logging.DEBUG)
            self.log = logging

    def read_config(self):
        config = Path(CONFIG)
        if config.exists():
            with config.open() as fin:
                config = json.load(fin)
                if config:
                    self.actions = {}
                self.preprocess_config(config)

    def preprocess_config(self, config):
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
        self.preprocess_config(config)
        with Path(CONFIG).open('w') as fout:
            json.dump(config, fout)

    def get_config(self):
        trigger_json = {}
        with Path(CONFIG).open() as fin:
            trigger_json = json.load(fin)
        return trigger_json

    def fire(self, action, params=''):
        query_action = str(params) if action == "startCountdown" else "default"

        # gpios, states, funcs
        gpio_actions = self.actions[action]['gpio'].get(query_action, [[], [], []])

        # actions, colors, brightness, args
        ledpanel_actions = self.actions[action]['ledpanel'].get(query_action, [])

        # remotes, payloads
        remote_actions = self.actions[action]['remote'].get(query_action, [])
        if gpio_actions[0]:
            cmd = f"{GPIO_CMD} {action} {','.join(gpio_actions[0])} {','.join(gpio_actions[1])} {','.join(gpio_actions[2])} {params}"
            run_command(cmd, wait=False)
        for slot in ledpanel_actions:
            args_dict = slot['args'] if slot['args'] != '' else {}
            args_dict['color'] = slot['color']
            args_dict['iterations'] = 1
            self.ledpanel.send(slot['action'], False, float(slot['brightness']), args_dict, None)
        for slot in remote_actions:
            cmd = f"{REMOTE_CMD} -m {slot['func']}{slot['state']} -t photobooth/remote/{slot['remoteuid']}"
            run_command(cmd, wait=False)
        self.log.debug(f'Trigger {action} fired successfully.')


if __name__ == "__main__":
    t = Trigger()
    t.fire(sys.argv[1])
