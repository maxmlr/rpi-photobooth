from flask import request
from .. import log, ledpanel, trigger, facerecognition, socketio, event_pool, PHOTOBOOTH_IMG_FOLDER, PHOTOBOOTH_AI_FOLDER
from .backend import set_trigger_lock, get_trigger_lock


@socketio.on('disconnect', namespace='/photobooth')
def photobooth_disconnect():
    set_trigger_lock(False, request.sid)
    log.info(f'photobooth disconnected: {request.sid}')

@socketio.on('manager_connect', namespace='/')
def handle_manager_connect_event(json):
    log.debug(f'new manager connection: {json["data"]}')

@socketio.on('photobooth_connect', namespace='/photobooth')
def handle_photobooth_connect_event(json):
    log.debug(f'new photobooth connection: {json["data"]}')

@socketio.on('gallery_connect', namespace='/gallery')
def handle_gallery_connect_event(json):
    log.debug(f'new gallery connection: {json["data"]}')

@socketio.on('setup_ledpanel_realtime_color_change', namespace='/')
def ledpanel_realtime_color_change(json):
    log.debug(f'received realtime color change: {json}')
    args_dict = {
        'color': json['color']
    }
    ledpanel.send(json['action'], True, float(json['alpha']), args_dict, log)

@socketio.on('trigger', namespace='/photobooth')
def trigger_fire(json):
    log.debug(f'received trigger action: {json["action"]}')
    if json['action'] == "thrill":
        if get_trigger_lock():
            log.info(f'trigger in progress - skipping thirll')
            return False
        else:
            set_trigger_lock(True, request.sid)
    event_pool.spawn_n(trigger.fire, json['action'], json['args'])
    if json['action'] == "renderPic":
        set_trigger_lock(False, request.sid)
        socketio.start_background_task(async_trigger_render, json)
        socketio.sleep(1)
        socketio.start_background_task(async_ai_face_recognition, json)
    elif json['action'] == "errorPic":
        set_trigger_lock(False, request.sid)
    log.debug(f'trigger action resolved: {json["action"]}')
    if json['action'] == "thrill":
        return True

@socketio.on('face_recognition', namespace='/gallery')
def gallery_face_recognition(json):
    log.debug(f'received gallery face_recognition: {json["action"]}')
    if json["action"] == "start":
        facerecognition.start(gallery_face_recognition_filter, request.sid)
        log.debug(f'gallery_face_recognition started for: {request.sid}')
        socketio.emit('debug', {'data': 'started'}, namespace='/gallery', room=request.sid)
    elif json["action"] == "stop":
        facerecognition.stop()
        socketio.emit('debug', {'data': 'stopped'}, namespace='/gallery', room=request.sid)
        log.debug(f'gallery_face_recognition stopped for: {request.sid}')

def gallery_face_recognition_filter(face_identifiers, client_id):
    log.debug(f'Got face recognition filter callback: {face_identifiers}, {client_id}')
    socketio.emit('filter', {'face-identifiers': face_identifiers}, namespace='/gallery', room=client_id)
    log.debug(f'Sent face recognition filter emit successful')

def async_trigger_render(json):
    log.debug(f'got new {json}')
    socketio.emit('newPic', {'img': json['args']}, namespace='/gallery', broadcast=True)

def async_ai_face_recognition(json):
    socketio.start_background_task(facerecognition.processImage, PHOTOBOOTH_IMG_FOLDER / json['args'], PHOTOBOOTH_AI_FOLDER, json, async_ai_face_recognition_callback)

def async_ai_face_recognition_callback(json, face_identifiers):
    log.debug(f'got update {face_identifiers}')
    socketio.emit('updatePic', {'img': json['args'], 'data': {'face-identifiers': ','.join(face_identifiers)}}, namespace='/gallery', broadcast=True)
