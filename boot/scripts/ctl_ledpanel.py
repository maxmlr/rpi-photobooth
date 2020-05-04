#!/usr/bin/env python3


import argparse
from Pyro5.api import Proxy
from gpio_led import LEDPanel
from helpers import retry


class LEDpanelControl:

    SERVER_IP = 'localhost'
    PORT = 9090
    ENDPOINT = 'ledpanel.control'
    
    def __init__(self, verbose=False, save=False):
        self.verbose = verbose
        self.save = save

    def send(self, action, resume=False, brightness=1, args_dict={}, logger=None):
        @retry(Exception, tries=25, delay=1, backoff=1, verbose=self.verbose, catchAll=self.save)
        def send_(verbose, *args):
            if verbose:
                print(f'sending: {args}')
            proxy = Proxy(f'PYRO:{self.ENDPOINT}@{self.SERVER_IP}:{self.PORT}')
            proxy.ledCtl(*args)
        send_(self.verbose, action, resume, brightness, args_dict)


if __name__ == "__main__":
    actions = LEDPanel.get_actions()
    parser = argparse.ArgumentParser(description='LED Panel Controller.')
    parser.add_argument(
        "action",
        help=f"Available actions: {', '.join(actions)}",
        metavar='action'
    )
    parser.add_argument("-c", "--color", type=str, default='black')
    parser.add_argument("-b", "--brightness", type=float, default=1)
    parser.add_argument("-i", "--iterations", type=int, default=1)
    parser.add_argument("-r", "--resume", action='store_true')
    parser.add_argument("-v", "--verbose", action='store_true')
    parser.add_argument("-s", "--save", action='store_true')
    args, argv  = parser.parse_known_args()

    args_dict = vars(args)
    action = args_dict.pop('action')
    resume = args_dict.pop('resume')
    brightness = args_dict.pop('brightness')
    verbose = args_dict.pop('verbose')
    save = args_dict.pop('save')

    LEDpanelControl(verbose, save).send(action, resume, brightness, args_dict)
