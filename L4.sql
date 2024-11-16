--Stw�rz funkcje:
--1.	Zwracaj�c� nazw� pracy dla podanego parametru id, dodaj 
--wyj�tek, je�li taka praca nie istnieje
CREATE OR REPLACE FUNCTION get_job_title(p_job_id VARCHAR2) RETURN VARCHAR2 IS
    v_job_title VARCHAR2(50);
BEGIN
    SELECT job_title INTO v_job_title
    FROM jobs
    WHERE job_id = p_job_id;
    
    RETURN v_job_title;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Job ID not found');
END;

SELECT get_job_title('DEV') FROM dual;
SELECT get_job_title('DEV12') FROM dual;

--2.	zwracaj�c� roczne zarobki (wynagrodzenie 12-to miesi�czne 
--plus premia jako wynagrodzenie * commission_pct) dla pracownika 
--o podanym id
CREATE OR REPLACE FUNCTION get_annual_salary(p_employee_id NUMBER) RETURN NUMBER IS
    v_salary NUMBER;
    v_commission_pct NUMBER;
BEGIN
    SELECT salary, NVL(commission_pct, 0) INTO v_salary, v_commission_pct
    FROM employees
    WHERE employee_id = p_employee_id;
    
    RETURN (v_salary * 12) + (v_salary * v_commission_pct);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Employee ID not found');
END;

SELECT get_annual_salary(100) FROM dual;

--3.	bior�c� w nawias numer kierunkowy z numeru telefonu 
--podanego jako varchar
CREATE OR REPLACE FUNCTION get_formatted_phone(p_phone_number VARCHAR2) RETURN VARCHAR2 IS
    v_area_code VARCHAR2(10);
    v_rest_number VARCHAR2(20);
    v_formatted_phone VARCHAR2(30);
BEGIN
    IF LENGTH(p_phone_number) > 9 THEN
        v_area_code := SUBSTR(p_phone_number, 1, INSTR(p_phone_number, '-') - 1);
        v_rest_number := SUBSTR(p_phone_number, INSTR(p_phone_number, '-') + 1);
        v_formatted_phone := '(' || v_area_code || ')' || v_rest_number;
        DBMS_OUTPUT.PUT_LINE('v_area_code:' || v_area_code);
        DBMS_OUTPUT.PUT_LINE('v_rest_number:' || v_rest_number);
        DBMS_OUTPUT.PUT_LINE('v_formatted_phone:' || v_formatted_phone);
    ELSE
        v_formatted_phone := p_phone_number;
    END IF;
    
    RETURN v_formatted_phone;
END;


SELECT get_formatted_phone('89-123-456-789') FROM dual;

--4.	Dla podanego w parametrze ci�gu znak�w zmieniaj�c� pierwsz�
--i ostatni� liter� na wielk� � pozosta�e na ma�e
CREATE OR REPLACE FUNCTION capitalize_first_last(p_string VARCHAR2) RETURN VARCHAR2 IS
    v_result VARCHAR2(100);
BEGIN
    v_result := UPPER(SUBSTR(p_string, 1, 1)) ||
                LOWER(SUBSTR(p_string, 2, LENGTH(p_string) - 2)) ||
                UPPER(SUBSTR(p_string, -1));
    RETURN v_result;
END;
SELECT capitalize_first_last('oracle db ale zabawa') FROM dual;

--5.	Dla podanego peselu - przerabiaj�c� pesel na dat� urodzenia
--w formacie �yyyy-mm-dd�
CREATE OR REPLACE FUNCTION pesel_to_birthdate(p_pesel VARCHAR2) RETURN DATE IS
    v_year NUMBER;
    v_month NUMBER;
    v_day NUMBER;
    v_birthdate DATE;
BEGIN
    v_year := TO_NUMBER(SUBSTR(p_pesel, 1, 2));
    v_month := TO_NUMBER(SUBSTR(p_pesel, 3, 2));
    v_day := TO_NUMBER(SUBSTR(p_pesel, 5, 2));

    IF v_month > 20 THEN
        v_month := v_month - 20;
        v_year := 2000 + v_year;
    ELSE
        v_year := 1900 + v_year;
    END IF;

    v_birthdate := TO_DATE(v_year || '-' || v_month || '-' || v_day, 'YYYY-MM-DD');
    RETURN v_birthdate;
