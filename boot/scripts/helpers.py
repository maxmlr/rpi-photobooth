import time
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


def retry(ExceptionToCheck, tries=4, delay=3, backoff=2, logger=None, verbose=False, catchAll=False):
    """Retry calling the decorated function using an exponential backoff.

    http://www.saltycrane.com/blog/2009/11/trying-out-retry-decorator-python/
    original from: http://wiki.python.org/moin/PythonDecoratorLibrary#Retry

    :param ExceptionToCheck: the exception to check. may be a tuple of
        exceptions to check
    :type ExceptionToCheck: Exception or tuple
    :param tries: number of times to try (not retry) before giving up
    :type tries: int
    :param delay: initial delay between retries in seconds
    :type delay: int
    :param backoff: backoff multiplier e.g. value of 2 will double the delay
        each retry
    :type backoff: int
    :param logger: logger to use. If None, print
    :type logger: logging.Logger instance
    """
    def deco_retry(f):

        @wraps(f)
        def f_retry(*args, **kwargs):
            mtries, mdelay = tries, delay
            while mtries > (1 if not catchAll else 0):
                try:
                    return f(*args, **kwargs)
                except ExceptionToCheck as err:
                    msg = f'{err}, Retrying in {mdelay} seconds...'
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
