"""Чтение настроек проекта из файла config.ini."""

import configparser
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # создаем базовый путь в корень проекта
CONFIG_PATH = os.path.join(BASE_DIR, "config.ini")

_parser = configparser.ConfigParser()
if not _parser.read(CONFIG_PATH, encoding="utf-8"):
    raise FileNotFoundError(f"Не найден файл настроек: {CONFIG_PATH}")  # добавил проверку наличия файла

API_URL = _parser.get("api", "url")
API_TIMEOUT = _parser.getint("api", "timeout")

DB_CONFIG = {
    "host": _parser.get("database", "host"),
    "port": _parser.getint("database", "port"),
    "dbname": _parser.get("database", "dbname"),
    "user": _parser.get("database", "user"),
    "password": _parser.get("database", "password")
}