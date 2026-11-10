"""Получение данных о покупках из API за один день (с повторными попытками)."""

import logging
import time

import requests

from config import API_TIMEOUT, API_URL

logger = logging.getLogger(__name__)

MAX_ATTEMPTS = 3
RETRY_DELAY = 5


class ApiError(Exception):
    """Выделяем свою ошибку при получении данных из API."""


def _fetch_once(date):
    """Делает один запрос и возвращает список покупок за дату ('YYYY-MM-DD')."""
    try:
        response = requests.get(API_URL, params={"date": date}, timeout=API_TIMEOUT)
    except requests.exceptions.RequestException as error:
        raise ApiError(f"Не удалось выполнить запрос за {date}: {error}") from error

    if response.status_code != 200:
        raise ApiError(f"API вернул статус {response.status_code} за {date}")

    try:
        data = response.json()
    except ValueError as error:
        raise ApiError(f"Ответ за {date} не JSON: {response.text[:100]}") from error

    if not isinstance(data, list):
        raise ApiError(f"Ответ за {date} не список, а {type(data).__name__}")

    return data


def fetch_day(date):
    """Использует функцию _fetch_once(date), при сбое повторяет запрос установленное кол-во раз, пишет об этом в лог."""
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            return _fetch_once(date)
        except ApiError as error:
            if attempt == MAX_ATTEMPTS:
                raise
            logger.warning(
                "Попытка %s из %s за %s не удалась: %s. Повтор через %sс",
                attempt, MAX_ATTEMPTS, date, error, RETRY_DELAY
            )
            time.sleep(RETRY_DELAY)