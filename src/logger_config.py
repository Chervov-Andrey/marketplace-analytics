"""Настройка логирования: запись в файл (по одному на день) и в консоль."""

import logging
import os 
from datetime import datetime

from config import BASE_DIR

LOG_DIR = os.path.join(BASE_DIR, "logs")


def setup_logging():
    """Настраивает запись логов в файл (отдельно на каждый день) и в консоль."""
    os.makedirs(LOG_DIR, exist_ok=True)
    log_file = os.path.join(LOG_DIR, f"{datetime.now() :%Y-%m-%d}.log")

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
        handlers=[
            logging.FileHandler(log_file, encoding="utf-8"),
            logging.StreamHandler(),
        ]
    )