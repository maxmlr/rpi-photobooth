from flask import Flask, render_template, request, jsonify
# from wpa_cli import WPAcli

app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1 style='color:blue'>Hello There!</h1>"

# @app.route("/api/v1/manager/wifi/<action>")
# def get_wifis(action):
#     wifi_list = WPAcli().scan()
#     return render_template('index.html', wifi_list = wifi_list)

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
