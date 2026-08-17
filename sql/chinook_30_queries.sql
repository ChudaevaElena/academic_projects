-- Задание 1: Количество треков длиннее 5 минут (300 000 мс)
SELECT COUNT(*) 
FROM track
WHERE milliseconds > 300000;

-- Задание 2: Количество треков дороже 1 доллара
SELECT COUNT(*) 
FROM track
WHERE unit_price > 1;

-- Задание 3: Количество треков, название которых начинается на 'A' или 'B'
SELECT COUNT(*) 
FROM track
WHERE name LIKE 'A%' OR name LIKE 'B%';

-- Задание 4: Количество уникальных стран, в которых живут клиенты
SELECT COUNT(DISTINCT country) 
FROM customer;

-- Задание 5: Страна с наибольшим числом клиентов
SELECT country
FROM customer
GROUP BY country
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Задание 6: Количество треков жанра с id=1, длительностью от 200 до 300 секунд (200000–300000 мс)
SELECT COUNT(*) 
FROM track
WHERE genre_id = 1 
  AND milliseconds BETWEEN 200000 AND 300000;

-- Задание 7: Количество клиентов с почтой на Gmail
SELECT COUNT(*) 
FROM customer
WHERE email LIKE '%@gmail.com';

-- Задание 8: Максимальная сумма счёта (total) для города Берлин
SELECT MAX(total)
FROM invoice
WHERE billing_city = 'Berlin';

-- Задание 9: Количество клиентов из Лондона, Парижа или Нью-Йорка
SELECT COUNT(*) 
FROM customer
WHERE city IN ('London', 'Paris', 'New York');

-- Задание 10: Количество сотрудников, работающих не в Калгари
SELECT COUNT(*) 
FROM employee
WHERE city != 'Calgary';

-- Задание 11: Количество треков группы Iron Maiden (через альбомы)
SELECT COUNT(*) 
FROM album a
JOIN artist ar ON a.artist_id = ar.artist_id
WHERE ar.name = 'Iron Maiden';

-- Задание 12: Общая длительность всех треков жанра Rock в минутах (округлённо)
SELECT ROUND(SUM(milliseconds) / 60000, 0) 
FROM track t
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock';

-- Задание 13: Страны, где средняя сумма счёта превышает 6
SELECT billing_country
FROM invoice
GROUP BY billing_country
HAVING AVG(total) > 6;

-- Задание 14: Жанр с наибольшим количеством проданных треков (по числу строк в invoice_line)
SELECT g.name, COUNT(*) 
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY g.name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Задание 15: Клиент с наибольшей общей суммой покупок
SELECT c.first_name,
       c.last_name, 
       SUM(i.total)
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.first_name, c.last_name
ORDER BY SUM(i.total) DESC
LIMIT 1;

-- Задание 16: Самый длинный трек группы Led Zeppelin (длительность в минутах)
SELECT t.name,
       ROUND(t.milliseconds / 60000, 0)
FROM track t
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
WHERE ar.name = 'Led Zeppelin'
ORDER BY t.milliseconds DESC 
LIMIT 1;

-- Задание 17: Месяц 2024 года с наименьшим количеством выставленных счетов
SELECT TO_CHAR(invoice_date, 'Month'),
       COUNT(invoice_id)
FROM invoice
WHERE EXTRACT(year FROM invoice_date) = 2024
GROUP BY TO_CHAR(invoice_date, 'Month')
ORDER BY COUNT(invoice_id)
LIMIT 1;

-- Задание 18: Квартал с наибольшей выручкой (сумма total округлена)
SELECT DATE_TRUNC('quarter', invoice_date)::date,
       ROUND(SUM(total)) AS best_quarter
FROM invoice
GROUP BY DATE_TRUNC('quarter', invoice_date)
ORDER BY SUM(total) DESC
LIMIT 1;

-- Задание 19: День недели с наибольшим числом счетов за 2023–2025 годы
SELECT TO_CHAR(invoice_date, 'Day'),
       COUNT(invoice_id)
FROM invoice
WHERE EXTRACT(year FROM invoice_date) BETWEEN 2023 AND 2025
GROUP BY TO_CHAR(invoice_date, 'Day')
ORDER BY COUNT(invoice_id) DESC
LIMIT 1;

-- Задание 20: Клиент с самым длительным периодом между первым и последним заказом
SELECT email,
       MAX(invoice_date) - MIN(invoice_date) AS period
FROM customer
JOIN invoice USING (customer_id)
GROUP BY email
ORDER BY period DESC
LIMIT 1;

-- Задание 21: Третий по популярности жанр (по числу проданных треков) только в зимние месяцы (январь, февраль, декабрь)
SELECT g.name,
       COUNT(i.invoice_id)
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
JOIN invoice i ON il.invoice_id = i.invoice_id
WHERE EXTRACT(month FROM i.invoice_date) IN (1, 2, 12)
GROUP BY g.name
ORDER BY COUNT(i.invoice_id) DESC
LIMIT 1
OFFSET 2;