END;
SELECT pesel_to_birthdate('68210300971') FROM dual;
SELECT pesel_to_birthdate('30248500271') FROM dual;

--6.	Zwracaj�c� liczb� pracownik�w oraz liczb� departament�w 
--kt�re znajduj� si� w kraju podanym jako parametr (nazwa kraju). 
--W przypadku braku kraju - odpowiedni wyj�tek
CREATE OR REPLACE FUNCTION get_counts_by_country(p_country_name VARCHAR2) 
RETURN VARCHAR2 IS
    v_country_name countries.country_name%TYPE;
    v_employee_count NUMBER;
    v_department_count NUMBER;
BEGIN
    SELECT c.country_name 
    INTO v_country_name
    FROM countries c
    WHERE c.country_name = p_country_name;
    
    IF v_country_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20003, 'Country not found.');
        END IF;
        
    SELECT COUNT(*)
    INTO v_employee_count
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN locations l ON d.location_id = l.location_id
    JOIN countries c ON l.country_id = c.country_id
    WHERE c.country_name = p_country_name;

    SELECT COUNT(*)
    INTO v_department_count
    FROM departments d
    JOIN locations l ON d.location_id = l.location_id
    JOIN countries c ON l.country_id = c.country_id
    WHERE c.country_name = p_country_name;

    RETURN 'Employees: ' || v_employee_count || ', Departments: ' || v_department_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Country not found.');
END;
SELECT get_counts_by_country('Canada') FROM dual;
SELECT get_counts_by_country('X') FROM dual;

--Stworzy� nast�puj�ce wyzwalacze:
--1.	Stworzy� tabel� archiwum_departament�w (id, nazwa, data_zamkni�cia, ostatni_manager 
--jako imi� i nazwisko). Po usuni�ciu departamentu doda� odpowiedni rekord do tej tabeli
CREATE TABLE archiwum_departamentow (
    id NUMBER,
    nazwa VARCHAR2(50),
    data_zamkniecia DATE,
    ostatni_manager VARCHAR2(100)
);

-- Tworzenie wyzwalacza
CREATE OR REPLACE TRIGGER trg_after_delete_department
AFTER DELETE ON departments
FOR EACH ROW
BEGIN
    INSERT INTO archiwum_departamentow (id, nazwa, data_zamkniecia, ostatni_manager)
    VALUES (:OLD.department_id, :OLD.department_name, SYSDATE,
            (SELECT first_name || ' ' || last_name 
             FROM employees 
             WHERE employee_id = :OLD.manager_id));
END;

--2.	W razie UPDATE i INSERT na tabeli employees, sprawdzi� czy zarobki �api� si� w 
--wide�kach 2000 - 26000. Je�li nie �api� si� - zabroni� dodania. Doda� tabel� 
--z�odziej(id, USER, czas_zmiany), kt�rej b�d� wrzucane logi, je�li b�dzie pr�ba dodania, 
--b�d� zmiany wynagrodzenia poza wide�ki.

SELECT user from dual;
INSERT INTO zlodziej (username) VALUES (USER);

CREATE TABLE zlodziej (
    id NUMBER GENERATED BY DEFAULT AS IDENTITY,
    username VARCHAR2(50),
    czas_zmiany TIMESTAMP DEFAULT SYSTIMESTAMP
);

--CREATE SEQUENCE zlodziej_seq
--START WITH 1
--INCREMENT BY 1
--NOCACHE;

-- Tworzenie wyzwalacza do walidacji wide�ek wynagrodzenia i logowania pr�b narusze�
CREATE OR REPLACE TRIGGER trg_salary_check
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    
    IF :NEW.salary < 2000 OR :NEW.salary > 26000 THEN
        INSERT INTO zlodziej (username) 
        VALUES (USER);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('user:' || USER);
        RAISE_APPLICATION_ERROR(-20004, 'Wynagrodzenie poza dozwolonymi wide�kami (2000 - 26000).');
    END IF;
END;

UPDATE employees
SET salary = 27000
WHERE employee_id = 100;


