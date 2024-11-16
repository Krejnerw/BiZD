--1.   Stworzyæ blok anonimowy wypisuj¹cy zmienn¹ numer_max równ¹ maksymalnemu 
--numerowi Departamentu i dodaj do tabeli departamenty – departament z numerem o 10 
--wiekszym, typ pola dla zmiennej z nazw¹ nowego departamentu (zainicjowaæ na EDUCATION) 
--ustawiæ taki jak dla pola department_name w tabeli (%TYPE)

--2.   Do poprzedniego skryptu dodaj instrukcje zmieniaj¹c¹ location_id (3000) 
--dla dodanego departamentu  
DECLARE
    numer_max departments.department_id%TYPE;
    nowa_nazwa departments.department_name%TYPE := 'EDUCATION';
    
BEGIN
    SELECT MAX(department_id) INTO numer_max FROM departments;

    DBMS_OUTPUT.PUT_LINE('Maksymalny numer departamentu: ' || numer_max);

    -- Dodanie nowego departamentu o numerze wiêkszym o 10
    INSERT INTO departments (department_id, department_name)
    VALUES (numer_max + 10, nowa_nazwa);

    -- Zaktualizowanie location_id dla nowego departamentu
    UPDATE departments
    SET location_id = 3000
    WHERE department_id = numer_max + 10;
    
    DBMS_OUTPUT.PUT_LINE('Dodano nowy departament o numerze: ' || (numer_max + 10) || ' i nazwie: ' || nowa_nazwa);
--    COMMIT;
END;

--3.   Stwórz tabelê nowa z jednym polem typu varchar a nastêpnie wpisz do niej za 
--pomoc¹ pêtli liczby od 1 do 10 bez liczb 4 i 6
CREATE TABLE nowa (
    liczba VARCHAR2(10)
);

BEGIN
    FOR i IN 1..10 LOOP
        -- Pominiêcie liczb 4 i 6
        IF i = 4 OR i = 6 THEN
            CONTINUE;
        END IF;

        -- Wstawienie liczby jako tekst do tabeli 'nowa'
        INSERT INTO nowa (liczba) VALUES (TO_CHAR(i));
    END LOOP;
    COMMIT;
END;

--4.   Wyci¹gn¹æ informacje z tabeli countries do jednej zmiennej (%ROWTYPE) 
--dla kraju o identyfikatorze ‘CA’. Wypisaæ nazwê i region_id na ekran
DECLARE
    -- Zmienna rekordowa, która przechowa ca³y wiersz z tabeli countries dla kraju 'CA'
    country_record countries%ROWTYPE;
BEGIN
    SELECT * INTO country_record
    FROM countries
    WHERE country_id = 'CA';

    -- Wyœwietlenie nazwy kraju i region_id
    DBMS_OUTPUT.PUT_LINE('Country Name: ' || country_record.country_name);
    DBMS_OUTPUT.PUT_LINE('Region ID: ' || country_record.region_id);
END;

--5.   Zadeklaruj kursor jako wynagrodzenie, nazwisko dla departamentu o numerze 50. 
--Dla elementów kursora wypisaæ na ekran, jeœli wynagrodzenie jest wy¿sze ni¿ 3100: 
--nazwisko osoby i tekst ‘nie dawaæ podwy¿ki’ w przeciwnym przypadku: 
--nazwisko + ‘daæ podwy¿kê’
DECLARE
    -- Deklaracja kursora wybieraj¹cego wynagrodzenie i nazwisko pracowników z departamentu 50
    CURSOR cur_wynagrodzenie IS
        SELECT salary, last_name
        FROM employees
        WHERE department_id = 50;

    -- Zmienna rekordowa do przechowywania bie¿¹cego rekordu z kursora
    employee_record cur_wynagrodzenie%ROWTYPE;
