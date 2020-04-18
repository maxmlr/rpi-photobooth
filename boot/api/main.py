from flask import Flask, render_template, request, send_file, jsonify
from flask_cors import CORS
from flask_bootstrap import Bootstrap
from flask_fontawesome import FontAwesome
from helpers import getQRCodeImage, run_command
from wpa_cli import WPAcli
from hostapd_cli import Hostapd

"""
request.form: key/value pairs of data sent through POST
request.args: key/value pairs of data from the URL query string (through GET)
request.values: generic key/value pair extraction (for both GET, POST)
request.files: to obtain the sent files
request.json: to obtain parsed JSON content
request.method: HTTP method used by the request
"""

# configuration
DEBUG = True
BOOTSTRAP_SERVE_LOCAL = True

# instantiate the app
app = Flask(__name__)
app.config.from_object(__name__)
bootstrap = Bootstrap(app)
fa = FontAwesome(app)

# enable CORS
CORS(app, resources={r'/*': {'origins': '*'}})

# sanity check route
@app.route('/ping', methods=['GET'])
def ping_pong():
    return jsonify('pong!')

@app.route("/", methods=['GET'], endpoint='setup.home')
def home():
    ap_args = ap()
    return render_template('index.html', **ap_args)

@app.route("/status", methods=['GET'], endpoint='setup.status')
def status():
    return render_template('status.html', **request.args)

@app.route("/wifi/list", methods=['GET'], endpoint='wifi.list')
def wifi():
    wpa = WPAcli()
    wifi_args = {}
    wifi_list = [ _ for _ in wpa.scan() if _['ssid'] not in ['', 'hidden'] ]
    wpa_status = wpa.status()
    wifi_active = wpa_status.get('ssid', '')
    wifi_args['wifi_list'] = wifi_list
    wifi_args['wifi_active'] = wifi_active
    return render_template('wifi.html', **wifi_args)

def ap():
    hostapd = Hostapd()
    ap_args = {}
    ap_name = hostapd.get_config('ssid')
    ap_password = hostapd.get_config('wpa_passphrase')
    ap_show = int(hostapd.get_config('ignore_broadcast_ssid'))
    inet_passthrough = int(hostapd.get_inet_passthrough())
    ap_connections_cnt = 0
    ap_args['ap_name'] = ap_name
    ap_args['ap_password'] = '' if ap_password is None else ap_password
    ap_args['ap_show'] = ap_show
    ap_args['ap_connections_cnt'] = ap_connections_cnt
    ap_args['inet_passthrough'] = inet_passthrough
    return ap_args

@app.route("/wifi/connect", methods=['POST'], endpoint='wifi.connect')
def wifi_conect():
    wpa = WPAcli()
    ssid = request.form['ssid']
    password = request.form['password']
    # TODO check key_mgmt
    wpa.connect(ssid=ssid, psk=password, key_mgmt='WPA-PSK')
    return jsonify({'success': True})

@app.route('/wifi/ap/settings', methods=['POST'], endpoint='wifi.ap.settings')
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
        print(hidden,hostapd.get_config('ignore_broadcast_ssid'),hidden != hostapd.get_config('ignore_broadcast_ssid'))
    if hidden != hostapd.get_config('ignore_broadcast_ssid'):
        hostapd.set_config('ignore_broadcast_ssid', hidden)
        update = True

    if update:
        run_command('/opt/photobooth/bin/reboot.sh 3', wait=False)
    return jsonify({'success': True})

@app.route('/wifi/ap/passthrough/<int:status>', methods=['GET'], endpoint='wifi.ap.passthrough')
def ap_passthrough(status):
    hostapd = Hostapd()
    hostapd.set_inet_passthrough(status)
    return jsonify({'success': True})

@app.route('/qr/get/<string:data>', methods=['GET'], endpoint='qr.create')
def get_qr(data):
    ap_qr_bytes = getQRCodeImage(data, box_size=request.args.get('box_size', 10), border=request.args.get('border', 4), returnAs='bytes')
    out = ap_qr_bytes
    return send_file(out, mimetype='image/png', as_attachment=False)

if __name__ == "__main__":
    app.run(host='0.0.0.0')
