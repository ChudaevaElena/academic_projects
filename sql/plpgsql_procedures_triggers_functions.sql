-- Задание 1: обновление ставок из JSON с гарантией минимума 500
CREATE OR REPLACE PROCEDURE update_employees_rate(p_data json)
LANGUAGE plpgsql
AS $$
DECLARE
    _rec record;
    _new_rate numeric;
BEGIN
    FOR _rec IN 
        SELECT 
            (value->>'employee_id')::uuid AS employee_id,
            (value->>'rate_change')::numeric AS rate_change
        FROM json_array_elements(p_data)
    LOOP
        SELECT rate + rate * (_rec.rate_change / 100)
        INTO _new_rate
        FROM employees
        WHERE id = _rec.employee_id;
        IF _new_rate < 500 THEN
            _new_rate := 500;
        END IF;
        UPDATE employees
        SET rate = ROUND(_new_rate)
        WHERE id = _rec.employee_id;
    END LOOP;
END;
$$;

CALL update_employees_rate(
'[
 {"employee_id": "80718590-e2bf-492b-8c83-6f8c11d007b1", "rate_change": 10},
 {"employee_id": "dd0ba8dd-6c75-437c-9c68-824971ccc078", "rate_change": -5}
]'::json
);

-- Задание 2: индексация зарплат – ниже среднего получают на 2% больше
CREATE OR REPLACE PROCEDURE indexing_salary(p integer)
LANGUAGE plpgsql
AS $$
DECLARE
    _avg_rate numeric;
    _rec record;
    _new_rate numeric;
BEGIN
    SELECT AVG(rate)
    INTO _avg_rate
    FROM employees;
    FOR _rec IN 
        SELECT id, rate
        FROM employees
    LOOP
        IF _rec.rate < _avg_rate THEN
            _new_rate := _rec.rate + _rec.rate * ((p + 2)::numeric / 100);
        ELSE
            _new_rate := _rec.rate + _rec.rate * (p::numeric / 100);
        END IF;
        UPDATE employees
        SET rate = ROUND(_new_rate)
        WHERE id = _rec.id;
    END LOOP;
END;
$$;

CALL indexing_salary(5);

-- Задание 3: закрытие проекта, начисление бонусных часов (до 16 на человека)
CREATE OR REPLACE PROCEDURE close_project(p_project_id uuid)
LANGUAGE plpgsql
AS $$
DECLARE
    _is_active boolean;
    _estimated_time integer;
    _total_hours numeric;
    _participants_count integer;
    _bonus_hours numeric;
    _rec record;
BEGIN
    SELECT is_active, estimated_time
    INTO _is_active, _estimated_time
    FROM projects
    WHERE id = p_project_id;
    IF _is_active = false THEN
        RAISE EXCEPTION 'Project already closed';
    END IF;
    SELECT SUM(work_hours)
    INTO _total_hours
    FROM logs
    WHERE project_id = p_project_id;
    UPDATE projects
    SET is_active = false
    WHERE id = p_project_id;
    IF _estimated_time IS NULL OR _total_hours IS NULL THEN
        RETURN;
    END IF;
    IF _estimated_time <= _total_hours THEN
        RETURN;
    END IF;
    SELECT COUNT(DISTINCT employee_id)
    INTO _participants_count
    FROM logs
    WHERE project_id = p_project_id;
    IF _participants_count = 0 THEN
        RETURN;
    END IF;
    _bonus_hours := (_estimated_time - _total_hours) * 0.75 / _participants_count;
    IF _bonus_hours > 16 THEN
        _bonus_hours := 16;
    END IF;
    _bonus_hours := FLOOR(_bonus_hours);
    IF _bonus_hours <= 0 THEN
        RETURN;
    END IF;
    FOR _rec IN
        SELECT DISTINCT employee_id
        FROM logs
        WHERE project_id = p_project_id
    LOOP
        INSERT INTO logs(
            employee_id,
            project_id,
            work_date,
            work_hours,
            required_review,
            is_paid
        )
        VALUES (
            _rec.employee_id,
            p_project_id,
            CURRENT_DATE,
            _bonus_hours,
            false,
            false
        );
    END LOOP;
END;
$$;

CALL close_project('4abb5b99-3889-4c20-a575-e65886f266f9');

