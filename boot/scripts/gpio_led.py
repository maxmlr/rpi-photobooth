#!/usr/bin/env python3

import sys
import argparse
import inspect
from signal import signal, SIGINT
import time
import datetime
import board
import neopixel
from colors import Color
from helpers import frange, pre_execution, post_execution, retry


class LEDPanel:

    def __init__(self, pixel_pin=board.D18, num_pixels=64, order=neopixel.GRB, brightness=1.0, auto_write=False):
        self.pixel_pin = pixel_pin
        self.num_pixels = num_pixels
        self.order = order
        self.pixels = None
        self.brightness_adjusted = 1
        self.is_running = False
        self.is_abort = False
        self.init(brightness=brightness, auto_write=auto_write)

    def init(self, brightness=1.0, auto_write=False):
        self.pixels = neopixel.NeoPixel(
            self.pixel_pin, self.num_pixels, brightness=brightness, auto_write=auto_write, pixel_order=self.order
        )
        LEDPanel.active = self

    def catchSignale(self):
        signal(SIGINT, self.handler)

    def abort(self):
        if self.is_running:
            self.is_abort = True
            while self.is_running:
                pass

    def pause(self, wait):
        if self.is_abort:
            self.is_abort = False
            self.is_running = False
            sys.exit()
        else:
            time.sleep(wait)

    def handler(self, signal_received, frame):
        self.clear()
        print('\nSIGINT or CTRL-C detected. Exiting gracefully')
        sys.exit(0)

    def get_color(self, color, brightness=None):
        if color.startswith('rgb'):
            r_str, g_str, b_str = color[4:-1].split(',')
            r, g, b = int(r_str), int(g_str), int(b_str)
            color_ = (r, g, b)
        else:
            color_ = Color.colors.get(color, Color.colors.get(f'{color.lower()}1', Color.RGB(255, 255, 255))).rgb_format()
        return self.adjust_color_brightness(color_, brightness)

    def adjust_color_brightness(self, color, brightness=None):
        brightness_ = brightness if brightness != None else self.brightness_adjusted
        return tuple([round(_ * brightness_) for _ in color])

    def adjustBrightness(self, brightness):
        self.brightness_adjusted = brightness

    def setPixelColor(self, pixels=[], color=None):
        if not color or isinstance(color, str):
            color_ = self.get_color(color)
        else:
            color_ = color
        if pixels != None or (isinstance(pixels, list) and not pixels):
            if isinstance(pixels, int):
                pixels = [pixels]
            for i in pixels:
                self.pixels[i % self.num_pixels] = color_
        else:
            self.pixels.fill(color_)

    def wheel(self, pos, brightness=None):
        """Generate rainbow colors across 0-255 positions."""
        if pos < 85:
            r, g, b = pos * 3, 255 - pos * 3, 0
        elif pos < 170:
            pos -= 85
            r, g, b = 255 - pos * 3, 0, pos * 3
        else:
            pos -= 170
            r, g, b = 0, pos * 3, 255 - pos * 3
        return self.adjust_color_brightness((r, g, b) if self.order in (neopixel.RGB, neopixel.GRB) else (r, g, b, 0), brightness)

    def boot(self, **kwargs):
        import json
        import logging
        import pystemd.journal
        from pathlib import Path
        from pystemd.systemd1 import Unit
        
        CONFIG = '/opt/photobooth/conf/custom/trigger.json'
        unit = Unit(b'graphical.target')
        unit.load()
        config = Path(CONFIG)
        color = 'black'
        brightness = 0

        status = (unit.Unit.ActiveState).decode()
        while status != 'active':
            pystemd.journal.sendv(
                f'PRIORITY={logging.INFO}',
                MESSAGE=f'Graphical target: {status}',
                SYSLOG_IDENTIFIER='ledpanel'
            )
            self.pulsate('blue', start_brightness=0.1)
            status = (unit.Unit.ActiveState).decode()
        pystemd.journal.sendv(
            f'PRIORITY={logging.INFO}',
            MESSAGE=f'Graphical target: {status}',
            SYSLOG_IDENTIFIER='ledpanel'
        )

        self.clear()
        default_set = False
        if config.exists():
            with config.open() as fin:
                for action in json.load(fin)['actions']:
                    if action['trigger'] == 'default' and not default_set:
                        for sub in action['ledpanel']:
                            if sub['name'] == 'default' and not default_set:
                                for slot in sub['slots']:
                                    self.setPanelColor(slot['color'])
                                    self.setBrightness(float(slot['brightness']))
                                    default_set = True
        if not default_set:
            self.setPanelColor(color)
            self.setBrightness(brightness)

    def get_effects(self):
        return Effects(panel=self)

    def get_actions():
        return [name for name, func in inspect.getmembers(Effects, predicate=inspect.isfunction) if str(inspect.signature(func)).find('**kwargs') != -1]

    def get_colors():
        return list(Color.colors.keys())

    @pre_execution
    @post_execution
    def run(self, func_name, resume, brightness, kwargs):
        func = getattr(self, func_name, None)
        if func:
            if not resume:
                self.clear()
            self.adjustBrightness(brightness)
            func(**kwargs)
            self.show()
        else:
            print(f'ERROR: {func_name}() not available.')

    def clear(self, **kwargs):
        for i in range(self.num_pixels):
            self.pixels[i % self.num_pixels] = self.get_color('black')
        self.pixels.show()

    def setPanelColor(self, color=None, **kwargs):
        self.setPixelColor(pixels=None, color=color)

    def setBrightness(self, brightness, **kwargs):
        for idx, (r,g,b) in enumerate(self.pixels):
            self.pixels[idx] = (brightness * 255 if r else 0, brightness * 255 if g else 0, brightness * 255 if b else 0)


