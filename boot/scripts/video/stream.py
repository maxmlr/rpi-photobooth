import cv2
from logger import Logger


"""
------------------------------------------------------------------------------------------------------------------------------
VideoCapture settings
------------------------------------------------------------------------------------------------------------------------------
0. CV_CAP_PROP_POS_MSEC Current position of the video file in milliseconds.
1. CV_CAP_PROP_POS_FRAMES 0-based index of the frame to be decoded/captured next.
2. CV_CAP_PROP_POS_AVI_RATIO Relative position of the video file
3. CV_CAP_PROP_FRAME_WIDTH Width of the frames in the video stream.
4. CV_CAP_PROP_FRAME_HEIGHT Height of the frames in the video stream.
5. CV_CAP_PROP_FPS Frame rate.
6. CV_CAP_PROP_FOURCC 4-character code of codec.
7. CV_CAP_PROP_FRAME_COUNT Number of frames in the video file.
8. CV_CAP_PROP_FORMAT Format of the Mat objects returned by retrieve() .
9. CV_CAP_PROP_MODE Backend-specific value indicating the current capture mode.
10. CV_CAP_PROP_BRIGHTNESS Brightness of the image (only for cameras).
11. CV_CAP_PROP_CONTRAST Contrast of the image (only for cameras).
12. CV_CAP_PROP_SATURATION Saturation of the image (only for cameras).
13. CV_CAP_PROP_HUE Hue of the image (only for cameras).
14. CV_CAP_PROP_GAIN Gain of the image (only for cameras).
15. CV_CAP_PROP_EXPOSURE Exposure (only for cameras).
16. CV_CAP_PROP_CONVERT_RGB Boolean flags indicating whether images should be converted to RGB.
17. CV_CAP_PROP_WHITE_BALANCE Currently unsupported
18. CV_CAP_PROP_RECTIFICATION Rectification flag for stereo cameras (note: only supported by DC1394 v 2.x backend currently)
------------------------------------------------------------------------------------------------------------------------------
"""


logger = Logger(__name__, level="DEBUG")
logger.addFileHandler(filename='/var/log/ai.log', level="DEBUG")
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

    def init(self):
        if not self.stream:
            self.stream = cv2.VideoCapture(self.src)
            self.stream.set(3, self.resolution[0])
            self.stream.set(4, self.resolution[1])
            self.stream.set(5, self.fps)
            self.grabbed, self.frame = self.stream.read()
        if not self.socketio and not self.thread:
            from threading import Thread
        return self

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
        return self.frame

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
                func(self.read(), func_kwargs)
            if capture_alternate:
                capture_frame = not capture_frame
            self.touch()
