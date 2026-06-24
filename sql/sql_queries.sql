-- 1. Выборка всех закрытых компаний
SELECT *
FROM company
WHERE status = 'closed';

-- 2. Рейтинг новостных компаний США по объёму финансирования
SELECT name, funding_total
FROM company
WHERE country_code = 'USA' AND category_code = 'news'
ORDER BY funding_total DESC;

-- 3. Общая сумма поглощений за наличные за 2011-2013 гг.
SELECT SUM(price_amount) AS total_acquisitions
FROM acquisition
WHERE term_code = 'cash' AND 
 acquired_at BETWEEN '2011-01-01' AND '2013-12-31';

-- 4. Поиск людей, чей Twitter-ник начинается на Silver
SELECT first_name, last_name, twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%';

-- 5. Поиск людей со словом money в Twitter-нике и фамилией на K
SELECT *
FROM people
WHERE twitter_username LIKE '%money%' AND last_name LIKE 'K%';

-- 6. Общее финансирование по странам, от большего к меньшему
SELECT country_code, SUM(funding_total) AS total_funding
FROM company
GROUP BY country_code
ORDER BY total_funding DESC;

-- 7. Минимальные и максимальные инвестиции по датам раундов
-- только там, где минимум не равен нулю и не равен максимуму
SELECT funded_at, MIN(raised_amount) AS min_investment, MAX(raised_amount) AS max_investment
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) <> 0 AND MIN(raised_amount) <> MAX(raised_amount);

-- 8. Категоризация фондов по инвестиционной активности
SELECT *, 
CASE 
 WHEN invested_companies >= 100 THEN 'high_activity'
 WHEN invested_companies >= 20 THEN 'middle_activity'
 ELSE 'low_activity'
END AS activity_category
FROM fund;

-- 9. Средние раунды инвестиций по категориям активности
SELECT activity_category, ROUND(AVG(investment_rounds)) AS avg_rounds
FROM (
 SELECT invested_companies,
 CASE 
 WHEN invested_companies >= 100 THEN 'high_activity'
 WHEN invested_companies >= 20 THEN 'middle_activity'
 ELSE 'low_activity'
 END AS activity_category,
 investment_rounds
 FROM fund
) AS categorization
GROUP BY activity_category
ORDER BY avg_rounds ASC;

-- 10. Топ-10 стран по охвату компаний фондами, основанными в 2010-2012 гг.
SELECT f.country_code, 
 MIN(companies_count) AS min_companies, 
 MAX(companies_count) AS max_companies, 
 AVG(companies_count) AS avg_companies
FROM (
 SELECT fund.country_code, COUNT(DISTINCT investment.company_id) AS companies_count
 FROM fund f
 JOIN investment ON fund.id = investment.fund_id
 JOIN funding_round ON investment.funding_round_id = funding_round.id
 WHERE fund.founded_at BETWEEN '2010-01-01' AND '2012-12-31'
 GROUP BY fund.id
) AS country_investments
GROUP BY country_code
HAVING MIN(companies_count) > 0
ORDER BY avg_companies DESC, country_code ASC
LIMIT 10;

-- 11. Список сотрудников с университетами, включая тех без образования
SELECT p.first_name, p.last_name, e.instituition
FROM people p
LEFT JOIN education e ON p.id = e.person_id;

-- 12. Топ-5 компаний по количеству уникальных университетов сотрудников
SELECT c.name AS company_name, COUNT(DISTINCT e.instituition) AS universities_count
FROM company c
JOIN people p ON c.id = p.company_id
LEFT JOIN education e ON p.id = e.person_id
GROUP BY c.id
ORDER BY universities_count DESC
LIMIT 5;

-- 13. Закрытые компании, у которых первый раунд финансирования был одновременно последним
SELECT DISTINCT c.name
FROM company c
JOIN funding_round fr ON c.id = fr.company_id
WHERE c.status = 'closed' AND fr.is_first_round = TRUE AND fr.is_last_round = TRUE;

-- 14. Сотрудники закрытых компаний с единственным раундом финансирования
SELECT DISTINCT p.id AS employee_id
FROM people p
WHERE p.company_id IN (SELECT id FROM company WHERE status = 'closed' AND 
 id IN (SELECT company_id FROM funding_round WHERE is_first_round = TRUE AND is_last_round = TRUE));

-- 15. Университеты сотрудников из задания 14
SELECT DISTINCT p.id AS employee_id, e.instituition
FROM people p
JOIN education e ON p.id = e.person_id
WHERE p.id IN (SELECT DISTINCT p.id
 FROM people p
 WHERE p.company_id IN (SELECT id FROM company WHERE status = 'closed' AND 
 id IN (SELECT company_id FROM funding_round WHERE is_first_round = TRUE AND is_last_round = TRUE)));

-- 16. Количество учебных заведений на каждого сотрудника
SELECT employee_id, COUNT(instituition) AS total_institutions
FROM (SELECT p.id AS employee_id, e.instituition
 FROM people p
 JOIN education e ON p.id = e.person_id) AS employee_education
GROUP BY employee_id;
