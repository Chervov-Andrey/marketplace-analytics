"""Работа с базой данных PostgreSQL: запись данных за день и список уже загруженных дат."""

import psycopg2
from psycopg2.extras import execute_values

from config import DB_CONFIG

INSERT_SQL = """
    INSERT INTO sales (
        client_id, gender, product_id, quantity, price_per_item,
        discount_per_item, total_price, purchase_date, purchased_at
    )
    VALUES %s
    ON CONFLICT (client_id, purchased_at, product_id) DO NOTHING
    RETURNING 1
"""


def save_day(rows):
    """Записывает строки одного дня одной транзакцией и возвращает число вставленных строк."""
    connection = psycopg2.connect(**DB_CONFIG)
    try:
        cursor = connection.cursor()
        inserted = execute_values(cursor, INSERT_SQL, rows, page_size=1000, fetch=True)
        connection.commit()
        return len(inserted)
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def get_loaded_dates():
    """Возвращает множество дат, за которые в таблице sales уже есть строки."""
    connection = psycopg2.connect(**DB_CONFIG)
    cursor = connection.cursor()
    cursor.execute("SELECT DISTINCT purchase_date FROM sales")
    loaded_dates = {row[0] for row in cursor.fetchall()}
    connection.close()
    return loaded_dates