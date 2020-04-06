#!/usr/bin/env python3


import argparse
from Pyro5.compatibility import Pyro4
from helpers import retry


SERVER_IP = 'localhost'
PORT = 9090
ENDPOINT = 'ledpanel.control'


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='LED Panel COntroller.')
    parser.add_argument("action")
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

    @retry(Exception, tries=25, delay=1, backoff=1, verbose=verbose, catchAll=save)
    def send(proxy, *args):
        if verbose:
            print(f'sending: {args}')
        proxy.ledCtl(*args)

    # proxy = Pyro4.Proxy(f'PYRONAME:{ENDPOINT}')
    proxy = Pyro4.Proxy(f'PYRO:{ENDPOINT}@{SERVER_IP}:{PORT}')
    send(proxy, action, resume, brightness, args_dict)
