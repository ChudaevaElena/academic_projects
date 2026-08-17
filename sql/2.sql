CREATE TABLE employees (employee_id SERIAL PRIMARY KEY,
 first_name VARCHAR(50),
 last_name VARCHAR(50),
 hire_date DATE,
 department VARCHAR(50),
 salary NUMERIC,
 manager_id INTEGER);
1.
SELECT department,
 COUNT(*) quantity
FROM employees
GROUP BY department;
2.
SELECT *
FROM employees
WHERE manager_id IS NULL;
3.
SELECT *
FROM employees
WHERE last_name LIKE 'S%' AND
 salary > 70000;
4.
SELECT *
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2021 AND
 manager_id = 5;
5.
SELECT department,
 EXTRACT(YEAR FROM hire_date) hire_year,
 COUNT(*) employee_count
FROM employees
GROUP BY department, hire_year
ORDER BY employee_count DESC, department;
6.
SELECT department,
 AVG(salary) average_salary
FROM employees
GROUP BY department
ORDER BY average_salary DESC;
7.
SELECT department,
 COUNT(*) employee_count,
 SUM(salary) total_salary
FROM employees
GROUP BY department
HAVING SUM(salary) > 200000;
8.
SELECT EXTRACT(YEAR FROM hire_date) hire_year,
 EXTRACT(QUARTER FROM hire_date) hire_quarter,
 COUNT(*) 
FROM employees
GROUP BY hire_year, hire_quarter
HAVING COUNT(*) > 5;
9.
SELECT 
 CASE 
 WHEN salary > 80000 THEN 'High'
 WHEN salary BETWEEN 50000 AND 80000 THEN 'Medium'
 ELSE 'Низкий'
 END salary_level,
 COUNT(*) employee_count
FROM employees
GROUP BY salary_level;
10.
SELECT department, 
 AVG(salary) average_salary
FROM employees
WHERE hire_date > '2015-01-01'
GROUP BY department
HAVING AVG(salary) > 55000;