--3.	Stworzy� sekwencj� i wyzwalacz, kt�ry b�dzie odpowiada� za auto_increment w tabeli 
--employees.
-- Zmiana nazwy kolumny w tabeli
-- Tworzenie sekwencji
CREATE SEQUENCE emp_seq
START WITH 1
INCREMENT BY 1
NOCACHE;

-- Wyzwalacz dla auto_increment kolumny employee_id
CREATE OR REPLACE TRIGGER trg_emp_auto_increment
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF :NEW.employee_id IS NULL THEN
        :NEW.employee_id := emp_seq.NEXTVAL;
    END IF;
END;

--4.	Stworzy� wyzwalacz, kt�ry zabroni dowolnej operacji na tabeli 
--JOD_GRADES (INSERT, UPDATE, DELETE)
-- Wyzwalacz blokuj�cy INSERT, UPDATE, DELETE na JOB_GRADES
CREATE OR REPLACE TRIGGER trg_block_jod_grades
BEFORE INSERT OR UPDATE OR DELETE ON JOB_GRADES
BEGIN
    RAISE_APPLICATION_ERROR(-20005, 'Operacje na tabeli JOD_GRADES s� zabronione.');
END;

--5.	Stworzy� wyzwalacz, kt�ry przy pr�bie zmiany max i min salary w tabeli jobs 
--zostawia stare warto�ci.
-- Wyzwalacz, kt�ry uniemo�liwia zmian� min_salary i max_salary w jobs
CREATE OR REPLACE TRIGGER trg_jobs_protect_salary
BEFORE UPDATE OF min_salary, max_salary ON jobs
FOR EACH ROW
BEGIN
    :NEW.min_salary := :OLD.min_salary;
    :NEW.max_salary := :OLD.max_salary;
END;

