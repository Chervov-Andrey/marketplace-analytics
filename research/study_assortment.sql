-- Исследование 1. Ассортимент и скидки. Данные за 2023 год.
-- Во всех запросах исключены строки с нулевым количеством (quantity = 0).


-- 1. Ключевые показатели
SELECT
    COUNT(*) AS purchases,
    SUM(quantity) AS units,
    COUNT(DISTINCT client_id) AS clients,
    SUM(total_price) AS revenue,
    SUM(quantity * price_per_item) AS revenue_before_discount,
    SUM(quantity * discount_per_item) AS discounts,
    ROUND(100.0 * SUM(quantity * discount_per_item)
        / SUM(quantity * price_per_item), 1) AS discount_pct
FROM sales
WHERE quantity > 0
  AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'


-- 2. Скидка и спрос
SELECT
    (LEAST(FLOOR(10.0 * discount_per_item / price_per_item), 9) * 10)::int AS discount_from_pct,
    COUNT(*) AS purchases,
    ROUND(AVG(quantity), 1) AS avg_quantity,
    ROUND(SUM(total_price)::numeric / COUNT(*)) AS avg_revenue_per_purchase
FROM sales
WHERE quantity > 0
  AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
GROUP BY 1
ORDER BY 1


-- 3. Цена и спрос
WITH p AS (
    SELECT product_id,
           MAX(price_per_item) AS price,
           COUNT(*) AS purchases,
           SUM(total_price) AS revenue
    FROM sales
    WHERE quantity > 0
      AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
    GROUP BY product_id
)
SELECT (FLOOR(price / 10000) * 10000)::int AS price_from,
       COUNT(*) AS products,
       ROUND(AVG(purchases), 1) AS avg_purchases_per_product,
       ROUND(AVG(revenue)) AS avg_revenue_per_product
FROM p
GROUP BY 1
ORDER BY 1


-- 4. ABC-анализ с ценой
WITH p AS (
    SELECT product_id, MAX(price_per_item) AS price, SUM(total_price) AS revenue
    FROM sales
    WHERE quantity > 0
      AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'
    GROUP BY product_id
),
r AS (
    SELECT product_id, price, revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC, product_id)
             / SUM(revenue) OVER () AS cum_share
    FROM p
)
SELECT CASE WHEN cum_share <= 0.80 THEN 'A'
            WHEN cum_share <= 0.95 THEN 'B'
            ELSE 'C' END AS abc,
       COUNT(*) AS products,
       ROUND(AVG(price)) AS avg_price,
       MIN(price) AS min_price,
       MAX(price) AS max_price,
       ROUND(SUM(revenue)) AS revenue,
	   ROUND(SUM(revenue) / COUNT(*)) AS revenue_per_product
FROM r
GROUP BY 1
ORDER BY 1


-- 5. Выручка при предельной скидке
SELECT
	ROUND(SUM(total_price)) AS revenue_now,
    ROUND(SUM(quantity * (price_per_item - LEAST(discount_per_item, price_per_item * 0.2)))) AS revenue_cap_20,
    ROUND(SUM(quantity * (price_per_item - LEAST(discount_per_item, price_per_item * 0.3)))) AS revenue_cap_30,
    ROUND(SUM(quantity * (price_per_item - LEAST(discount_per_item, price_per_item * 0.4)))) AS revenue_cap_40,
    ROUND(SUM(quantity * (price_per_item - LEAST(discount_per_item, price_per_item * 0.5)))) AS revenue_cap_50
FROM sales
WHERE quantity > 0
  AND purchase_date >= '2023-01-01' AND purchase_date < '2024-01-01'