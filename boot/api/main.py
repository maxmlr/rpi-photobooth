from flask import Flask, render_template, request, send_file, jsonify
from flask_cors import CORS
from flask_bootstrap import Bootstrap
from flask_fontawesome import FontAwesome
from helpers import getQRCodeImage
from wpa_cli import WPAcli


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

@app.route("/dev")
def set_bg():
    return render_template('bgselect.html')

@app.route("/", endpoint='setup.home')
def home():
    if (request.script_root).startswith('/api'):
        return jsonify('photobooth_api:v1')
    template_args = {}
    wifi_list = [] #[ _ for _ in WPAcli().scan() if _['ssid'] not in ['', 'hidden'] ]
    wifi_active = 'penthouse_2.4'
    ap_name = 'photobooth'
    ap_connections_cnt = 0
    template_args['wifi_list'] = wifi_list
    template_args['wifi_cnt'] = len(wifi_list)
    template_args['wifi_active'] = wifi_active
    template_args['ap_name'] = ap_name
    template_args['ap_connections_cnt'] = ap_connections_cnt
    return render_template('index.html', **template_args)

@app.route('/qr/get/<string:data>', methods=['GET'], endpoint='qr.create')
def get_qr(data):
    ap_qr_bytes = getQRCodeImage(data, box_size=request.args.get('box_size', 10), border=request.args.get('border', 4), returnAs='bytes')
    out = ap_qr_bytes
    print (out)
    return send_file(out, mimetype='image/png', as_attachment=False)

# # handling form data
# @app.route('/form-handler', methods=['POST', 'GET'])
# def handle_data():
#     # request.form: key/value pairs of data sent through POST
#     # request.args: key/value pairs of data from the URL query string (through GET)
#     # request.values: generic key/value pair extraction (for both GET, POST)
#     # request.files: to obtain the sent files
#     # request.json: to obtain parsed JSON content
#     # request.method: HTTP method used by the request
#     respose = request.args if request.args else request.form
#     return jsonify(respose)

if __name__ == "__main__":
    app.run(host='0.0.0.0')
