#!/usr/bin/env python3


import os
from pathlib import Path
from PIL import Image
from FBpyGIF import fb
from argparse import ArgumentParser
from helpers import source

# with imagemagick
# convert -resize 1024x600 -background black -gravity center -extent 1024x600 /opt/photobooth/img/boot.png [bgr|bgra]:/dev/fb0
# with FBpyGIF
# python3 -m FBpyGIF /opt/photobooth/img/boot.png

def resize(image, width, height):
    img = Image.open(image)
    newsize = (width, height)
    return img.resize(newsize)


def crop(image, left, top, right, bottom):
    img = Image.open(image)
    width, height = img.size
    left = left
    top = top
    right = width - right
    bottom = height - bottom
    return im.crop((left, top, right, bottom)) 


def getFrameBuffer(image):
    BIT_DEPTH = 24
    FRAME_BUFFER = 0
    fb.ready_fb(BIT_DEPTH, FRAME_BUFFER)
    fb.show_img(fb.ready_img(image))


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-img", action="store", required=True, dest="image", help="name of splash image")
    args = parser.parse_args()

    photobooth_config = source('/boot/photobooth.conf')

    img_path = Path(args.image)
    img_preprocessed_path = img_path.parents[0] / f'.{img_path.stem}.png'
    if  not img_preprocessed_path.exists():
        img = resize(img_path, int(photobooth_config['DISPLAY_RESOLUTION_X']), int(photobooth_config['DISPLAY_RESOLUTION_Y']))
    else:
        img = Image.open(img_preprocessed_path)
    img.save(img_preprocessed_path, "PNG")

    getFrameBuffer(img_preprocessed_path)
