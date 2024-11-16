--1.   Stworzy� blok anonimowy wypisuj�cy zmienn� numer_max r�wn� maksymalnemu 
--numerowi Departamentu i dodaj do tabeli departamenty � departament z numerem o 10 
--wiekszym, typ pola dla zmiennej z nazw� nowego departamentu (zainicjowa� na EDUCATION) 
--ustawi� taki jak dla pola department_name w tabeli (%TYPE)

--2.   Do poprzedniego skryptu dodaj instrukcje zmieniaj�c� location_id (3000) 
--dla dodanego departamentu  
DECLARE
    numer_max departments.department_id%TYPE;
    nowa_nazwa departments.department_name%TYPE := 'EDUCATION';
    
BEGIN
    SELECT MAX(department_id) INTO numer_max FROM departments;

    DBMS_OUTPUT.PUT_LINE('Maksymalny numer departamentu: ' || numer_max);

    -- Dodanie nowego departamentu o numerze wi�kszym o 10
    INSERT INTO departments (department_id, department_name)
    VALUES (numer_max + 10, nowa_nazwa);

    -- Zaktualizowanie location_id dla nowego departamentu
    UPDATE departments
    SET location_id = 3000
    WHERE department_id = numer_max + 10;
    
    DBMS_OUTPUT.PUT_LINE('Dodano nowy departament o numerze: ' || (numer_max + 10) || ' i nazwie: ' || nowa_nazwa);
--    COMMIT;
END;

--3.   Stw�rz tabel� nowa z jednym polem typu varchar a nast�pnie wpisz do niej za 
--pomoc� p�tli liczby od 1 do 10 bez liczb 4 i 6
CREATE TABLE nowa (
    liczba VARCHAR2(10)
);

BEGIN
    FOR i IN 1..10 LOOP
        -- Pomini�cie liczb 4 i 6
        IF i = 4 OR i = 6 THEN
            CONTINUE;
        END IF;

        -- Wstawienie liczby jako tekst do tabeli 'nowa'
        INSERT INTO nowa (liczba) VALUES (TO_CHAR(i));
    END LOOP;
    COMMIT;
END;

--4.   Wyci�gn�� informacje z tabeli countries do jednej zmiennej (%ROWTYPE) 
--dla kraju o identyfikatorze �CA�. Wypisa� nazw� i region_id na ekran
DECLARE
    -- Zmienna rekordowa, kt�ra przechowa ca�y wiersz z tabeli countries dla kraju 'CA'
    country_record countries%ROWTYPE;
BEGIN
    SELECT * INTO country_record
    FROM countries
    WHERE country_id = 'CA';

    -- Wy�wietlenie nazwy kraju i region_id
    DBMS_OUTPUT.PUT_LINE('Country Name: ' || country_record.country_name);
    DBMS_OUTPUT.PUT_LINE('Region ID: ' || country_record.region_id);
END;

--5.   Zadeklaruj kursor jako wynagrodzenie, nazwisko dla departamentu o numerze 50. 
--Dla element�w kursora wypisa� na ekran, je�li wynagrodzenie jest wy�sze ni� 3100: 
--nazwisko osoby i tekst �nie dawa� podwy�ki� w przeciwnym przypadku: 
--nazwisko + �da� podwy�k�
DECLARE
    -- Deklaracja kursora wybieraj�cego wynagrodzenie i nazwisko pracownik�w z departamentu 50
    CURSOR cur_wynagrodzenie IS
        SELECT salary, last_name
        FROM employees
        WHERE department_id = 50;

    -- Zmienna rekordowa do przechowywania bie��cego rekordu z kursora
    employee_record cur_wynagrodzenie%ROWTYPE;
BEGIN
    -- Otwarcie kursora
    OPEN cur_wynagrodzenie;
    --petla kursorowa    
    LOOP
        -- Pobranie kolejnego rekordu
        FETCH cur_wynagrodzenie INTO employee_record;
        
        -- Wyj�cie z p�tli, je�li nie ma wi�cej rekord�w
        EXIT WHEN cur_wynagrodzenie%NOTFOUND;

        -- Sprawdzenie wynagrodzenia i wypisanie odpowiedniego komunikatu
        IF employee_record.salary > 3100 THEN
            DBMS_OUTPUT.PUT_LINE(employee_record.last_name || ': nie dawa� podwy�ki');
        ELSE
            DBMS_OUTPUT.PUT_LINE(employee_record.last_name || ': da� podwy�k�');
        END IF;
    END LOOP;

    -- Zamkni�cie kursora po zako�czeniu przetwarzania
    CLOSE cur_wynagrodzenie;
END;

