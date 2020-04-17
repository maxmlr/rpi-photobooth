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

# create backend interfaces
hostapd = Hostapd()
wpa = WPAcli()

# sanity check route
@app.route('/ping', methods=['GET'])
def ping_pong():
    return jsonify('pong!')

@app.route("/", endpoint='setup.home')
def home():
    if request.method == 'GET':
        template_args = {}
        wifi_list = [ _ for _ in wpa.scan() if _['ssid'] not in ['', 'hidden'] ]
        wpa_status = wpa.status()
        wifi_active = wpa_status.get('ssid', '')
        ap_name = hostapd.get_config('ssid')
        ap_show = int(hostapd.get_config('ignore_broadcast_ssid'))
        ap_connections_cnt = 0
        template_args['wifi_list'] = wifi_list
        template_args['wifi_cnt'] = len(wifi_list)
        template_args['wifi_active'] = wifi_active
        template_args['ap_name'] = ap_name
        template_args['ap_show'] = ap_show
        template_args['ap_connections_cnt'] = ap_connections_cnt
        return render_template('index.html', **template_args)

@app.route("/status", methods=['GET'], endpoint='setup.status')
def status():
    return render_template('status.html', **request.args)

@app.route('/wifi/ap/show/<int:status>', methods=['GET'], endpoint='wifi.ap.show')
def ap_show(status):
    hostapd.set_config('ignore_broadcast_ssid', status)
    run_command('/opt/photobooth/bin/reboot.sh 3', wait=False)
    return jsonify({'success': True})

@app.route('/qr/get/<string:data>', methods=['GET'], endpoint='qr.create')
def get_qr(data):
    ap_qr_bytes = getQRCodeImage(data, box_size=request.args.get('box_size', 10), border=request.args.get('border', 4), returnAs='bytes')
    out = ap_qr_bytes
    return send_file(out, mimetype='image/png', as_attachment=False)

if __name__ == "__main__":
    app.run(host='0.0.0.0')
