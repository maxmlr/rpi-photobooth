from flask import json, jsonify
from . import restapi
from .. import PHOTOBOOTH_IMG_FOLDER, facerecognition

@restapi.route('/ping', methods=['GET'])
def ping_pong():
    return jsonify('pong!')

@restapi.route('/images', methods=['GET'])
def get_images():
    image_pattern = '*.jpg'
    return jsonify([img.name for img in PHOTOBOOTH_IMG_FOLDER.glob(image_pattern)])

@restapi.route('/ai/fr/db', methods=['GET'])
def get_fr_db():
    return jsonify(facerecognition.db)
