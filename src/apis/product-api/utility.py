import logging
from logging import Logger

def get_logger(module_name) -> Logger:
    return logging.getLogger(f"app.{module_name}")
