1)
WITH cohorts AS
(SELECT customer_id,
       DATE_TRUNC('quarter', registration_date) AS cohort
FROM customers
ORDER BY cohort),

order_dates AS
(SELECT customer_id,
       DATE_TRUNC('quarter', order_date) AS order_date
FROM orders),

--SELECT *
--FROM cohorts c
--JOIN order_dates od USING(customer_id)

cohorta AS
(SELECT c.cohort,
       od.order_date,
	   COUNT(DISTINCT customer_id) AS cnt_customers
FROM cohorts c
JOIN order_dates od USING(customer_id)
GROUP BY c.cohort, od.order_date)

SELECT *,
       MAX(cnt_customers) OVER(PARTITION BY cohort) AS cnt_customers_in_cohort,
	   ROUND(cnt_customers::numeric/(MAX(cnt_customers) OVER(PARTITION BY cohort))::numeric,3) AS retention_rate
FROM cohorta;


2)
WITH cohorts  AS
(SELECT customer_id,
       DATE_TRUNC('quarter',  MIN(order_date) OVER(PARTITION BY customer_id)) AS cohort
FROM orders),

order_quarters AS
(SELECT customer_id,
       DATE_TRUNC ('quarter', order_date) AS order_quarter
FROM orders),

cohorta AS
(SELECT c.cohort,
       oq.order_quarter,
	   COUNT(DISTINCT customer_id) AS cnt_customers
FROM cohorts c
JOIN order_quarters oq USING(customer_id)
GROUP BY c.cohort, oq.order_quarter)

SELECT *,
	   ROUND(cnt_customers::numeric/(MAX(cnt_customers) OVER(PARTITION BY cohort))::numeric,3) AS retention_rate
FROM cohorta;

3)
WITH cohorts  AS
(SELECT customer_id,
       DATE_TRUNC('quarter',  MIN(order_date) OVER(PARTITION BY customer_id)) AS cohort
FROM orders),

order_quarters AS
(SELECT customer_id,
       DATE_TRUNC ('quarter', order_date) AS order_quarter
FROM orders),

cohorta AS
(SELECT c.cohort,
       oq.order_quarter,
     COUNT(DISTINCT customer_id) AS cnt_customers
FROM cohorts c
JOIN order_quarters oq USING(customer_id)
GROUP BY c.cohort, oq.order_quarter)

SELECT*,
       LAG(cnt_customers) OVER (PARTITION BY cohort ORDER BY order_quarter) AS previous_day_cnt_customers,
     ROUND(1-(cnt_customers/(LAG(cnt_customers) OVER (PARTITION BY cohort ORDER BY order_quarter))::numeric),2) AS churn_rate
FROM cohorta;