BEGIN
    -- Otwarcie kursora
    OPEN cur_wynagrodzenie;
    --petla kursorowa    
    LOOP
        -- Pobranie kolejnego rekordu
        FETCH cur_wynagrodzenie INTO employee_record;
        
        -- Wyjœcie z pêtli, jeœli nie ma wiêcej rekordów
        EXIT WHEN cur_wynagrodzenie%NOTFOUND;

        -- Sprawdzenie wynagrodzenia i wypisanie odpowiedniego komunikatu
        IF employee_record.salary > 3100 THEN
            DBMS_OUTPUT.PUT_LINE(employee_record.last_name || ': nie dawaæ podwy¿ki');
        ELSE
            DBMS_OUTPUT.PUT_LINE(employee_record.last_name || ': daæ podwy¿kê');
        END IF;
    END LOOP;

    -- Zamkniêcie kursora po zakoñczeniu przetwarzania
    CLOSE cur_wynagrodzenie;
END;

--6.   Zadeklarowaæ kursor zwracaj¹cy zarobki imiê i nazwisko pracownika z parametrami, 
--gdzie pierwsze dwa parametry okreœlaj¹ wide³ki zarobków a trzeci czêœæ imienia pracownika. 
--Wypisaæ na ekran pracowników:
--a.   	z wide³kami 1000- 5000 z czêœci¹ imienia a (mo¿e byæ równie¿ A)
--b.   	z wide³kami 5000-20000 z czêœci¹ imienia u (mo¿e byæ równie¿ U)
DECLARE
    -- Deklaracja kursora z trzema parametrami
    CURSOR cur_pracownicy(min_salary NUMBER, max_salary NUMBER, name_part VARCHAR2) IS
        SELECT salary, first_name, last_name
        FROM employees
        WHERE salary BETWEEN min_salary AND max_salary
          AND LOWER(first_name) LIKE '%' || LOWER(name_part) || '%';

    -- Zmienna rekordowa do przechowywania wyników kursora
    employee_record cur_pracownicy%ROWTYPE;
BEGIN
    -- a) Wypisanie pracowników z wide³kami 1000-5000 i czêœci¹ imienia 'a' lub 'A'
    DBMS_OUTPUT.PUT_LINE('Pracownicy z wide³kami 1000-5000 i czêœci¹ imienia "a":');
    OPEN cur_pracownicy(1000, 5000, 'a');
    LOOP
        FETCH cur_pracownicy INTO employee_record;
        EXIT WHEN cur_pracownicy%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(employee_record.first_name || ' ' || employee_record.last_name || ', Zarobki: ' || employee_record.salary);
    END LOOP;
    CLOSE cur_pracownicy;

    -- b) Wypisanie pracowników z wide³kami 5000-20000 i czêœci¹ imienia 'u' lub 'U'
    DBMS_OUTPUT.PUT_LINE('Pracownicy z wide³kami 5000-20000 i czêœci¹ imienia "u":');
    OPEN cur_pracownicy(5000, 20000, 'u');
    LOOP
        FETCH cur_pracownicy INTO employee_record;
        EXIT WHEN cur_pracownicy%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(employee_record.first_name || ' ' || employee_record.last_name || ', Zarobki: ' || employee_record.salary);
    END LOOP;
    CLOSE cur_pracownicy;
END;

--9.    Stwórz procedury:
--a.   dodaj¹c¹ wiersz do tabeli Jobs – z dwoma parametrami wejœciowymi 
--okreœlaj¹cymi Job_id, Job_title, przetestuj dzia³anie wrzuæ wyj¹tki 
--– co najmniej when others
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
--b.   modyfikuj¹c¹ title w  tabeli Jobs – z dwoma parametrami id dla którego 
--ma byæ modyfikacja oraz now¹ wartoœæ dla Job_title – przetestowaæ dzia³anie, 
--dodaæ swój wyj¹tek dla no Jobs updated – najpierw sprawdziæ numer b³êdu
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

--c.   usuwaj¹c¹ wiersz z tabeli Jobs  o podanym Job_id– przetestowaæ dzia³anie, 
--dodaj wyj¹tek dla no Jobs deleted
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

--d.   Wyci¹gaj¹c¹ zarobki i nazwisko (parametry zwracane przez procedurê) 
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

--e.   dodaj¹c¹ do tabeli employees wiersz – wiêkszoœæ parametrów ustawiæ na 
--domyœlne (id poprzez sekwencjê), stworzyæ wyj¹tek jeœli wynagrodzenie 
--dodawanego pracownika jest wy¿sze ni¿ 20000
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
