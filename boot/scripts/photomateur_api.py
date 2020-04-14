#!/usr/bin/env python3


import os
import requests
import time
import json
import pystemd.journal
from pystemd.systemd1 import Unit
from helpers import retry, source, inlineReplace, run_command


class PhotomateurAPI:

    photobooth_config = '/boot/photobooth.conf'
    entrypoint = 'https://admin.photomateur.de/api/v1'

    def __init__(self):
        env = source(self.photobooth_config)
        self.register_token = env.get('PHOTOMATEUR_REGISTER_TOKEN')
        self.api_token = env.get('PHOTOMATEUR_API_TOKEN')
        self.device_id = env.get('DEVICE_ID')
        self.device_model = env.get('DEVICE_MODEL')
        self.device_type = env.get('DEVICE_TYPE')
        self.headers = {
            'Accept': 'application/json'
        }
        self.available = False
        self.check_connectivity()
        if self.available and not self.api_token:
            self.register()

    def check_connectivity(self):

        @retry(RuntimeError, tries=3, delay=5, backoff=1, verbose=True)
        def check_connectivity_():
            return self.get('device/ping').get('message') == 'pong'
        
        status = False
        try:
            status = check_connectivity_()
        except Exception as err:
            print(f'PhotomateurAPI ERROR: {err}')
        finally:
            # print(f'PhotomateurAPI connected: {status}')
            self.available = status

    def check_control_request(self):
        try:
            if not self.api_token:
                print('PhotomateurAPI ERROR: api_token missing')
            else:
                response = self.post('device/control/status')
                response_msg = response.get('message', None)
                if response_msg != None:
                    pass
                    # print(f'Control request response: {response_msg}')
                else:
                    print(f'PhotomateurAPI ERROR - control: {response}')
                unit = Unit(b'ngrok@ssh\\x20http.service')
                unit.load()
                status = (unit.Unit.ActiveState).decode()
                if response_msg == 1 and status != 'active':
                    print ('Initiating remote control...')
                    cmd = 'systemctl start ngrok@"ssh\\x20http".service'
                    run_command(cmd)
                    retries = 10
                    while status != 'active' and retries > 0:
                        time.sleep(1)
                        retries -= 1
                        status = (unit.Unit.ActiveState).decode()
                    if status == 'active':
                        tunnels_detailed = requests.get('http://127.0.0.1:4040/api/tunnels').json()['tunnels']
                        tunnels = dict([(t['public_url'].split(":")[0], t['public_url']) for t in tunnels_detailed])
                        self.post('device/control/callback', {'status': 'up', 'tunnels': json.dumps(tunnels)})
                    else:
                        self.post('device/control/callback', {'status': 'error', 'tunnels': json.dumps({})})
                elif response_msg == 0 and status == 'active':
                    print ('Exiting remote control...')
                    cmd = 'systemctl stop ngrok@"ssh\\x20http".service'
                    run_command(cmd)
                    self.post('device/control/callback', {'status': 'down', 'tunnels': json.dumps({})})
        except Exception as err:
            print(f'PhotomateurAPI ERROR: {err}')

    def register(self):
        try:
            if not self.api_token:
                print('API registering device...')
                data = {
                    'type': self.device_type,
                    'model': self.device_model,
                    'api_token': self.register_token
                }
                response = self.post('device/register', data)
                api_token = response.get('api_token', None)
                if api_token != None:
                    print('API registration successful.')
                    self.api_token = api_token
                    inlineReplace(self.photobooth_config, r'PHOTOMATEUR_API_TOKEN=', f'PHOTOMATEUR_API_TOKEN="{self.api_token}"')
                else:
                    print(f'PhotomateurAPI ERROR - registration: {response}')
            else:
                print(f'Device already registered as: {self.device_id}')
        except RuntimeError as err:
            print(f'PhotomateurAPI ERROR: {err}')

    def update(self, status='ok', payload={}, statusFile=None):
        if statusFile and os.path.exists(statusFile):
            status_file = None
            payload_file = {'message': []}
            with open(statusFile) as fin:
                for line in fin:
                    if status_file == None:
                        status_file = line.strip()
                    else:
                        payload_file['message'] += [line.strip()]
            if status_file != None:
                status = status_file
            if payload_file['message']:
                payload = payload_file
        try:
            if not self.api_token:
                print('PhotomateurAPI ERROR: api_token missing')
            else:
                data = {
                    'status': status,
                    'payload': json.dumps(payload)
                }
                response = self.post('device/report', data)
                response_msg = response.get('message', None)
                if response_msg != None:
                    pass
                    # print(f'Update response: {response_msg}')
                else:
                    print(f'PhotomateurAPI ERROR - update: {response}')
        except Exception as err:
            print(f'PhotomateurAPI ERROR: {err}')


    def get(self, endpoint, data={}):
        if 'device_id' not in data:
            data['device_id'] = self.device_id
        if 'api_token' not in data:
            data['api_token'] = self.api_token
        r = requests.get(url = f'{self.entrypoint}/{endpoint}', data = data, headers = self.headers)
        json = r.json()
        if r.status_code == 200:
            return json
        else:
            print(f'ERROR {r.status_code} for api GET request: {endpoint}')
            if json.get('message') == 'Unauthenticated.':
                print(f'PhotomateurAPI ERROR - failed to authenticate.')
            return {}

    def post(self, endpoint, data={}):
        if 'device_id' not in data:
            data['device_id'] = self.device_id
        if 'api_token' not in data:
            data['api_token'] = self.api_token
        r = requests.post(url = f'{self.entrypoint}/{endpoint}', data = data, headers = self.headers)
        json = r.json()
        if r.status_code == 200:
            return json
        else:
            print(f'ERROR {r.status_code} for api POST request: {endpoint}')
            if json.get('message') == 'Unauthenticated.':
                print(f'PhotomateurAPI ERROR - failed to authenticate.')
            return {}

if __name__ == "__main__":

    api = PhotomateurAPI()
    api.update(statusFile='/tmp/api.status')
    api.check_control_request()
