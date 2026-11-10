"""Загрузка одного дня: получение данных из API, подготовка и запись в базу."""

import logging

from api_client import fetch_day
from db import save_day
from process_data import convert_day

logger = logging.getLogger(__name__)


def load_day(date):
    """Получает данные за дату, готовит строки и записывает их в базу."""
    day_data =  fetch_day(date)
    rows = convert_day(day_data)
    inserted = save_day(rows)
    logger.info("%s: получено %s, вставлено %s", date, len(day_data), inserted)
    return inserted