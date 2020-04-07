import os
import io
import shlex
import subprocess
import time
import qrcode
from functools import wraps


def frange(start, stop, step):
    if step > 1:
        step = (stop-start)/step
    i = start
    while i <= stop:
        yield round(i,2)
        i += step


def pre_execution(method):
    @wraps(method)
    def _impl(self, *method_args, **method_kwargs):
        self.is_running = True
        return method(self, *method_args, **method_kwargs)
    return _impl


def post_execution(method):
    @wraps(method)
    def _impl(self, *method_args, **method_kwargs):
        return_value = method(self, *method_args, **method_kwargs)
        self.is_running = False
        return return_value
    return _impl


def retry(exceptions, tries=4, delay=3, backoff=2, logger=None, verbose=False, catchAll=False):
    """Retry calling the decorated function using an exponential backoff.

    adapted from:  http://www.saltycrane.com/blog/2009/11/trying-out-retry-decorator-python/
    original from: http://wiki.python.org/moin/PythonDecoratorLibrary#Retry

    :param exceptions: the exception(s) to check. may be a tuple of
        exceptions to check.
    :type exceptions: Exception type, exception instance, or tuple containing
        any number of both (eg. IOError, IOError(errno.ECOMM), (IOError,), or
        (ValueError, IOError(errno.ECOMM))
    :param tries: number of times to try (not retry) before giving up
    :type tries: int
    :param delay: initial delay between retries in seconds
    :type delay: int
    :param backoff: backoff multiplier e.g. value of 2 will double the delay
        each retry
    :type backoff: int
    :param silent: If set then no logging will be attempted
    :type silent: bool
    :param logger: logger to use. If None, print
    :type logger: logging.Logger instance
    :param verbose: if set, print verbose manages
    :type verbose: bool
    :param catchAll: if set, also catch last retry
    :type catchAll: bool
    """
    try:
        len(exceptions)
    except TypeError:
        exceptions = (exceptions,)
    all_exception_types = tuple(set(x if type(x) == type else x.__class__ for x in exceptions))
    exception_types = tuple(x for x in exceptions if type(x) == type)
    exception_instances = tuple(x for x in exceptions if type(x) != type)

    def deco_retry(f):
        @wraps(f)
        def f_retry(*args, **kwargs):
            mtries, mdelay = tries, delay
            while mtries > (1 if not catchAll else 0):
                try:
                    return f(*args, **kwargs)
                except all_exception_types as e:
                    if (not any(x for x in exception_types if isinstance(e, x))
                        and not any(x for x in exception_instances if type(x) == type(e) and x.args == e.args)):
                        raise
                    msg = f'{str(e) if str(e) != "" else repr(e)}, Retrying in {mdelay} seconds...'
                    if verbose:
                        if logger:
                            logger.warning(msg)
                        else:
                            print(msg)
                    time.sleep(mdelay)
                    mtries -= 1
                    mdelay *= backoff
            if mtries == 1:
                return f(*args, **kwargs)
        return f_retry  # true decorator
    return deco_retry


def run_command(command, shell=False, print_output=False, env_exports={}, logger=None):
    print_ = logger.info if logger else print
    current_env = os.environ.copy()
    merged_env = {**current_env, **env_exports}
    process = subprocess.Popen(shlex.split(command), shell=shell, env=merged_env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout = []
    stdout_data, stderr_data = process.communicate()
    for line in stdout_data.splitlines():
        line = line.rstrip().decode('utf8')
        if print_output:
            print_(f'shell> {line}')
        stdout.append(line)
    if process.returncode != 0:
        stderr = []
        stderr_data = "" if not stderr_data else stderr_data
        for line in stderr_data.splitlines():
            line = line.rstrip().decode('utf8')
            stderr.append(line)
        print_(f'Error while executing command: {" ".join(stderr)}')
    return stdout


def getQRCodeImage(data, version=1, box_size=10, border=4, fit=True, fill_color='black', back_color='white', returnAs='image'):
    qr = qrcode.QRCode(
        version = version,
        error_correction = qrcode.constants.ERROR_CORRECT_L,
        box_size = box_size,
        border = border,
    )
    qr.add_data(data)
    qr.make(fit=fit)
    img = qr.make_image(fill_color=fill_color, back_color=back_color)
    if returnAs == 'bytes':
        file_object = io.BytesIO()
        img.save(file_object, 'PNG')
        file_object.seek(0)
        return file_object
    else:
        return img
