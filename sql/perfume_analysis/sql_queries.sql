-- 1. Динамика продаж по ценовым категориям за каждый год
SELECT
    EXTRACT(YEAR from order_date) AS year,
    SUM(CASE WHEN p.price/volume_ml < 100 THEN ol.quantity ELSE 0 END) AS "до 100 руб./мл",
    SUM(CASE WHEN p.price/volume_ml >= 100 AND p.price/p.volume_ml < 150 THEN ol.quantity ELSE 0 END) AS "100 - 150 руб./мл",
    SUM(CASE WHEN p.price/volume_ml >= 150 AND p.price/p.volume_ml < 500 THEN ol.quantity ELSE 0 END) AS "150 - 500 руб./мл",
    SUM(CASE WHEN p.price/volume_ml >= 500 THEN ol.quantity ELSE 0 END) AS "от 500 руб./мл"
FROM orders o
JOIN order_lines ol ON o.order_id = ol.order_id
JOIN products p ON ol.product_id = p.product_id
GROUP BY year
ORDER BY year;

-- 2. Распределение товаров по ценовым категориям
SELECT
    CASE
        WHEN price / volume_ml < 50 THEN 'до 50 руб./мл'
        WHEN price / volume_ml BETWEEN 50 AND 100 THEN '50 - 100 руб./мл'
        WHEN price / volume_ml BETWEEN 100 AND 150 THEN '100 - 150 руб./мл'
        WHEN price / volume_ml BETWEEN 150 AND 200 THEN '150 - 200 руб./мл'
        WHEN price / volume_ml BETWEEN 200 AND 250 THEN '200 - 250 руб./мл'
        WHEN price / volume_ml BETWEEN 250 AND 300 THEN '250 - 300 руб./мл'
        WHEN price / volume_ml BETWEEN 300 AND 350 THEN '300 - 350 руб./мл'
        WHEN price / volume_ml BETWEEN 350 AND 400 THEN '350 - 400 руб./мл'
        WHEN price / volume_ml BETWEEN 400 AND 450 THEN '400 - 450 руб./мл'
        WHEN price / volume_ml BETWEEN 450 AND 500 THEN '450 - 500 руб./мл'
        ELSE 'от 500 руб./мл'
    END AS price_category,
    COUNT(*)
FROM products
GROUP BY price_category
ORDER BY COUNT(*);
