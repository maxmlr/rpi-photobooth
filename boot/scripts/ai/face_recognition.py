import eventlet
eventlet.sleep()
eventlet.monkey_patch()
from pathlib import Path
from PIL import Image, ImageDraw
import face_recognition
from timeit import default_timer as timer
from logger import Logger


"""
author: Maximilian Miller <mmiller@bromberglab.org>
"""

__version__ = 1.0

logger = Logger(__name__, level="DEBUG")
# logger.addConsoleHandler()
logger.addFileHandler(filename='/var/log/flask/api.log', level="DEBUG")
log = logger.getLogger()


class FaceRecognition():

    def __init__(self):
        log.debug('FaceRecognition init...')

    def touch(self, socketio):
        if socketio is not None:
            eventlet.sleep(0)

    def process(self, image_uri: Path, out_path: Path, socketio=None, json=None):
        log.debug('Start face recognition...')
        source_img = Image.open(image_uri)
        self.touch(socketio)
        
        # load into a numpy array
        image = face_recognition.load_image_file(image_uri)
        self.touch(socketio)
        
        # Find all the faces in the image using the default HOG-based model.
        # This method is fairly accurate, but not as accurate as the CNN model and not GPU accelerated.
        # See also: find_faces_in_picture_cnn.py
        face_locations = face_recognition.face_locations(image)
        self.touch(socketio)
        log.debug(f'Found {len(face_locations)} face(s) in {image_uri.name}')
        
        draw = ImageDraw.Draw(source_img)
        for face_location in face_locations:

            # Print the location of each face in this image
            top, right, bottom, left = face_location
            log.debug(f'A face is located at pixel location Top: {top}, Left: {left}, Bottom: {bottom}, Right: {right}')
            draw.rectangle([(left,bottom),(right,top)], fill=None, outline="red", width=10)
            #draw.text((20, 70), "something123", font=ImageFont.truetype("font_path123"))
            # You can access the actual face itself like this:
            #face_image = image[top:bottom, left:right]
            #pil_image = Image.fromarray(face_image)
            #pil_image.show()

        self.touch(socketio)
        source_img.save(out_path / image_uri.name, "JPEG")
        self.touch(socketio)
        if socketio is not None:
            socketio.emit('updatePic', {'img': json['args'], 'src': f'/data/ai/{json["args"]}' }, namespace='/gallery', broadcast=True)


if __name__ == "__main__":
    import sys
    fr = FaceRecognition()
    fr.process(Path(sys.argv[1]), Path(sys.argv[1]))
