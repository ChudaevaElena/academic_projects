-- Создание таблицы и наполнение данными
CREATE TABLE companies (
    id integer PRIMARY KEY,
    company_name text,
    main_admin_id integer,
    additional_admins integer[],
    notify_emails text[]
);

INSERT INTO companies VALUES
(1, 'ООО "АльфаСофт"', 101, '{201,202,203}', '{"admin@alpha.ru","support@alpha.ru"}'),
(2, 'ООО "БетаСейлз"', 102, '{205,210}', '{"info@beta.ru","sales@beta.ru","ceo@beta.ru"}'),
(3, 'ЗАО "ГаммаМаркет"', 103, '{210,215,220}', '{"admin@gamma.ru"}'),
(4, 'ИП "Дельта-Сервис"', 104, '{201,210}', '{"owner@delta.ru","manager@delta.ru","tech@delta.ru"}');

-- Задание 1: первый и последний доп. администратор
SELECT company_name,
       additional_admins[1] AS first_admin,
       additional_admins[array_length(additional_admins, 1)] AS last_admin
FROM companies;

-- Задание 2: компании, где есть администратор с ID = 210
SELECT id,
       company_name
FROM companies
WHERE 210 = ANY(additional_admins);

-- Задание 3: компании с >= 3 доп. администраторами
SELECT company_name,
       additional_admins,
       array_length(additional_admins, 1) AS admins_count
FROM companies
WHERE array_length(additional_admins, 1) >= 3;

-- Задание 4: добавить администратора 230 в "БетаСейлз"
UPDATE companies
SET additional_admins = array_append(additional_admins, 230)
WHERE company_name = 'ООО "БетаСейлз"';

-- проверка обновления
SELECT company_name,
       additional_admins
FROM companies
WHERE company_name = 'ООО "БетаСейлз"';

-- Задание 5: список email-ов в виде строки через запятую
SELECT company_name,
       array_to_string(notify_emails, ', ') AS emails_list
FROM companies;

-- дополнительно: плоский список (один email на строку)
SELECT company_name,
       unnest(notify_emails) AS email
FROM companies;

-- Задание 6: фильтрация по множеству администраторов

-- вариант "содержит всех указанных" (201 и 210)
SELECT company_name,
       additional_admins,
       array_to_string(additional_admins, ', ') AS admins_list
FROM companies
WHERE additional_admins @> STRING_TO_ARRAY('201, 210', ', ')::integer[];

-- вариант "содержит хотя бы одного из указанных" (201 или 210)
SELECT company_name,
       additional_admins,
       array_to_string(additional_admins, ', ') AS admins_list
FROM companies
WHERE additional_admins && STRING_TO_ARRAY('201, 210', ', ')::integer[];
