import eventlet
import random
import string
import json
import pickle
import cv2
import imutils
import face_recognition
import numpy as np
from pathlib import Path
from PIL import Image, ImageDraw
from timeit import default_timer as timer
from logger import Logger
from video.stream import VideoStream


"""
author: Maximilian Miller <miller.deutschland@gmail.com>
"""

__version__ = 1.0


logger = Logger(__name__, level='DEBUG')
# logger.addConsoleHandler()
logger.addFileHandler(filename='/var/log/api.log', level='DEBUG')
log = logger.getLogger()

DATA_FOLDER = Path('/opt/photobooth/data')
FR_BASE_FOLDER = DATA_FOLDER / 'facerecognition'
DB_PATH = DATA_FOLDER / 'gallery.json'
IMG_PATTERN = '*.jpg'


class FaceRecognition:

    known_face_encodings = []
    known_face_identifiers = []

    def __init__(self):
        log.info('FaceRecognition: init...')
        self.stream = None
        self.socketio = None
        self.thread = None
        self.db = {}
        self.audience = {}
        self.audience_reported = set()
        log.debug('FaceRecognition: loading data...')
        self.load_data()
        self.load_db()
        log.debug(f'FaceRecognition: got {len(self.known_face_encodings)} encodings')
        log.info('FaceRecognition: ready')

    def init(self):
        self.stream = VideoStream(resolution=(320, 180), fps=30)
        if self.socketio:
            self.stream.setSocketIO(self.socketio)
        return self

    def setSocketIO(self, socketio):
        self.socketio = socketio
        return self

    def touch(self):
        if self.socketio:
             self.socketio.sleep()

    def load_db(self):
        db = Path(DB_PATH)
        if db.exists():
            with db.open() as fin:
                self.db = json.load(fin)        
    
    def save_db(self):
        with Path(DB_PATH).open('w') as fout:
            json.dump(self.db, fout)

    def update_db(self, id, face_identifiers):
        self.db[id] = face_identifiers
        self.save_db()

    def randomName(self, stringLength=8):
        letters = string.ascii_lowercase
        return ''.join(random.choice(letters) for i in range(stringLength))

    def start(self, callback=None, client_id=None):
        self.audience = {}
        self.audience_reported = set()
        self.stream.init()
        if self.socketio:
            log.debug('Stream RealTime-FaceRecognition using socketio')
            self.socketio.start_background_task(
                self.stream.process,
                self.find,
                func_kwargs={
                    'callback': callback,
                    'client_id': client_id
                },
                capture_alternate=True
            )
        else:
            log.debug('Stream RealTime-FaceRecognition using threading')
            if self.thread is None:
                from threading import Thread
            self.thread = Thread(
                target=self.stream.process,
                kwargs={
                    'func': self.find,
                    'func_kwargs': {
                        'callback': callback,
                        'client_id': client_id
                    },
                    'capture_alternate': True
                }
            )
            self.thread.start()

    def stop(self):
        self.stream.stop(destroy=True)
    
    def load_data(self):
        for item in [_.name for _ in FR_BASE_FOLDER.glob('*/')]:
            images_path =  FR_BASE_FOLDER / item / 'img'
            encodings_path =  FR_BASE_FOLDER / item / 'enc'
            encodings = [_.stem for _ in encodings_path.glob('*.enc')]
            for file in images_path.glob(IMG_PATTERN):
                fname = file.stem
                face_encoding = None
                if fname not in encodings:
                    with (encodings_path / f'{fname}.enc').open('wb') as fout:
                        log.debug(f'encoding: {fname}')
                        image = face_recognition.load_image_file(file)
                        face_encoding = face_recognition.face_encodings(image)[0]
                        pickle.dump(face_encoding, fout)
                else:
                    with (encodings_path / f'{fname}.enc').open('rb') as fin:
                        face_encoding = pickle.load(fin)
                self.known_face_encodings += [face_encoding]
                self.known_face_identifiers += [item]

    def processImage(self, image_uri: Path, out_path: Path, json=None, callback=None):
        log.debug('Start face recognition...')
        self.touch()
        
        # load into a numpy array
        image = face_recognition.load_image_file(image_uri)
        self.touch()
        
        # Find all the faces in the image using the default HOG-based model.
        # This method is fairly accurate, but not as accurate as the CNN model and not GPU accelerated.
        # See also: find_faces_in_picture_cnn.py
        #face_locations = face_recognition.face_locations(image)
        face_identifiers, face_locations = self.frame_analyze(image, uid=image_uri.stem, by_similarity=True, save=True)
        self.touch()
        
        # source_img = Image.open(image_uri)
        # draw = ImageDraw.Draw(source_img)
        # for face_location in face_locations:

        #     # Print the location of each face in this image
        #     top, right, bottom, left = face_location
        #     log.debug(f'A face is located at pixel location Top: {top}, Left: {left}, Bottom: {bottom}, Right: {right}')
        #     draw.rectangle([(left,bottom),(right,top)], fill=None, outline="red", width=10)
        #     #draw.text((20, 70), "something123", font=ImageFont.truetype("font_path123"))
        #     # You can access the actual face itself like this:
        #     #face_image = image[top:bottom, left:right]
        #     #pil_image = Image.fromarray(face_image)
        #     #pil_image.show()
        # source_img.save(out_path / image_uri.name, "JPEG")
        # self.touch()
        if callback is not None:
            callback(json, face_identifiers)

    def frame_preprocess(self, frame, resize=None):
        if resize:
            adjusted_frame = cv2.resize(frame, (0, 0), fx=resize, fy=resize)
        else:
            adjusted_frame = frame
        rgb_frame = adjusted_frame[:, :, ::-1]
        return rgb_frame

    def frame_analyze(self, frame, uid=None, by_similarity=True, save=False):
        face_locations = face_recognition.face_locations(frame)
        self.touch()
        if save:
            log.info(f'Found {len(face_locations)} face(s)')
        face_encodings = face_recognition.face_encodings(frame, face_locations)
        if save and face_locations:
            log.debug(f'Computed encodings')
        self.touch()
        face_identifiers = []
        for idx, face_encoding in enumerate(face_encodings):
            matches = face_recognition.compare_faces(self.known_face_encodings, face_encoding)
            name = "Unknown"
            index = -1
            if matches:
                if by_similarity:
                    face_distances = face_recognition.face_distance(self.known_face_encodings, face_encoding)
                    best_match_index = np.argmin(face_distances)
                    if matches[best_match_index]:
                        name = self.known_face_identifiers[best_match_index]
                        index = idx
                else:
                    if True in matches:
                        first_match_index = matches.index(True)
                        name = self.known_face_identifiers[first_match_index]
                        index = idx
            if save:
                log.debug(f'Face {idx}: {name}')
                if index == -1:
                    name = self.randomName(8)
                    variant = 1
                    log.debug(f'Saving new encoding as {name}')
                else:
                    variant = len(list((FR_BASE_FOLDER / name / 'enc').glob('*.enc'))) + 1
                    log.debug(f'Saving encoding {variant} for {name}')
                base_path = FR_BASE_FOLDER / name
                encoding_path = base_path / 'enc' / f'{variant}.enc'
                image_path = base_path / 'img' / f'{variant}.jpg'
                if not base_path.exists():
                    encoding_path.parent.mkdir(parents=True, exist_ok=True)
                    image_path.parent.mkdir(parents=True, exist_ok=True)
                with (encoding_path).open('wb') as fout:
                    pickle.dump(face_encoding, fout)
                top, right, bottom, left = face_locations[idx]
                cropped = frame[frame.shape[0]-bottom:frame.shape[0]-top, left:right]
                cropped_rgb = cropped[:, :, ::-1]
                cv2.imwrite(str(image_path), cropped_rgb)
                self.known_face_encodings += [face_encoding]
                self.known_face_identifiers += [name]
            face_identifiers.append(name)
            self.touch()
        if uid:
            self.update_db(uid, face_identifiers)
        return face_identifiers, face_locations

    def find(self, grabbed, frame, kwargs):
        frame = self.frame_preprocess(frame)
        face_identifiers, face_locations = self.frame_analyze(frame)
        res = self.post_process(face_locations, face_identifiers)
        log.debug(f'Find finished - new:{list(res)} reporting:{list(self.audience_reported)}')
        self.touch()
        if self.audience_reported != res:
            callback = kwargs['callback']
            client_id = kwargs['client_id']
            callback(list(res), client_id)
            self.audience_reported = res

    def post_process(self, face_locations, face_identifiers):
        # for (top, right, bottom, left), name in zip(face_locations, face_identifiers):
            # # Scale back up face locations since the frame we detected in was scaled to 1/4 size
            # top *= 4
            # right *= 4
            # bottom *= 4
            # left *= 4

            # # Draw a box around the face
            # cv2.rectangle(frame, (left, top), (right, bottom), (0, 0, 255), 2)

            # # Draw a label with a name below the face
            # cv2.rectangle(frame, (left, bottom - 35), (right, bottom), (0, 0, 255), cv2.FILLED)
            # font = cv2.FONT_HERSHEY_DUPLEX
            # cv2.putText(frame, name, (left + 6, bottom - 6), font, 1.0, (255, 255, 255), 1)

        # Display the resulting image
        # cv2.imshow('Video', frame)
        return self.whois(face_identifiers)

    def whois(self,face_identifiers, threshold=1, inactive_countdown=5):
        for item in face_identifiers:
            if item == 'Unknown':
                continue
            item_cnt = self.audience.get(item, 0)
            if item_cnt < threshold:
                self.audience[item] = item_cnt + 1
            elif item_cnt == threshold:
                self.audience[item] = threshold + inactive_countdown
        for item in [_ for _ in self.audience.keys() if _ not in face_identifiers]:
            if self.audience[item] == 1:
                 self.audience.pop(item)
            else:
                self.audience[item] -= 1
        return set([ item_ for (item_, cnt_) in self.audience.items() if cnt_ > threshold])
