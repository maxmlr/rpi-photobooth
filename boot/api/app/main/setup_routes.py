from flask import render_template, request, json, jsonify, send_file
from flask_login import login_required
from . import setup
from .. import log, trigger
from helpers import getQRCodeImage, run_command
from hostapd_cli import Hostapd
from wpa_cli import WPAcli
from modules_cli import Modules
from gpio_led import LEDPanel


"""
request.form: key/value pairs of data sent through POST
request.args: key/value pairs of data from the URL query string (through GET)
request.values: generic key/value pair extraction (for both GET, POST)
request.files: to obtain the sent files
request.json: to obtain parsed JSON content
request.method: HTTP method used by the request
"""


@setup.route('', methods=['GET'], endpoint='home')
@login_required
def home():
    ap_args = ap()
    trigger_args = trigger.get_config()
    gpio_args = {
        'relay_mapping': {
            '24': '1',
            '25': '2',
            '16': '3',
            '17': '4',
            '27': '5',
            '22': '6',
            '5': '7',
            '6': '8'
        },
        'gpio_state_mapping': {
            '0': 'on',
            '1': 'off'
        },
        'gpio_func_list': [
            'static'
        ]
    }
    ledpanel_args = {
        'ledpanel_actions_list': LEDPanel.get_actions(),
        'ledpanel_colors_list': LEDPanel.get_colors()
    }
    return render_template('index.html', **{**ap_args , **trigger_args, **ledpanel_args, **gpio_args})


@setup.route('/status', methods=['GET'], endpoint='status')
def status():
    return render_template('status.html', **request.args)


@setup.route('/wifi/list', methods=['GET'], endpoint='wifi-list')
@login_required
def wifi():
    wpa = WPAcli()
    wifi_args = {}
    wifi_list = [ _ for _ in wpa.scan() if _['ssid'] not in ['', 'hidden'] ]
    wpa_status = wpa.status()
    wifi_active = wpa_status.get('ssid', '')
    wifi_args['wifi_list'] = wifi_list
    wifi_args['wifi_active'] = wifi_active
    return render_template('wifi.html', **wifi_args)


@setup.route('/modules/list', methods=['GET'], endpoint='modules-list')
@login_required
def modules():
    m = Modules()
    m.discover()
    modules_args = {}
    clients = m.get_clients()
    remotes = m.get_remotes()
    modules_args['clients'] = clients
    modules_args['remotes'] = remotes
    return render_template('modules.html', **modules_args)


@setup.route('/wifi/connect', methods=['POST'], endpoint='wifi-connect')
@login_required
def wifi_connect():
    wpa = WPAcli()
    ssid = request.form['ssid']
    password = request.form['password']
    # TODO check key_mgmt
    wpa.connect(ssid=ssid, psk=password, key_mgmt='WPA-PSK')
    return jsonify({'success': True})


@setup.route('/wifi/ap/settings', methods=['POST'], endpoint='wifi-ap-settings')
@login_required
def ap_settings():
    hostapd = Hostapd()
    ssid = request.form['ssid']
    password = request.form['password']
    hidden = request.form['hidden']

    update = False
    if ssid and ssid != hostapd.get_config('ssid'):
        hostapd.set_config('ssid', ssid)
        update = True
    if password and password != hostapd.get_config('wpa_passphrase'):
        hostapd.set_config('wpa_passphrase', password)
        hostapd.set_config('rsn_pairwise', 'CCMP')
        hostapd.set_config('wpa', '2')
        hostapd.set_config('wpa_key_mgmt', 'WPA-PSK')
        update = True
    elif password == '' and hostapd.get_config('wpa_passphrase') != None:
        hostapd.set_config('#wpa_passphrase', '')
        hostapd.set_config('#rsn_pairwise', 'CCMP')
        hostapd.set_config('wpa', 'none')
        hostapd.set_config('#wpa_key_mgmt', 'WPA-PSK')
        update = True
    if hidden != hostapd.get_config('ignore_broadcast_ssid'):
        hostapd.set_config('ignore_broadcast_ssid', hidden)
        update = True

    if update:
        log.debug('restarting hostapd...')
        hostapd.restart()

    return jsonify({'success': update})


@setup.route('/wifi/ap/passthrough/<int:status>', methods=['GET'], endpoint='wifi-ap-passthrough')
@login_required
def ap_passthrough(status):
    hostapd = Hostapd()
    hostapd.set_inet_passthrough(status)
    return jsonify({'success': True})


@setup.route('/qr/get/<string:data>', methods=['GET'], endpoint='qr-create')
def get_qr(data):
    ap_qr_bytes = getQRCodeImage(data, box_size=request.args.get('box_size', 10), border=request.args.get('border', 4), returnAs='bytes')
    out = ap_qr_bytes
    return send_file(out, mimetype='image/png', as_attachment=False)


@setup.route('/qr/get/ap', methods=['GET'], endpoint='qr-ap')
def get_qr_ap():
    ap_args = ap(detailed=False)
    ap_auth = 'WPA' if ap_args['ap_auth'] != 'none' else 'nopass'
    ap_name = ap_args['ap_name']
    ap_password = ap_args['ap_password']
    ap_show = ap_args['ap_show']
    data = f'WIFI:T:{ap_auth};S:{ap_name};P:{ap_password};{"H:true;" if ap_show else ""};'
    ap_qr_bytes = getQRCodeImage(data, box_size=request.args.get('box_size', 10), border=request.args.get('border', 4), returnAs='bytes')
    out = ap_qr_bytes
    return send_file(out, mimetype='image/png', as_attachment=False)


@setup.route('/trigger/actions/update', methods=['POST'], endpoint='trigger-actions-update')
def trigger_actions_update():
    json_data = request.get_json()
    trigger.update_config(json_data)
    return jsonify({'success': True})


def ap(detailed=True):
    hostapd = Hostapd()
    ap_args = {}
    ap_name = hostapd.get_config('ssid')
    ap_password = hostapd.get_config('wpa_passphrase')
    ap_show = int(hostapd.get_config('ignore_broadcast_ssid'))
    ap_auth = hostapd.get_config('wpa')
    ap_args['ap_mode'] = hostapd.mode
    ap_args['ap_name'] = ap_name
    ap_args['ap_password'] = '' if ap_password is None else ap_password
    ap_args['ap_show'] = ap_show
    ap_args['ap_auth'] = 'none' if ap_auth is None else ap_auth
    if detailed:
        inet_passthrough = int(hostapd.get_inet_passthrough())
        ap_args['inet_passthrough'] = inet_passthrough
        ap_status_out = hostapd.get_status()
        ap_status_json = json.loads(ap_status_out) if ap_status_out != None else {}
        ap_connections_cnt = ap_status_json.get('client_list_length', 0)
        ap_args['ap_connections_cnt'] = ap_connections_cnt
    return ap_args
