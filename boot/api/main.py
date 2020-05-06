from os import environ
from pathlib import Path
from dotenv import load_dotenv
from flask import Flask, Blueprint, render_template, request, send_file, json, jsonify, redirect, url_for, abort
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from flask_login import LoginManager, UserMixin, login_user, logout_user, current_user, login_required
from flask_socketio import SocketIO
from helpers import getQRCodeImage, run_command
from wpa_cli import WPAcli
from hostapd_cli import Hostapd
from modules_cli import Modules
from gpio_led import LEDPanel
from ctl_ledpanel import LEDpanelControl
from trigger import Trigger
import logging

"""
request.form: key/value pairs of data sent through POST
request.args: key/value pairs of data from the URL query string (through GET)
request.values: generic key/value pair extraction (for both GET, POST)
request.files: to obtain the sent files
request.json: to obtain parsed JSON content
request.method: HTTP method used by the request
"""

# configuration
load_dotenv()
DEBUG = True
SECRET_KEY = environ.get('SECRET_KEY')
API_KEY = environ.get('API_KEY')
logging.basicConfig(filename='/var/log/api.log', level=logging.DEBUG)
log = logging.getLogger("Photobooth-API")

# blueprints
setup = Blueprint('setup', 'setup', url_prefix='/setup')
restapi = Blueprint('restapi', 'restapi',  url_prefix='/api/v1')

# photobooth controller
ledpanel = LEDpanelControl()
trigger = Trigger(ledpanel=ledpanel, logger=log)

# login Manager
login_manager = LoginManager()

# instantiate the app
app = Flask(__name__)
app.config.from_object(__name__)
login_manager.init_app(app)

# enable CORS
CORS(app, resources={r'/*': {'origins': '*'}})

# enable websockets
socketio = SocketIO(app)

# users
users = {'admin@photomateur.de': {'password': 'admin'}}
class User(UserMixin):
    pass

@login_manager.user_loader
def user_loader(email):
    if email not in users:
        return
    user = User()
    user.id = email
    return user

@login_manager.request_loader
def request_loader(request):
    email = request.form.get('email')
    if email not in users:
        return
    user = User()
    user.id = email
    if request.form['password'] == users[email]['password']:
        return user
    else:
        return None

@setup.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        if current_user.is_authenticated:
            return redirect(url_for('setup.home'))
        return render_template('login.html')
    email = request.form['email']
    if email not in users:
        return render_template('login.html', **{ 'errors': "Email is not associated with a user." })
    if request.form['password'] == users[email]['password']:
        user = User()
        user.id = email
        login_user(user)
        return redirect(url_for('setup.home'))

    return render_template('login.html', **{ 'errors': "Wrong password." })

@setup.route('/logout')
def logout():
    logout_user()
    return render_template('login.html')

@login_manager.unauthorized_handler
def unauthorized_handler():
    return redirect(url_for('setup.login'))

@app.context_processor
def inject_enumerate():
    return dict(enumerate=enumerate)

@restapi.route('/ping', methods=['GET'])
def ping_pong():
    return jsonify('pong!')

@setup.route('', methods=['GET'], endpoint='home')
@login_required
def home():
    ap_args = ap()
    trigger_args = trigger_read()
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

def ap(detailed=True):
    hostapd = Hostapd()
    ap_args = {}
    ap_name = hostapd.get_config('ssid')
    ap_password = hostapd.get_config('wpa_passphrase')
    ap_show = int(hostapd.get_config('ignore_broadcast_ssid'))
    ap_auth = hostapd.get_config('wpa')
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

def trigger_read():
    trigger_json_file = Path('/opt/photobooth/conf/custom/trigger.json')
    trigger_json = {}
    with trigger_json_file.open() as fin:
        trigger_json = json.load(fin)
    return trigger_json

def trigger_write(json_data):
    trigger_json_file = Path('/opt/photobooth/conf/custom/trigger.json')
    with trigger_json_file.open('w') as fout:
         json.dump(json_data, fout)

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
        run_command('/opt/photobooth/bin/reboot.sh 3', wait=False)
    return jsonify({'success': True})

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
    trigger_write(json_data)
    trigger.update_config(json_data)
    return jsonify({'success': True})

@socketio.on('manager_connect', namespace='/')
def handle_manager_connect_event(json):
    log.debug(f'new manager connection: {json["data"]}')

@socketio.on('setup_ledpanel_realtime_color_change', namespace='/')
def ledpanel_realtime_color_change(json):
    log.debug(f'received realtime color change: {json}')
    args_dict = {
        'color': json['color']
    }
    ledpanel.send(json['action'], False, float(json['alpha']), args_dict, log)

@socketio.on('photobooth_connect', namespace='/photobooth')
def handle_manager_connect_event(json):
    log.debug(f'new photobooth connection: {json["data"]}')

@socketio.on('trigger', namespace='/photobooth')
def trigger_fire(json):
    trigger.fire(json['action'], params=json['args'])
    log.debug(f'received trigger action: {json["action"]}')

# register blueprints
app.register_blueprint(restapi)
app.register_blueprint(setup)

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', debug=True)
