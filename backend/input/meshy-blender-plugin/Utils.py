import bpy
import os
import time
import requests
from functools import wraps


import logging


def setup_logging():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    addon_dir = os.path.dirname(os.path.abspath(__file__))
    file_handler = logging.FileHandler(os.path.join(addon_dir, "meshy.log"))
    file_handler.setLevel(logging.INFO)
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    return logger


logger = setup_logging()


def retry_wrapper(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        max_retries = 3
        retry_delay = 1
        for _ in range(max_retries):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                time.sleep(retry_delay)
                retry_delay *= 2
        raise Exception("Failed to execute function after max retries")

    return wrapper


@retry_wrapper
def request_from_meshy(url, headers, params={"source": "blender"}):
    try:
        response = requests.get(url, headers=headers, params=params)
        return response.json()
    except Exception as e:
        logger.error(f"Error: {e}")
        return None
