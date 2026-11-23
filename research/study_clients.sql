-- Исследование 2. Клиентская база и LTV. Данные за 2023 год.
-- Во всех запросах исключены строки с нулевым количеством (quantity = 0).


-- 1. Клиенты по числу покупок и давности
WITH c AS (
    SELECT client_id,
           COUNT(*) AS freq,
           SUM(total_price) AS revenue,
           DATE '2023-12-31' - MAX(purchase_date) AS recency_days
    FROM sales
    WHERE quantity > 0
      AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
    GROUP BY client_id
)
SELECT CASE WHEN freq = 1 THEN '1 покупка'
            WHEN freq <= 3 THEN '2-3 покупки'
            ELSE '4+ покупок' END AS frequency_group,
       CASE WHEN recency_days <= 90 THEN 'до 90 дней'
            ELSE 'более 90 дней' END AS last_purchase,
       COUNT(*) AS clients,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)
         AS revenue_share_pct
FROM c
GROUP BY 1, 2
ORDER BY 1, 2


-- 2. Время между покупками
WITH t AS (
    SELECT client_id,
           purchase_date - LAG(purchase_date) OVER (PARTITION BY client_id ORDER BY purchased_at) AS gap_days
    FROM sales
    WHERE quantity > 0
      AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
)
SELECT COUNT(gap_days) AS gaps,
       ROUND(AVG(gap_days)) AS avg_days,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY gap_days) AS median
FROM t
WHERE gap_days IS NOT NULL


-- 3. Доля повторных покупок
WITH t AS (
    SELECT client_id,
           purchase_date - LAG(purchase_date)
             OVER (PARTITION BY client_id ORDER BY purchase_date) AS gap_days
    FROM sales
    WHERE quantity > 0
      AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
)
SELECT
    CASE
        WHEN gap_days <= 30  THEN '0-30'
        WHEN gap_days <= 60  THEN '31–60'
        WHEN gap_days <= 90  THEN '61–90'
        WHEN gap_days <= 180 THEN '91–180'
        ELSE 'более 180'
    END AS gap_bucket,
    COUNT(*) AS gaps,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM t
WHERE gap_days IS NOT NULL
GROUP BY 1
ORDER BY 1


-- 4. Сезонные спады
WITH monthly AS (
    SELECT date_trunc('month', purchase_date)::date AS month,
           COUNT(*) AS purchases
    FROM sales
    WHERE quantity > 0
      AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
    GROUP BY 1
),
yearly_avg AS (
    SELECT COUNT(*)::numeric / 365 AS avg_per_day
    FROM sales
    WHERE quantity > 0
      AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
),
calendar AS (
    SELECT generate_series('2023-01-01'::date, '2023-12-01'::date, '1 month') AS month
)
SELECT
    CASE EXTRACT(MONTH FROM c.month)
        WHEN 1  THEN 'Январь'  WHEN 2  THEN 'Февраль' WHEN 3  THEN 'Март'
        WHEN 4  THEN 'Апрель'  WHEN 5  THEN 'Май'     WHEN 6  THEN 'Июнь'
        WHEN 7  THEN 'Июль'    WHEN 8  THEN 'Август'  WHEN 9  THEN 'Сентябрь'
        WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь'  WHEN 12 THEN 'Декабрь'
    END AS month_name,
    COALESCE(m.purchases, 0) AS purchases,
    ROUND(
        100.0 * (COALESCE(m.purchases, 0)::numeric
                 / EXTRACT(DAY FROM c.month + INTERVAL '1 month' - INTERVAL '1 day')
                 / NULLIF(y.avg_per_day, 0)
                 - 1),
        1
    ) AS deviation_pct
FROM calendar c
CROSS JOIN yearly_avg y
LEFT JOIN monthly m ON m.month = c.month
ORDER BY c.month