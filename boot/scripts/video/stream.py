import cv2
from logger import Logger


"""
author: Maximilian Miller <miller.deutschland@gmail.com>
"""

__version__ = 1.0


"""
------------------------------------------------------------------------------------------------------------------------------
VideoCapture settings
------------------------------------------------------------------------------------------------------------------------------
see https://docs.opencv.org/master/d4/d15/group__videoio__flags__base.html
------------------------------------------------------------------------------------------------------------------------------
"""


logger = Logger(__name__, level='DEBUG')
logger.addFileHandler(filename='/var/log/api.log', level='DEBUG')
log = logger.getLogger()


class VideoStream:
    
    def __init__(self, src=0, resolution=(320, 240), fps=32):
        self.src = src
        self.stream = None
        self.resolution = resolution
        self.fps = fps
        self.capture = True
        self.stopped = False
        self.destroyed = False
        self.socketio = None
        self.thread = None

    def init(self, config={}):
        if not self.stream:
            self.set_config(config)
            self.grabbed, self.frame = self.stream.read()
        return self

    def set_config(self, config):
        self.stream = cv2.VideoCapture(self.src)
        self.stream.set(cv2.CAP_PROP_FRAME_WIDTH, self.resolution[0])
        self.stream.set(cv2.CAP_PROP_FRAME_HEIGHT, self.resolution[1])
        self.stream.set(cv2.CAP_PROP_FPS, self.fps)
        for key, val in config.items():
            self.stream.set(key, val)

    def capture_single(self, config={}):
        if not self.stream:
            self.set_config(config)
            grabbed, frame = self.stream.read()
            self.stream.release()
            self.stream = None
        else:
            grabbed, frame = self.stream.read()
        return grabbed, frame

    def destroy(self):
        if self.destroyed:
            self.stream.release()
            self.stream = None
            self.destroyed = False
            log.debug('Stream destroyed')

    def setSocketIO(self, socketio):
        self.socketio = socketio
        return self

    def touch(self):
        if self.socketio is not None:
            self.socketio.sleep()

    def start(self):
        log.info('Stream start signal sent')
        if self.socketio:
            log.debug('Stream using socketio')
            self.socketio.start_background_task(self.update)
        else:
            log.debug('Stream using threading')
            from threading import Thread
            self.thread = Thread(target=self.update, args=())
            self.thread.start()
        return self

    def update(self):
        log.debug('Stream capture started')
        while True:
            if not self.capture:
                self.capture = True
                log.debug('Stream capture stopped')
                self.destroy()
                return
            # log.debug('Stream capturing...')
            self.grabbed, self.frame = self.stream.read()
            self.touch()

    def read(self):
        return self.grabbed, self.frame

    def stop(self, destroy=False):
        log.info('Stream stop signal sent')
        self.stopped = True
        self.destroyed = destroy

    def process(self, func, func_kwargs=None, capture_alternate=True):
        self.start()
        capture_frame = True
        log.debug('Stream process started')
        while True:
            if self.stopped:
                self.capture = False
                self.stopped = False
                log.debug('Stream process stopped')
                return
            if capture_frame:
                # log.debug('Stream processing...')
                func(*self.read(), func_kwargs)
            if capture_alternate:
                capture_frame = not capture_frame
            self.touch()
