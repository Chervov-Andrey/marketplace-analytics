"""Ежедневная загрузка: записывает в базу данные за вчерашний день."""

import logging
import sys
from datetime import date, timedelta

from logger_config import setup_logging
from pipeline import load_day

setup_logging()
logger = logging.getLogger(__name__)

yesterday = (date.today() - timedelta(days=1)).isoformat()
logger.info("Ежедневная загрузка: запрос данных за %s", yesterday)

try:
    load_day(yesterday)
except Exception:
    logger.exception("Не удалось загрузить данные за %s", yesterday)
    sys.exit(1)