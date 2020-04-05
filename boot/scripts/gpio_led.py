#!/usr/bin/env python3

import sys
from signal import signal, SIGINT
import time
import datetime
import board
import neopixel


def frange(start, stop, step):
    if step > 1:
        step = (stop-start)/step
    i = start
    while i <= stop:
        yield round(i,2)
        i += step


class LEDPanel:

    colors = {
        'black' : (0,0,0),
        'white' : (255,255,255),
        'red' : (255,0,0),
        'green' : (0,255,0),
        'blue' : (0,0,255)
    }

    def __init__(self, pixel_pin=board.D18, num_pixels=64, order=neopixel.GRB, brightness=1.0, auto_write=False):
        self.pixel_pin = pixel_pin
        self.num_pixels = num_pixels
        self.order = order
        self.pixels = None
        self.brightness_adjusted = 1
        self.init(brightness=brightness, auto_write=auto_write)

    def init(self, brightness=1.0, auto_write=False):
        self.pixels = neopixel.NeoPixel(
            self.pixel_pin, self.num_pixels, brightness=brightness, auto_write=auto_write, pixel_order=self.order
        )
        LEDPanel.active = self
        signal(SIGINT, self.handler)

    def handler(self, signal_received, frame):
        self.clear()
        print('\nSIGINT or CTRL-C detected. Exiting gracefully')
        sys.exit(0)

    def get_color(self, color, brightness=None):
        color_ = self.colors.get(color, self.colors['black'])
        return self.adjust_color_brightness(color_, brightness)

    def adjust_color_brightness(self, color, brightness=None):
        brightness_ = brightness if brightness != None else self.brightness_adjusted
        return tuple([round(_ * brightness_) for _ in color])

    def clear(self):
        for i in range(self.num_pixels):
            self.pixels[i % self.num_pixels] = self.get_color('black')
        self.pixels.show()

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

    def setPanelColor(self, color=None):
        self.setPixelColor(pixels=None, color=color)

    def setBrightness(self, brightness):
        for idx, (r,g,b) in enumerate(self.pixels):
            self.pixels[idx] = (brightness if r else 0, brightness if g else 0, brightness if b else 0)

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

    def get_effects(self):
        return Effects(panel=self)


class Effects(LEDPanel):

    def __init__(self, panel):
        self.__dict__ = panel.__dict__

    def show(self):
        self.pixels.show()

    def switchColors(self, colors=['red', 'green', 'blue'], wait=0.5, iterations=1):
        for _ in range(iterations):
            for c in colors:
                self.pixels.fill(self.get_color(c))
                self.show()
                time.sleep(wait)

    def pulsate(self, color, start_brightness=0, stop_brightness=1, steps=150, wait=0.01, iterations=1):
        brightness_steps = list(frange(start_brightness, stop_brightness, steps))
        if iterations > 1 and brightness_steps[0] == 0:
            brightness_steps = brightness_steps[1:]
        brightness_steps_r = list(reversed(brightness_steps[:-1]))
        for i in range(iterations):
            for brightness_ in brightness_steps:
                self.pixels.fill(self.get_color(color, brightness_))
                self.show()
                time.sleep(wait)
            if i == 0:
                brightness_steps = [_ for _ in brightness_steps if _ > 0.1]
                brightness_steps_r = list(reversed(brightness_steps[:-1]))
            for brightness_ in brightness_steps_r:
                self.pixels.fill(self.get_color(color, brightness_))
                self.show()
                time.sleep(wait)

    def circleChase(self, color, wait=0.05, iterations=1):
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
                time.sleep(wait)

    def cycle(self, color, wait=0.025, iterations=1):
        for i in range(iterations * self.num_pixels):
            for j in range(self.num_pixels):
                self.pixels[j] = self.get_color('black')
            self.pixels[i % self.num_pixels] = self.get_color(color)
            self.pixels.write()
            time.sleep(wait)

    def bounce(self, wait=0.025, iterations=1):
        n = self.pixels.n
        for i in range(iterations * n):
            for j in range(n):
                self.pixels[j] = (0, 0, 128)
            if (i // n) % 2 == 0:
                self.pixels[i % n] = (0, 0, 0)
            else:
                self.pixels[n - 1 - (i % n)] = (0, 0, 0)
            self.pixels.write()
            time.sleep(wait)

    def fadeInOut(self, wait=0.025, iterations=3):
        n = self.pixels.n
        for i in range(0, iterations * 256, 8):
            for j in range(n):
                if (i // 256) % 2 == 0:
                    val = i & 0xff
                else:
                    val = 255 - (i & 0xff)
                self.pixels[j] = (val, 0, 0)
            self.pixels.write()
            time.sleep(wait)

    def colorWipe(self, color, wait=0.05, iterations=1):
        """Wipe color across display a pixel at a time."""
        last_color = None
        for _ in range(iterations):
            if  last_color == color:
                self.clear()
            for i in range(self.num_pixels):
                self.setPixelColor(i, color)
                self.show()
                time.sleep(wait)
            last_color = color

    def theaterChase(self, color, wait=0.05, iterations=1):
        """Movie theater light style chaser animation."""
        for _ in range(iterations):
            for q in range(3):
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q, color)
                self.show()
                time.sleep(wait)
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q)

    def rainbow(self, wait=0.02, iterations=1):
        """Draw rainbow that fades across all pixels at once."""
        for j in range(256 * iterations):
            for i in range(self.num_pixels):
                self.setPixelColor(i, self.wheel((i + j) & 255))
            self.show()
            time.sleep(wait)

    def rainbowCycle(self, wait=0.02, iterations=1):
        """Draw rainbow that uniformly distributes itself across all pixels."""
        for j in range(256 * iterations):
            for i in range(self.num_pixels):
                self.setPixelColor(i, self.wheel(
                    (int(i * 256 / self.num_pixels) + j) & 255)
                )
            self.show()
            time.sleep(wait)

    def theaterChaseRainbow(self, wait=0.05, iterations=1):
        """Rainbow movie theater light style chaser animation."""
        for j in range(256 * iterations):
            for q in range(3):
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q, self.wheel((i + j) % 255))
                self.show()
                time.sleep(wait)
                for i in range(0, self.num_pixels, 3):
                    self.setPixelColor(i + q, 0)

    def clock(self):
        for i in range(0, self.num_pixels, 1):
            self.setPixelColor(i, 'black')
        while True:
            now = datetime.datetime.now()

            # Low light during 19-8 o'clock
            if(8 < now.hour < 19):
                self.setBrightness(200)
            else:
                self.setBrightness(25)

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
            time.sleep(0.1)

    def demo(self, brightness=1, iterations=2):
        self.brightness_adjusted = brightness

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
    action = sys.argv[1] if len(sys.argv) > 1 else ''

    panel = LEDPanel()
    effects = panel.get_effects()

    if action == "demo":
        effects.demo()
    if action.startswith("color:"):
        effects.setPanelColor(action.split(':')[1])
        effects.show()
    else:
        print('no valid action specified')
