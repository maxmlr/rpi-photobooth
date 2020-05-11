from os import environ
import logging


class Logger():

    def __init__(self, name, level=logging.INFO):
        self.level = level
        self.log = logging.getLogger(name)
        self.log.setLevel(level if level else environ.get("LOGLEVEL", logging.INFO))

    def addConsoleHandler(self, level=None, formatted=True):
        console_handler = logging.StreamHandler()
        console_handler.setLevel(level if level else self.level)
        if formatted:
            formatter = logging.Formatter(
                "%(asctime)s - %(filename)s:%(lineno)-4s - [ %(levelname)8s ] --- %(message)s"
            )
            console_handler.setFormatter(formatter)
        self.log.addHandler(console_handler)

    def addFileHandler(self, filename, level=None):
        file_handler = logging.FileHandler(filename)
        file_handler.setLevel(level if level else self.level)
        formatter = logging.Formatter(
                "%(asctime)s - %(filename)s:%(lineno)-4s - [ %(levelname)8s ] --- %(message)s"
            )
        file_handler.setFormatter(formatter)
        self.log.addHandler(file_handler)
    
    def getLogger(self):
        return self.log

    def getRootLogger(self):
        return logging.getLogger()
