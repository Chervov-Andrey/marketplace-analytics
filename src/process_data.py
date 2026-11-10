"""Преобразование записей из API в строки для таблицы sales."""

from datetime import datetime, timedelta


def convert_record(record):
    """Преобразует одну запись из API в кортеж нужных значений в порядке столбцов таблицы sales."""
    day = datetime.strptime(record["purchase_datetime"], "%Y-%m-%d")
    purchased_at = day + timedelta(seconds=record["purchase_time_as_seconds_from_midnight"])

    return (
        record["client_id"],
        record["gender"],
        record["product_id"],
        record["quantity"],
        record["price_per_item"],
        record["discount_per_item"],
        record["total_price"],
        day.date(),
        purchased_at
    )


def convert_day(day_data):
    """Превращает все записи за один день в список строк для записи в базу."""
    return [convert_record(record) for record in day_data]