-- Задание 22: Количество клиентов, потративших больше среднего, и email самого крупного покупателя
WITH customer_totals AS (
    SELECT 
        c.email,
        SUM(i.total) AS total_spent
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.email
),
avg_spending AS (
    SELECT AVG(total_spent) AS avg_total
    FROM customer_totals
)
SELECT 
    (SELECT COUNT(*) FROM customer_totals WHERE total_spent > (SELECT avg_total FROM avg_spending)) AS count,
    (SELECT email FROM customer_totals ORDER BY total_spent DESC LIMIT 1) AS top_email;

-- Задание 23: Количество альбомов, содержащих более 20 треков
SELECT COUNT(names)
FROM (
    SELECT a.title AS names
    FROM album a
    JOIN track t ON a.album_id = t.album_id
    GROUP BY a.title
    HAVING COUNT(t.track_id) > 20
) AS sub;

-- Задание 24: Количество клиентов, не совершивших ни одной покупки в 2025 году
SELECT COUNT(customer_id)
FROM customer
WHERE customer_id NOT IN (
    SELECT c.customer_id
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    WHERE EXTRACT(year FROM i.invoice_date) = 2025
);

-- Задание 25: Количество клиентов, купивших треки не менее чем из 11 разных жанров (меломаны)
SELECT COUNT(c.customer_id) AS melomaniac
FROM customer c
WHERE (
    SELECT COUNT(DISTINCT g.genre_id)
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    WHERE i.customer_id = c.customer_id
) >= 11;

-- Задание 26: Наибольшее количество клиентов в одном сегменте (VIP >43, Regular 38–43, New ≤38 по сумме трат)
SELECT MAX(clients) AS max_clients
FROM (
    SELECT 
        COUNT(client) AS clients,
        CASE 
            WHEN tot > 43 THEN 'VIP'
            WHEN tot > 38 AND tot <= 43 THEN 'Regular'
            ELSE 'New'
        END AS segment
    FROM (
        SELECT 
            customer_id AS client,
            SUM(total) AS tot
        FROM invoice
        GROUP BY customer_id
    ) AS customer_totals
    GROUP BY 
        CASE 
            WHEN tot > 43 THEN 'VIP'
            WHEN tot > 38 AND tot <= 43 THEN 'Regular'
            ELSE 'New'
        END
) AS segment_counts;

-- Задание 27: Количество клиентов, купивших не менее 8 треков группы Metallica
SELECT COUNT(customer_idd) AS met_fans
FROM (
    SELECT c.customer_id AS customer_idd
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album a ON t.album_id = a.album_id
    JOIN artist ar ON a.artist_id = ar.artist_id
    WHERE ar.name = 'Metallica'
    GROUP BY customer_idd
    HAVING COUNT(t.track_id) >= 8
) AS fans;

-- Задание 28: Процент изменения выручки по сравнению с предыдущим месяцем (первые 4 месяца 2025 года)
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', invoice_date) AS month,
        SUM(total) AS revenue
    FROM invoice
    WHERE invoice_date BETWEEN '2025-01-01' AND '2025-12-31'
    GROUP BY month
),
rrevenue AS (
    SELECT 
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly_revenue
)
SELECT 
    ROUND(
        CASE 
            WHEN previous_revenue IS NULL THEN NULL
            ELSE ((revenue - previous_revenue) / previous_revenue) * 100
        END
    , 2) AS percent_change
FROM rrevenue
ORDER BY month
LIMIT 4;

-- Задание 29: Накопленная (кумулятивная) выручка за октябрь, ноябрь, декабрь 2025 года
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', invoice_date) AS month,
        SUM(total) AS revenue
    FROM invoice
    WHERE EXTRACT(YEAR FROM invoice_date) = 2025
    GROUP BY month
),
rrevenue AS (
    SELECT 
        month,
        ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS ssum
    FROM monthly_revenue
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS month,
    ssum
FROM rrevenue
WHERE EXTRACT(MONTH FROM month) IN (10, 11, 12)
ORDER BY month;

-- Задание 30: Максимальное среднее значение трат среди трёх групп клиентов (разбитых по квартилям трат)
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        SUM(i.total) AS total_spent
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
),
spending_groups AS (
    SELECT 
        customer_id,
        total_spent,
        NTILE(3) OVER (ORDER BY total_spent) AS spending_group
    FROM customer_spending
),
group_data AS (
    SELECT 
        spending_group,
        ROUND(AVG(total_spent)::numeric, 2) AS group_avg
    FROM spending_groups
    GROUP BY spending_group
)
SELECT MAX(group_avg) AS max_group_avg
FROM group_data;
