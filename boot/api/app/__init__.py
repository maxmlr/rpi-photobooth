import eventlet 
eventlet.monkey_patch(
    os=False,
    select=False,
    socket=False,
    thread=True,
    time=False
)
from os import environ
from dotenv import load_dotenv
from pathlib import Path
from flask import Flask
from flask_socketio import SocketIO
from flask_login import LoginManager
from flask_cors import CORS
from logger import Logger
from ctl_ledpanel import LEDpanelControl
from trigger import Trigger
from ai.gallery import FaceRecognition


load_dotenv(dotenv_path='/boot/photobooth.conf')
load_dotenv()
DEBUG = True
SECRET_KEY = environ.get('SECRET_KEY')
API_KEY = environ.get('API_KEY')
ADMIN_USER = environ.get('ADMIN_EMAIL')
ADMIN_PASSWORD = environ.get('ADMIN_PASSWORD')
PHOTOBOOTH_HTML_ROOT = Path("/var/www/html")
PHOTOBOOTH_IMG_FOLDER = PHOTOBOOTH_HTML_ROOT / Path("data/images")
PHOTOBOOTH_AI_FOLDER = PHOTOBOOTH_HTML_ROOT / Path("data/ai")

logger = Logger(__name__, level="DEBUG")
logger.addFileHandler(filename='/var/log/flask/api.log', level="DEBUG")
log = logger.getLogger()

socketio = SocketIO(async_mode ='eventlet')
login_manager = LoginManager()

event_pool = eventlet.GreenPool(5)

# photobooth controller
ledpanel = LEDpanelControl()
trigger = Trigger(ledpanel=ledpanel, logger=log)
facerecognition = FaceRecognition()

# photobooth globals
GLOBALS = {
    'trigger_lock': None
}


def create_app(debug=False):
    # create the app
    app = Flask(__name__)
    app.config.from_object(__name__)

    # enable CORS
    CORS(app, resources={r'/*': {'origins': '*'}})

    # register blueprints
    from .main import restapi, setup
    app.register_blueprint(restapi)
    app.register_blueprint(setup)

    # init login manager
    login_manager.init_app(app)

    # init socketio
    socketio.init_app(app)
    facerecognition.setSocketIO(socketio).init()

    # add context processors
    @app.context_processor
    def inject_enumerate():
        return dict(enumerate=enumerate)
    
    return app
