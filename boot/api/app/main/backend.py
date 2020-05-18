from pathlib import Path
from .. import log, GLOBALS, PHOTOBOOTH_IMG_FOLDER, PHOTOBOOTH_AI_FOLDER

TRIGGER_LOCK = Path('/tmp/trigger.lock')

def set_trigger_lock(lock, client_id):
    if lock:
        GLOBALS['trigger_lock'] = client_id
        TRIGGER_LOCK.touch()
    else:
        if GLOBALS['trigger_lock'] == client_id:
            GLOBALS['trigger_lock'] = None
            if TRIGGER_LOCK.exists():
                TRIGGER_LOCK.unlink()

def get_trigger_lock():
    return GLOBALS['trigger_lock'] is not None