-- Задание 4: логирование часов с проверками (проект активен, часы 1–24, флаг ревью)
CREATE OR REPLACE PROCEDURE log_work(
    p_employee_id uuid,
    p_project_id uuid,
    p_work_date date,
    p_work_hours integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    _is_active boolean;
    _required_review boolean := false;
BEGIN
    SELECT is_active
    INTO _is_active
    FROM projects
    WHERE id = p_project_id;
    IF _is_active = false THEN
        RAISE EXCEPTION 'Project closed';
    END IF;
    IF p_work_hours < 1 OR p_work_hours > 24 THEN
        RAISE EXCEPTION 'Invalid work hours';
    END IF;
    IF p_work_hours > 16 THEN
        _required_review := true;
    END IF;
    IF p_work_date > CURRENT_DATE THEN
        _required_review := true;
    END IF;
    IF p_work_date < CURRENT_DATE - 7 THEN
        _required_review := true;
    END IF;
    INSERT INTO logs(
        employee_id,
        project_id,
        work_date,
        work_hours,
        required_review,
        is_paid
    )
    VALUES (
        p_employee_id,
        p_project_id,
        p_work_date,
        p_work_hours,
        _required_review,
        false
    );
END;
$$;

CALL log_work('80718590-e2bf-492b-8c83-6f8c11d007b1',
              '35647af3-2aac-45a0-8d76-94bc250598c2',
              '2023-10-22',
              4);

-- Задание 5: триггер для истории изменения ставок
CREATE TABLE employee_rate_history(
    id serial PRIMARY KEY,
    employee_id uuid,
    rate integer,
    from_date date
);

INSERT INTO employee_rate_history(employee_id, rate, from_date)
SELECT id, rate, '2020-12-26'
FROM employees;

CREATE OR REPLACE FUNCTION save_employee_rate_history()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employee_rate_history(employee_id, rate, from_date)
        VALUES (NEW.id, NEW.rate, CURRENT_DATE);
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF NEW.rate <> OLD.rate THEN
            INSERT INTO employee_rate_history(employee_id, rate, from_date)
            VALUES (NEW.id, NEW.rate, CURRENT_DATE);
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER change_employee_rate
AFTER INSERT OR UPDATE
ON employees
FOR EACH ROW
EXECUTE FUNCTION save_employee_rate_history();

-- Задание 6: топ-3 сотрудников по часам для проекта
CREATE OR REPLACE FUNCTION best_project_workers(p_project_id uuid)
RETURNS TABLE (
    employee text,
    work_hours integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.name,
        SUM(l.work_hours)::integer
    FROM logs l
    JOIN employees e ON e.id = l.employee_id
    WHERE l.project_id = p_project_id
    GROUP BY e.name
    ORDER BY SUM(l.work_hours) DESC
    LIMIT 3;
END;
$$;

SELECT *
FROM best_project_workers('4abb5b99-3889-4c20-a575-e65886f266f9');

-- Задание 7: расчёт зарплаты за месяц (сверхурочные ×1.25)
CREATE OR REPLACE FUNCTION calculate_month_salary(
    p_date_from date,
    p_date_to date
)
RETURNS TABLE (
    id uuid,
    employee text,
    worked_hours integer,
    salary numeric
)
LANGUAGE plpgsql
AS $$
DECLARE
    _rec record;
    _hours integer;
    _salary numeric;
BEGIN
    FOR _rec IN
        SELECT 
            e.id,
            e.name,
            e.rate,
            SUM(l.work_hours)::integer AS total_hours
        FROM employees e
        JOIN logs l ON l.employee_id = e.id
        WHERE l.work_date BETWEEN p_date_from AND p_date_to
          AND l.required_review = false
          AND l.is_paid = false
        GROUP BY e.id, e.name, e.rate
    LOOP
        _hours := _rec.total_hours;
        IF _hours > 160 THEN
            _salary := (160 * _rec.rate) + ((_hours - 160) * _rec.rate * 1.25);
        ELSE
            _salary := _hours * _rec.rate;
        END IF;
        id := _rec.id;
        employee := _rec.name;
        worked_hours := _hours;
        salary := _salary;
        RETURN NEXT;
    END LOOP;
END;
$$;

SELECT *
FROM calculate_month_salary('2023-10-01', '2023-10-31');

-- проверочные запросы
SELECT *
FROM logs
ORDER BY created_at DESC;

SELECT id FROM employees;
SELECT id, name FROM projects;