class Effects(LEDPanel):

    def __init__(self, panel):
        self.__dict__ = panel.__dict__

    def show(self):
        self.pixels.show()

    def switchColors(self, colors=['red', 'green', 'blue'], wait=0.5, iterations=1, **kwargs):
        for _ in range(iterations):
            for c in colors:
                self.pixels.fill(self.get_color(c))
                self.show()
                self.pause(wait)

    def pulsate(self, color, start_brightness=0, stop_brightness=1, steps=150, wait=0.01, iterations=1, **kwargs):
        brightness_steps = list(frange(start_brightness, stop_brightness, steps))
        if iterations > 1 and brightness_steps[0] == 0:
            brightness_steps = brightness_steps[1:]
        brightness_steps_r = list(reversed(brightness_steps[:-1]))
        for i in range(iterations):
            for brightness_ in brightness_steps:
                self.pixels.fill(self.get_color(color, brightness_))
                self.show()
                self.pause(wait)
            if i == 0:
                brightness_steps = [_ for _ in brightness_steps if _ > 0.1]
                brightness_steps_r = list(reversed(brightness_steps[:-1]))
            for brightness_ in brightness_steps_r:
                self.pixels.fill(self.get_color(color, brightness_))
                self.show()
                self.pause(wait)

    def circleChase(self, color, wait=0.05, iterations=1, **kwargs):
        ring = [0,15,16,31,32,47,48,63] + [62,61,60,59,58,57] + [56,55,40,39,24,23,8] + [7,6,5,4,3,2,1]
        for _ in range(iterations):
            for i in range(len(ring)):
                idx = ring[i]
                last_idx = i - 1
                if last_idx == -1:
                    last_idx = len(ring) - 1
                last = ring[last_idx]
                self.pixels[idx] = self.get_color(color)
                self.pixels[last] = self.get_color('black')
                self.pixels.show()
                self.pause(wait)

    def cycle(self, color, wait=0.025, iterations=1, **kwargs):
        for i in range(iterations * self.num_pixels):
            for j in range(self.num_pixels):
                self.pixels[j] = self.get_color('black')
            self.pixels[i % self.num_pixels] = self.get_color(color)
            self.pixels.write()
            self.pause(wait)

    def bounce(self, wait=0.025, iterations=1, **kwargs):
        n = self.pixels.n
        for i in range(iterations * n):
            for j in range(n):
                self.pixels[j] = (0, 0, 128)
            if (i // n) % 2 == 0:
                self.pixels[i % n] = (0, 0, 0)
            else:
                self.pixels[n - 1 - (i % n)] = (0, 0, 0)
            self.pixels.write()
            self.pause(wait)

    def fadeInOut(self, wait=0.025, iterations=3, **kwargs):
        n = self.pixels.n
        for i in range(0, iterations * 256, 8):
            for j in range(n):
                if (i // 256) % 2 == 0:
                    val = i & 0xff
                else:
                    val = 255 - (i & 0xff)
                self.pixels[j] = (val, 0, 0)
            self.pixels.write()
            self.pause(wait)

    def colorWipe(self, color, wait=0.05, iterations=1, **kwargs):
        """Wipe color across display a pixel at a time."""
        last_color = None
        for _ in range(iterations):
            if  last_color == color:
                self.clear()
            for i in range(self.num_pixels):
                self.setPixelColor(i, color)
                self.show()
                self.pause(wait)
            last_color = color

    def theaterChase(self, color, wait=0.05, iterations=1, **kwargs):
        """Movie theater light style chaser animation."""
        for _ in range(iterations):
            for q in range(3):
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q, color)
                self.show()
                self.pause(wait)
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q)

    def rainbow(self, wait=0.02, iterations=1, **kwargs):
        """Draw rainbow that fades across all pixels at once."""
        for j in range(256 * iterations):
            for i in range(self.num_pixels):
                self.setPixelColor(i, self.wheel((i + j) & 255))
            self.show()
            self.pause(wait)

    def rainbowCycle(self, wait=0.02, iterations=1, **kwargs):
        """Draw rainbow that uniformly distributes itself across all pixels."""
        for j in range(256 * iterations):
            for i in range(self.num_pixels):
                self.setPixelColor(i, self.wheel(
                    (int(i * 256 / self.num_pixels) + j) & 255)
                )
            self.show()
            self.pause(wait)

    def theaterChaseRainbow(self, wait=0.05, iterations=1, **kwargs):
        """Rainbow movie theater light style chaser animation."""
        for j in range(256 * iterations):
            for q in range(3):
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q, self.wheel((i + j) % 255))
                self.show()
                self.pause(wait)
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q, 0)

    def clock(self, **kwargs):
        for i in range(0, self.num_pixels, 1):
            self.setPixelColor(i, 'black')
        while True:
            now = datetime.datetime.now()

            # Low light during 19-8 o'clock
            if(8 < now.hour < 19):
                self.setBrightness(0.75)
            else:
                self.setBrightness(0.1)

            hour = now.hour % 12
            minute = now.minute / 5
            second = now.second / 5
            secondmodulo = now.second % 5
            timeslot_in_microseconds = secondmodulo * 1000000 + now.microsecond

            for i in range(0, self.num_pixels, 1):
                secondplusone = second + 1 if(second < 11) else 0
                secondminusone = second - 1 if(second > 0) else 11
                colorarray = [0, 0, 0]

                if i == second:
                    if timeslot_in_microseconds < 2500000:
                        colorarray[0] = int(
                            0.0000508 * timeslot_in_microseconds) + 126
                    else:
                        colorarray[0] = 382 - \
                            int(0.0000508 * timeslot_in_microseconds)

                if i == secondplusone:
                    colorarray[0] = int(0.0000256 * timeslot_in_microseconds)
                if i == secondminusone:
                    colorarray[0] = int(
                        0.0000256 * timeslot_in_microseconds) * -1 + 128
                if i == minute:
                    colorarray[2] = 200
                if i == hour:
                    colorarray[1] = 200

                self.setPixelColor(
                    i, (colorarray[0], colorarray[1], colorarray[2])
                )

            self.show()
            self.pause(0.1)

    def demo(self, brightness=1, iterations=2, **kwargs):
        self.adjustBrightness(brightness)

        self.clear()
        self.switchColors(iterations=iterations)
        self.clear()
        self.pulsate('blue', iterations=iterations)
        self.clear()
        self.circleChase('green', iterations=iterations)
        self.clear()
        self.cycle('red', iterations=iterations)
        self.clear()
        self.bounce(iterations=iterations)
        self.clear()
        self.fadeInOut(iterations=iterations)
        self.clear()
        self.colorWipe('red', iterations=iterations)
        self.clear()
        self.theaterChase('blue', iterations=iterations * 10)
        self.clear()
        self.rainbow(iterations=iterations)
        self.clear()
        self.rainbowCycle(iterations=iterations)
        self.clear()
        self.theaterChaseRainbow(iterations=iterations)
        self.clear()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='LED Panel COntroller.')
    parser.add_argument("action")
    parser.add_argument("-c", "--color", type=str, default='white')
    parser.add_argument("-b", "--brightness", type=float, default=1)
    parser.add_argument("-i", "--iterations", type=int, default=1)
    parser.add_argument("-r", "--resume", action='store_true')
    args, argv  = parser.parse_known_args()

    args_dict = vars(args)
    action = args_dict.pop('action')
    resume = args_dict.pop('resume')
    brightness = args_dict.pop('brightness')

    effects = LEDPanel().get_effects()
    effects.catchSignale()
    effects.run(action, resume, brightness, args_dict)