--6.   Zadeklarowa� kursor zwracaj�cy zarobki imi� i nazwisko pracownika z parametrami, 
--gdzie pierwsze dwa parametry okre�laj� wide�ki zarobk�w a trzeci cz�� imienia pracownika. 
--Wypisa� na ekran pracownik�w:
--a.   	z wide�kami 1000- 5000 z cz�ci� imienia a (mo�e by� r�wnie� A)
--b.   	z wide�kami 5000-20000 z cz�ci� imienia u (mo�e by� r�wnie� U)
DECLARE
    -- Deklaracja kursora z trzema parametrami
    CURSOR cur_pracownicy(min_salary NUMBER, max_salary NUMBER, name_part VARCHAR2) IS
        SELECT salary, first_name, last_name
        FROM employees
        WHERE salary BETWEEN min_salary AND max_salary
          AND LOWER(first_name) LIKE '%' || LOWER(name_part) || '%';

    -- Zmienna rekordowa do przechowywania wynik�w kursora
    employee_record cur_pracownicy%ROWTYPE;
BEGIN
    -- a) Wypisanie pracownik�w z wide�kami 1000-5000 i cz�ci� imienia 'a' lub 'A'
    DBMS_OUTPUT.PUT_LINE('Pracownicy z wide�kami 1000-5000 i cz�ci� imienia "a":');
    OPEN cur_pracownicy(1000, 5000, 'a');
    LOOP
        FETCH cur_pracownicy INTO employee_record;
        EXIT WHEN cur_pracownicy%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(employee_record.first_name || ' ' || employee_record.last_name || ', Zarobki: ' || employee_record.salary);
    END LOOP;
    CLOSE cur_pracownicy;

    -- b) Wypisanie pracownik�w z wide�kami 5000-20000 i cz�ci� imienia 'u' lub 'U'
    DBMS_OUTPUT.PUT_LINE('Pracownicy z wide�kami 5000-20000 i cz�ci� imienia "u":');
    OPEN cur_pracownicy(5000, 20000, 'u');
    LOOP
        FETCH cur_pracownicy INTO employee_record;
        EXIT WHEN cur_pracownicy%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(employee_record.first_name || ' ' || employee_record.last_name || ', Zarobki: ' || employee_record.salary);
    END LOOP;
    CLOSE cur_pracownicy;
END;

--9.    Stw�rz procedury:
--a.   dodaj�c� wiersz do tabeli Jobs � z dwoma parametrami wej�ciowymi 
--okre�laj�cymi Job_id, Job_title, przetestuj dzia�anie wrzu� wyj�tki 
--� co najmniej when others
CREATE OR REPLACE PROCEDURE add_job(p_job_id VARCHAR2, p_job_title VARCHAR2) AS
BEGIN
    INSERT INTO jobs (job_id, job_title)
    VALUES (p_job_id, p_job_title);

    DBMS_OUTPUT.PUT_LINE('Job added: ' || p_job_id || ', ' || p_job_title);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
--Test procedury
BEGIN
    add_job('DEV', 'Developer');
END;
BEGIN
    add_job('DEV2');
END;
--b.   modyfikuj�c� title w  tabeli Jobs � z dwoma parametrami id dla kt�rego 
--ma by� modyfikacja oraz now� warto�� dla Job_title � przetestowa� dzia�anie, 
--doda� sw�j wyj�tek dla no Jobs updated � najpierw sprawdzi� numer b��du
CREATE OR REPLACE PROCEDURE update_job_title(p_job_id VARCHAR2, p_new_job_title VARCHAR2) AS
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
END;
BEGIN
    update_job_title('DEV', 'Senior Developer');
END;
BEGIN
    update_job_title('DEV2', 'Senior Developer');
END;

--c.   usuwaj�c� wiersz z tabeli Jobs  o podanym Job_id� przetestowa� dzia�anie, 
--dodaj wyj�tek dla no Jobs deleted
CREATE OR REPLACE PROCEDURE delete_job(p_job_id VARCHAR2) AS
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
END;
BEGIN
    delete_job('DEV2');
END;

--d.   Wyci�gaj�c� zarobki i nazwisko (parametry zwracane przez procedur�) 
--z tabeli employees dla pracownika o przekazanym jako parametr id
CREATE OR REPLACE PROCEDURE get_employee_salary_lastname(p_employee_id NUMBER, 
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
END;

DECLARE
    emp_salary NUMBER;
    emp_last_name VARCHAR2(50);
BEGIN
    get_employee_salary_lastname(100, emp_salary, emp_last_name);
END;
DECLARE
    emp_salary NUMBER;
    emp_last_name VARCHAR2(50);
BEGIN
    get_employee_salary_lastname(1, emp_salary, emp_last_name);
END;

--e.   dodaj�c� do tabeli employees wiersz � wi�kszo�� parametr�w ustawi� na 
--domy�lne (id poprzez sekwencj�), stworzy� wyj�tek je�li wynagrodzenie 
--dodawanego pracownika jest wy�sze ni� 20000
CREATE OR REPLACE PROCEDURE add_employee(p_first_name VARCHAR2,
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
END;

BEGIN
    add_employee(
        p_first_name => 'Ann',
        p_last_name => 'Doe',
        p_email => 'adoe@example.com',
        p_phone_number => '123.456.7890',
        p_salary => 15000
    );
END;
BEGIN
    add_employee(
        p_first_name => 'Ben',
        p_last_name => 'Doe',
        p_email => 'bdoe@example.com',
        p_phone_number => '123.456.7890',
        p_salary => 55000
    );
END;
