# Marketplace ETL Pipeline

Сбор и хранение данных о продажах онлайн-маркетплейса. Данные забираются по API, складываются в PostgreSQL, ежедневно обновляются по расписанию.

**Стек:** Python, requests, psycopg2, PostgreSQL, Metabase (Docker), cron.

## Как это работает

- `history_load.py` загружает историю продаж с 1 января 2022 года по вчерашний день. Уже загруженные дни пропускаются, поэтому скрипт можно безопасно запускать повторно.
- `daily_load.py` забирает данные за вчера и запускается по расписанию.
- Запросы к API выполняются с повторными попытками при сбоях, каждый день записывается в базу одной транзакцией, ход работы пишется в журнал `logs/`.

## Данные

Таблица `sales` содержит по одной строке на позицию покупки: клиент и его пол, товар, количество, цена за единицу, скидка, итоговая сумма, дата и время покупки. Первичный ключ `(client_id, purchased_at, product_id)`: повторные записи отбрасываются.

## Аналитика

- **Дашборд Metabase «Продажи маркетплейса»**: выручка, покупки и клиенты, динамика по месяцам, распределение клиентов по числу покупок, ABC-анализ, сегменты клиентов, LTV.

![Дашборд](img/Metabase-Дашборд-Продажи%20маркетплейса.png)

- **Исследования за 2023 год** (`research/`): ассортимент и политика скидок; клиентская база и LTV.

![Исследование: Ассортимент и политика скидок](research/Исследование_1%20Ассортимент%20и%20политика%20скидок.pdf)

![Исследование: клиентская база и LTV](research/Исследование_2%20Клиентская%20база%20и%20LTV.pdf)


## Структура

- `src/` — скрипты загрузки
- `sql/` — описание таблицы
- `research/` — SQL и материалы исследований
- `img/` — скриншоты
- `config.example.ini` — шаблон настроек

## Установка и запуск

Требуется Python 3 и PostgreSQL. В `config.ini` указываются адрес API и параметры подключения к базе.

**Linux**

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp config.example.ini config.ini
psql -U <пользователь> -d marketplace -f sql/create_sales_table.sql
python src/history_load.py
```

**Windows (PowerShell)**

```powershell
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy config.example.ini config.ini
psql -U <пользователь> -d marketplace -f sql\create_sales_table.sql
python src\history_load.py
```

## Ежедневная загрузка

**Linux** (cron, каждый день в 7:00; пути указываются полностью, часовой пояс сервера задаётся системой):

```
0 7 * * * /путь/к/проекту/venv/bin/python /путь/к/проекту/src/daily_load.py >> /путь/к/проекту/logs/cron.log 2>&1
```

**Windows**: Планировщик заданий, программа `venv\Scripts\python.exe`, аргумент `src\daily_load.py`, запуск ежедневно в 7:00.