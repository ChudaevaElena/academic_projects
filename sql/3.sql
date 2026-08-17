WITH regions AS (SELECT CASE 
          WHEN country IN ('Argentina', 'Brazil') THEN 'Южная Америка'
          WHEN country IN ('Canada', 'USA', 'Mexico') THEN 'Северная Америка'
          WHEN country IN ('Spain', 'UK', 'Italy', 'Germany', 'France') THEN 'Европа'
          WHEN country = 'Russia' THEN 'Россия'
        END AS region
        FROM contacts
        GROUP BY region),
     t_2020 AS (SELECT CASE 
              WHEN country IN ('Argentina', 'Brazil') THEN 'Южная Америка'
              WHEN country IN ('Canada', 'USA', 'Mexico') THEN 'Северная Америка'
              WHEN country IN ('Spain', 'UK', 'Italy', 'Germany', 'France') THEN 'Европа'
              WHEN country = 'Russia' THEN 'Россия'
        END AS region,
            SUM(total) AS total_2020
        FROM contacts
        JOIN orders ord USING(customer_id)
        WHERE EXTRACT(YEAR FROM ord.order_date) = 2020
        GROUP BY region),
     t_2021 AS (SELECT CASE 
              WHEN country IN ('Argentina', 'Brazil') THEN 'Южная Америка'
              WHEN country IN ('Canada', 'USA', 'Mexico') THEN 'Северная Америка'
              WHEN country IN ('Spain', 'UK', 'Italy', 'Germany', 'France') THEN 'Европа'
              WHEN country = 'Russia' THEN 'Россия'
        END AS region,
            SUM(total) AS total_2021
        FROM contacts
        JOIN orders ord USING(customer_id)
        WHERE EXTRACT(YEAR FROM ord.order_date) = 2021
        GROUP BY region),
     t_2022 AS (SELECT CASE 
              WHEN country IN ('Argentina', 'Brazil') THEN 'Южная Америка'
              WHEN country IN ('Canada', 'USA', 'Mexico') THEN 'Северная Америка'
              WHEN country IN ('Spain', 'UK', 'Italy', 'Germany', 'France') THEN 'Европа'
              WHEN country = 'Russia' THEN 'Россия'
        END AS region,
            SUM(total) AS total_2022
        FROM contacts
        JOIN orders ord USING(customer_id)
        WHERE EXTRACT(YEAR FROM ord.order_date) = 2022
        GROUP BY region),
     t_2023 AS (SELECT CASE 
              WHEN country IN ('Argentina', 'Brazil') THEN 'Южная Америка'
              WHEN country IN ('Canada', 'USA', 'Mexico') THEN 'Северная Америка'
              WHEN country IN ('Spain', 'UK', 'Italy', 'Germany', 'France') THEN 'Европа'
              WHEN country = 'Russia' THEN 'Россия'
        END AS region,
            SUM(total) AS total_2023
        FROM contacts
        JOIN orders ord USING(customer_id)
        WHERE EXTRACT(YEAR FROM ord.order_date) = 2023
        GROUP BY region)
SELECT regions.region,
     t_2020.total_2020,
     t_2021.total_2021,
     t_2022.total_2022,
     t_2023.total_2023
FROM regions 
JOIN t_2020 USING(region)
JOIN t_2021 USING(region)
JOIN t_2022 USING(region)
JOIN t_2023 USING(region)
