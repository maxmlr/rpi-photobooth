from flask import Blueprint

setup = Blueprint('setup', 'setup', url_prefix='/setup', template_folder='templates')
restapi = Blueprint('restapi', 'restapi',  url_prefix='/api/v1', template_folder='templates')

from . import api_routes, setup_routes, login, events