--Stworzy� paczki:
--1.	Sk�adaj�c� si� ze stworzonych procedur i funkcji
CREATE OR REPLACE PACKAGE utility_package IS
    -- Deklaracje funkcji
    FUNCTION get_job_title(p_job_id VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_annual_salary(p_employee_id NUMBER) RETURN NUMBER;
    FUNCTION get_formatted_phone(p_phone_number VARCHAR2) RETURN VARCHAR2;
    FUNCTION pesel_to_birthdate(p_pesel VARCHAR2) RETURN DATE;
    FUNCTION capitalize_first_last(p_string VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_counts_by_country(p_country_name VARCHAR2) RETURN VARCHAR2;
    
    -- Deklaracje procedur
    PROCEDURE add_job(p_job_id VARCHAR2, p_job_title VARCHAR2);
    PROCEDURE update_job_title(p_job_id VARCHAR2, p_new_job_title VARCHAR2);
    PROCEDURE delete_job(p_job_id VARCHAR2);
    PROCEDURE get_employee_salary_lastname(p_employee_id NUMBER, p_salary OUT NUMBER, p_last_name OUT VARCHAR2);
    PROCEDURE add_employee(
        p_first_name VARCHAR2,
        p_last_name VARCHAR2,
        p_email VARCHAR2,
        p_phone_number VARCHAR2,
        p_hire_date DATE DEFAULT SYSDATE,
        p_job_id VARCHAR2 DEFAULT 'DEV',
        p_salary NUMBER DEFAULT 5000,
        p_commission_pct NUMBER DEFAULT NULL,
        p_manager_id NUMBER DEFAULT 1,
        p_department_id NUMBER DEFAULT 100
    );
END utility_package;

CREATE OR REPLACE PACKAGE BODY utility_package AS

    FUNCTION get_job_title(p_job_id VARCHAR2) RETURN VARCHAR2 IS
        v_job_title VARCHAR2(50);
    BEGIN
        SELECT job_title INTO v_job_title
        FROM jobs
        WHERE job_id = p_job_id;
        
        RETURN v_job_title;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Job ID not found');
    END get_job_title;
    
    FUNCTION get_annual_salary(p_employee_id NUMBER) RETURN NUMBER IS
        v_salary NUMBER;
        v_commission_pct NUMBER;
    BEGIN
        SELECT salary, NVL(commission_pct, 0) INTO v_salary, v_commission_pct
        FROM employees
        WHERE employee_id = p_employee_id;
        
        RETURN (v_salary * 12) + (v_salary * v_commission_pct);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Employee ID not found');
    END get_annual_salary;
    
    FUNCTION get_formatted_phone(p_phone_number VARCHAR2) RETURN VARCHAR2 IS
        v_area_code VARCHAR2(10);
        v_rest_number VARCHAR2(20);
        v_formatted_phone VARCHAR2(30);
    BEGIN
        IF LENGTH(p_phone_number) > 9 THEN
            v_area_code := SUBSTR(p_phone_number, 1, INSTR(p_phone_number, '-') - 1);
            v_rest_number := SUBSTR(p_phone_number, INSTR(p_phone_number, '-') + 1);
            v_formatted_phone := '(' || v_area_code || ')' || v_rest_number;
            DBMS_OUTPUT.PUT_LINE('v_area_code:' || v_area_code);
            DBMS_OUTPUT.PUT_LINE('v_rest_number:' || v_rest_number);
            DBMS_OUTPUT.PUT_LINE('v_formatted_phone:' || v_formatted_phone);
        ELSE
            v_formatted_phone := p_phone_number;
        END IF;
        
        RETURN v_formatted_phone;
    END get_formatted_phone;
    
    FUNCTION capitalize_first_last(p_string VARCHAR2) RETURN VARCHAR2 IS
        v_result VARCHAR2(100);
    BEGIN
        v_result := UPPER(SUBSTR(p_string, 1, 1)) ||
                    LOWER(SUBSTR(p_string, 2, LENGTH(p_string) - 2)) ||
                    UPPER(SUBSTR(p_string, -1));
        RETURN v_result;
    END capitalize_first_last;
    
    FUNCTION pesel_to_birthdate(p_pesel VARCHAR2) RETURN DATE IS
        v_year NUMBER;
        v_month NUMBER;
        v_day NUMBER;
        v_birthdate DATE;
    BEGIN
        v_year := TO_NUMBER(SUBSTR(p_pesel, 1, 2));
        v_month := TO_NUMBER(SUBSTR(p_pesel, 3, 2));
        v_day := TO_NUMBER(SUBSTR(p_pesel, 5, 2));
    
        IF v_month > 20 THEN
            v_month := v_month - 20;
            v_year := 2000 + v_year;
        ELSE
            v_year := 1900 + v_year;
        END IF;
    
        v_birthdate := TO_DATE(v_year || '-' || v_month || '-' || v_day, 'YYYY-MM-DD');
        RETURN v_birthdate;
    END pesel_to_birthdate;
    
    FUNCTION get_counts_by_country(p_country_name VARCHAR2) 
    RETURN VARCHAR2 IS
        v_country_name countries.country_name%TYPE;
        v_employee_count NUMBER;
        v_department_count NUMBER;
    BEGIN
        SELECT c.country_name 
        INTO v_country_name
        FROM countries c
        WHERE c.country_name = p_country_name;
        
        IF v_country_name IS NULL THEN
                RAISE_APPLICATION_ERROR(-20003, 'Country not found.');
            END IF;
            
        SELECT COUNT(*)
        INTO v_employee_count
        FROM employees e
        JOIN departments d ON e.department_id = d.department_id
        JOIN locations l ON d.location_id = l.location_id
        JOIN countries c ON l.country_id = c.country_id
        WHERE c.country_name = p_country_name;
    
        SELECT COUNT(*)
        INTO v_department_count
        FROM departments d
        JOIN locations l ON d.location_id = l.location_id
        JOIN countries c ON l.country_id = c.country_id
        WHERE c.country_name = p_country_name;
    
        RETURN 'Employees: ' || v_employee_count || ', Departments: ' || v_department_count;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Country not found.');
    END get_counts_by_country;
    
    PROCEDURE add_job(p_job_id VARCHAR2, p_job_title VARCHAR2) AS
    BEGIN
        INSERT INTO jobs (job_id, job_title)
        VALUES (p_job_id, p_job_title);
    
        DBMS_OUTPUT.PUT_LINE('Job added: ' || p_job_id || ', ' || p_job_title);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
    END add_job;
    
    PROCEDURE update_job_title(p_job_id VARCHAR2, p_new_job_title VARCHAR2) AS
        rows_updated NUMBER;
    BEGIN
        UPDATE jobs
        SET job_title = p_new_job_title
        WHERE job_id = p_job_id;
    
        rows_updated := SQL%ROWCOUNT;
    
        IF rows_updated = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'No Jobs updated');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Job title updated for ID: ' || p_job_id);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
    END update_job_title;
    
    PROCEDURE delete_job(p_job_id VARCHAR2) AS
        rows_deleted NUMBER;
    BEGIN
        DELETE FROM jobs
        WHERE job_id = p_job_id;
    
        rows_deleted := SQL%ROWCOUNT;
    
        IF rows_deleted = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'No Jobs deleted');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Job deleted for ID: ' || p_job_id);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
    END delete_job;

    PROCEDURE get_employee_salary_lastname(p_employee_id NUMBER, 
                                         p_salary OUT NUMBER, 
                                         p_last_name OUT VARCHAR2) AS
    BEGIN
        SELECT salary, last_name
        INTO p_salary, p_last_name
        FROM employees
        WHERE employee_id = p_employee_id;
    
        DBMS_OUTPUT.PUT_LINE('Employee ' || p_last_name || ', Salary: ' || p_salary);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No employee found with ID: ' || p_employee_id);
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
    END get_employee_salary_lastname;
    
    PROCEDURE add_employee(p_first_name VARCHAR2,
                         p_last_name VARCHAR2,
                         p_email VARCHAR2,
                         p_phone_number VARCHAR2,
                         p_hire_date DATE DEFAULT SYSDATE,
                         p_job_id VARCHAR2 DEFAULT 'DEV',
                         p_salary NUMBER DEFAULT 5000,
                         p_commission_pct NUMBER DEFAULT NULL,
                         p_manager_id NUMBER DEFAULT 1,
                         p_department_id NUMBER DEFAULT 100
                                             ) AS
        new_employee_id NUMBER;
    BEGIN
        IF p_salary > 20000 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Salary exceeds the limit of 20000');
        END IF;
    
        -- Ustawienie ID pracownika z sekwencji
        SELECT employees_seq.NEXTVAL INTO new_employee_id FROM dual;
    
        INSERT INTO employees (
            employee_id, first_name, last_name, email, phone_number, hire_date,
            job_id, salary, commission_pct, manager_id, department_id
        )
        VALUES (
            new_employee_id, p_first_name, p_last_name, p_email, p_phone_number,
            p_hire_date, p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id
        );
    
        DBMS_OUTPUT.PUT_LINE('Employee added with ID: ' || new_employee_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
    END add_employee;

END utility_package;

BEGIN
    utility_package.add_job('JUN', 'Junior');
END;
/
SELECT utility_package.get_annual_salary(101) FROM dual;


--2.	Stworzy� paczk� z procedurami i funkcjami do obs�ugi tabeli REGIONS (CRUD), 
--gdzie odczyt z r�nymi parametrami
CREATE OR REPLACE PACKAGE regions_package IS
    PROCEDURE create_region(p_region_id NUMBER, p_region_name VARCHAR2);
    PROCEDURE read_region(p_region_id NUMBER, p_region_name OUT VARCHAR2);
    PROCEDURE update_region(p_region_id NUMBER, p_new_name VARCHAR2);
    PROCEDURE delete_region(p_region_id NUMBER);
END regions_package;

CREATE OR REPLACE PACKAGE BODY regions_package IS

    PROCEDURE create_region(p_region_id NUMBER, p_region_name VARCHAR2) IS
    BEGIN
        INSERT INTO regions (region_id, region_name) VALUES (p_region_id, p_region_name);
    END;

    PROCEDURE read_region(p_region_id NUMBER, p_region_name OUT VARCHAR2) IS
    BEGIN
        SELECT region_name INTO p_region_name FROM regions WHERE region_id = p_region_id;
    END;

    PROCEDURE update_region(p_region_id NUMBER, p_new_name VARCHAR2) IS
    BEGIN
        UPDATE regions SET region_name = p_new_name WHERE region_id = p_region_id;
    END;

    PROCEDURE delete_region(p_region_id NUMBER) IS
    BEGIN
        DELETE FROM regions WHERE region_id = p_region_id;
    END;

END regions_package;
