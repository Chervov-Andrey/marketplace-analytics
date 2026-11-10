"""Историческая загрузка: записывает в базу все дни с 2022-01-01 по вчера.

Уже загруженные дни пропускаются, поэтому скрипт можно запускать повторно:
он продолжит с места остановки и подберёт дни, которые не удались.
"""

import logging
import sys
from datetime import date, timedelta

from db import get_loaded_dates
from logger_config import setup_logging
from pipeline import load_day

START_DATE = date(2022, 1, 1)

setup_logging()
logger = logging.getLogger(__name__)

end_date = date.today() - timedelta(days=1)
loaded_dates = get_loaded_dates()
logger.info(
    "Историческая загрузка данных: с %s по %s, уже загружено дней: %s",
    START_DATE, end_date, len(loaded_dates)
)

loaded_count = 0       # сколько дней загрузили сейчас
skipped_count = 0      # сколько дней пропустили (уже были)
failed_count = 0       # сколько дней не удалось загрузить
total_inserted = 0     # сколько строк всего записали в базу

# Перебираем дни по порядку: уже загруженные пропускаем, остальные загружаем.
# Сбой одного дня не останавливает загрузку остальных.
current_date = START_DATE
while current_date <= end_date:
    if current_date in loaded_dates:
        skipped_count += 1
    else:
        try:
            total_inserted += load_day(current_date.isoformat())
            loaded_count += 1
        except Exception:
            logger.exception("Не удалось загрузить день %s", current_date)
            failed_count += 1
    current_date += timedelta(days=1)

logger.info(
    "Загрузка завершена: загружено дней %s, пропущено дней (были загружены ранее) %s, не удалось загрузить %s, всего вставлено строк %s",
    loaded_count, skipped_count, failed_count, total_inserted
)

if failed_count:
    logger.error("Не загружено дней: %s. Запустите скрипт повторно", failed_count)
    sys.exit(1)