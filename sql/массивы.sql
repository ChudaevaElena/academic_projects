-- Задание 1: продажи в пятницу для Центрального
SELECT daily_sales[5] AS friday_sales
FROM restaurants
WHERE restaurant_name = 'Центральный';

-- Задание 2: посетители в субботу в 20:00 для Паркового
SELECT hourly_traffic[6][12] AS visitors_sat_20h
FROM restaurants
WHERE restaurant_name = 'Парковый';

-- Задание 3: продажи картофеля в среду для Вокзального
SELECT weekly_menu_stats[3][2] AS potato_wednesday
FROM restaurants
WHERE restaurant_name = 'Вокзальный';

-- Задание 4: рестораны с хотя бы одним днём продаж > 100
SELECT restaurant_name
FROM restaurants
WHERE 100 < ANY(daily_sales);

-- Задание 5: рестораны, где все будни (дни 1–7) продажи бургеров >= 50
SELECT restaurant_name
FROM restaurants
WHERE 50 <= ALL(weekly_menu_stats[1:7][1]);

-- Задание 6: рестораны, где в какой-то день бургеры превышают и картофель, и напитки
SELECT restaurant_name
FROM restaurants r
WHERE EXISTS (
    SELECT 1
    FROM generate_series(1,7) d
    WHERE r.weekly_menu_stats[d][1] > r.weekly_menu_stats[d][2]
      AND r.weekly_menu_stats[d][1] > r.weekly_menu_stats[d][3]
);

-- Задание 7: для Университетского – количество дней, когда макс. часовой трафик > 50
SELECT COUNT(*)
FROM restaurants r,
     generate_series(1,7) d
WHERE r.restaurant_name = 'Университетский'
  AND (
      SELECT MAX(r.hourly_traffic[d][h])
      FROM generate_series(1,14) h
  ) > 50;

-- Задание 8: глобальный день с максимальными продажами бургеров (один результат)
SELECT 
    restaurant_name, 
    day_index, 
    weekly_menu_stats[day_index][1] AS burger_sales
FROM restaurants, generate_series(1,7) AS day_index
ORDER BY burger_sales DESC
LIMIT 1;

-- Задание 9: для каждого ресторана – день с пиковыми продажами бургеров
WITH daily_data AS (
    SELECT 
        restaurant_name, 
        day_index, 
        weekly_menu_stats[day_index][1] AS burgers
    FROM restaurants, generate_series(1,7) AS day_index
)
SELECT DISTINCT ON (restaurant_name) 
    restaurant_name, day_index, burgers
FROM daily_data
ORDER BY restaurant_name, burgers DESC;

-- Задание 10: корреляция между выручкой и числом посетителей по дням
WITH stats AS (
    SELECT 
        restaurant_name,
        day_index,
        daily_sales[day_index] as rev,
        (SELECT SUM(hourly_traffic[day_index][h]) 
         FROM generate_series(1,14) h) as visitors
    FROM restaurants, generate_series(1,7) day_index
)
SELECT 
    restaurant_name, 
    corr(rev, visitors) as correlation
FROM stats
GROUP BY restaurant_name
ORDER BY correlation DESC;

-- Задание 11: для каждого ресторана – дни, когда бургеры > 50 (список названий дней)
WITH data AS (
    SELECT 
        r.restaurant_name,
        d,
        r.weekly_menu_stats[d][1] AS burgers,
        CASE d
            WHEN 1 THEN 'пн'
            WHEN 2 THEN 'вт'
            WHEN 3 THEN 'ср'
            WHEN 4 THEN 'чт'
            WHEN 5 THEN 'пт'
            WHEN 6 THEN 'сб'
            WHEN 7 THEN 'вс'
        END AS day_name
    FROM restaurants r,
         generate_series(1,7) d
)
SELECT 
    restaurant_name,
    COUNT(*) AS days_count,
    STRING_AGG(day_name, ', ') AS days
FROM data
WHERE burgers > 50
GROUP BY restaurant_name;
