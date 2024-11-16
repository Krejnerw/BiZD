--I.	Usuñ wszystkie tabele ze swojej bazy
BEGIN
   FOR rec IN (SELECT owner, table_name FROM all_tables WHERE owner = 'KREJNERW')
   LOOP
      dbms_output.put_line('Tabela: ' || rec.table_name);
      EXECUTE IMMEDIATE 'DROP TABLE ' || rec.owner || '.' || rec.table_name || ' CASCADE CONSTRAINTS';
   END LOOP;
END;
/
--II.	Przekopiuj wszystkie tabele wraz z danymi od u¿ytkownika HR. Poustawiaj klucze g³ówne i obce
BEGIN
   FOR rec IN (SELECT table_name FROM all_tables WHERE owner = 'HR')
   LOOP
      EXECUTE IMMEDIATE 'CREATE TABLE ' || rec.table_name || ' AS SELECT * FROM HR.' || rec.table_name;
--      EXECUTE IMMEDIATE 'ALTER TABLE '|| rec.table_name ||'ADD CONSTRAINT pk_'||rec.table_name||'_id PRIMARY KEY ('||rec.table_name||_ID');
   END LOOP;
END;

ALTER TABLE REGIONS
ADD CONSTRAINT region_id_pk PRIMARY KEY (region_id);

ALTER TABLE COUNTRIES
ADD CONSTRAINT country_id_pk PRIMARY KEY (country_id);

ALTER TABLE COUNTRIES
ADD CONSTRAINT fk_COUNTRIES_region_id
  FOREIGN KEY (region_id)
  REFERENCES REGIONS(region_id);
  
ALTER TABLE LOCATIONS
ADD CONSTRAINT location_id_pk PRIMARY KEY (location_id);

ALTER TABLE LOCATIONS
ADD CONSTRAINT fk_LOCATIONS_country_id
  FOREIGN KEY (country_id)
  REFERENCES COUNTRIES(country_id);

ALTER TABLE JOBS
ADD CONSTRAINT job_id_pk PRIMARY KEY (job_id);

ALTER TABLE DEPARTMENTS
ADD CONSTRAINT department_id_pk PRIMARY KEY (department_id);

ALTER TABLE DEPARTMENTS
ADD CONSTRAINT fk_DEPARTMENTS_location_id
  FOREIGN KEY (location_id)
  REFERENCES LOCATIONS(location_id);
  
ALTER TABLE EMPLOYEES
ADD CONSTRAINT employee_id_pk PRIMARY KEY (employee_id);

ALTER TABLE EMPLOYEES
ADD CONSTRAINT fk_EMPLOYEES_manager_id
  FOREIGN KEY (manager_id)
  REFERENCES EMPLOYEES(employee_id);
  
ALTER TABLE EMPLOYEES
ADD CONSTRAINT fk_EMPLOYEES_department_id
  FOREIGN KEY (department_id)
  REFERENCES DEPARTMENTS(department_id);
  
ALTER TABLE EMPLOYEES
ADD CONSTRAINT fk_EMPLOYEES_job_id
  FOREIGN KEY (job_id)
  REFERENCES JOBS(job_id);
  
ALTER TABLE DEPARTMENTS
ADD CONSTRAINT fk_DEPARTMENTS_manager_id
  FOREIGN KEY (manager_id)
  REFERENCES EMPLOYEES(employee_id);
--DONE DEPARTMENTSadd fk manager_id

ALTER TABLE JOB_HISTORY
ADD CONSTRAINT job_history_id_pk PRIMARY KEY (employee_id,start_date);

ALTER TABLE JOB_HISTORY
ADD CONSTRAINT fk_JOB_HISTORY_job_id
  FOREIGN KEY (job_id)
  REFERENCES JOBS(job_id);
  
ALTER TABLE JOB_HISTORY
ADD CONSTRAINT fk_JOB_HISTORY_department_id
  FOREIGN KEY (department_id)
  REFERENCES DEPARTMENTS(department_id);
  
ALTER TABLE PRODUCTS
ADD CONSTRAINT product_id_pk PRIMARY KEY (product_id);

ALTER TABLE SALES
ADD CONSTRAINT sale_id_pk PRIMARY KEY (sale_id);

ALTER TABLE SALES
ADD CONSTRAINT fk_SALES_product_id
  FOREIGN KEY (product_id)
  REFERENCES PRODUCTS(product_id);
  
ALTER TABLE SALES
ADD CONSTRAINT fk_SALES_employee_id
  FOREIGN KEY (employee_id)
  REFERENCES EMPLOYEES(employee_id);
  
ALTER TABLE JOB_GRADES
ADD CONSTRAINT grade_pk PRIMARY KEY (grade);
/
--III.	Stwórz nastêpuj¹ce perspektywy lub zapytania, dodaj wszystko do swojego repozytorium:
--1.	Z tabeli employees wypisz w jednej kolumnie nazwisko i zarobki – nazwij kolumnê wynagrodzenie, dla osób z departamentów 20 i 50 z zarobkami pomiêdzy 2000 a 7000, uporz¹dkuj kolumny wed³ug nazwiska
SELECT last_name || ' ' || salary AS wynagrodzenie
FROM employees
WHERE department_id IN (20, 50)
  AND salary BETWEEN 2000 AND 7000
ORDER BY last_name;

--2.	Z tabeli employees wyci¹gn¹æ informacjê data zatrudnienia, nazwisko oraz kolumnê podan¹ przez u¿ytkownika dla osób maj¹cych menad¿era zatrudnionych w roku 2005. Uporz¹dkowaæ wed³ug kolumny podanej przez u¿ytkownika
SELECT hire_date, last_name, &user_col as user_col
FROM employees
WHERE manager_id IS NOT NULL
  AND EXTRACT(YEAR FROM hire_date) = 2005
ORDER BY user_col;

--3.	Wypisaæ imiona i nazwiska  razem, zarobki oraz numer telefonu porz¹dkuj¹c dane wed³ug pierwszej kolumny malej¹co  a nastêpnie drugiej rosn¹co (u¿yæ numerów do porz¹dkowania) dla osób z trzeci¹ liter¹ nazwiska ‘e’ oraz czêœci¹ imienia podan¹ przez u¿ytkownika
SELECT first_name || ' ' || last_name, salary, phone_number 
FROM employees
WHERE SUBSTR(last_name, 3, 1) = 'e'
    AND first_name LIKE '%' || '&name_part' || '%'
ORDER BY 1 DESC, 2 ASC;

--4.	Wypisaæ imiê i nazwisko, liczbê miesiêcy przepracowanych – funkcje months_between oraz round oraz kolumnê wysokoœæ_dodatku jako (u¿yæ CASE lub DECODE):
-- 10% wynagrodzenia dla liczby miesiêcy do 150
--20% wynagrodzenia dla liczby miesiêcy od 150 do 200
--30% wynagrodzenia dla liczby miesiêcy od 200
--uporz¹dkowaæ wed³ug liczby miesiêcy
SELECT first_name || ' ' || last_name AS ful_name,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) AS worked_months,
       CASE 
           WHEN ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) < 150 THEN salary * 0.1
           WHEN ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) BETWEEN 150 AND 200 THEN salary * 0.2
           ELSE salary * 0.3
       END AS premia
FROM employees
ORDER BY worked_months;

--5.	Dla ka¿dego z dzia³ów w których minimalna p³aca jest wy¿sza ni¿ 5000 
--wypisz sumê oraz œredni¹ zarobków zaokr¹glon¹ do ca³oœci nazwij odpowiednio kolumny   
SELECT department_id,
       ROUND(SUM(salary)) AS salary_sum,
       ROUND(AVG(salary)) AS salary_mean
FROM employees
GROUP BY department_id
HAVING MIN(salary) > 5000;

--6.	Wypisaæ nazwisko, numer departamentu, nazwê departamentu, id pracy, dla osób z pracuj¹cych Toronto
SELECT e.last_name, e.department_id, d.department_name, e.job_id
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN locations l ON d.location_id = l.location_id
WHERE l.city = 'Toronto';

--7.	Dla pracowników o imieniu „Jennifer” wypisz imiê i nazwisko tego pracownika oraz osoby które z nim wspó³pracuj¹
SELECT e.first_name || ' ' || e.last_name AS worker,
       e2.first_name || ' ' || e2.last_name AS coworker
FROM employees e
JOIN employees e2 ON e.department_id = e2.department_id AND e.employee_id != e2.employee_id
WHERE e.first_name = 'Jennifer';

--8.	Wypisaæ wszystkie departamenty w których nie ma pracowników
SELECT d.department_id, d.department_name
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
WHERE e.department_id IS NULL;

--9.	Skopiuj tabelê Job_grades od u¿ytkownika HR
--10.	Wypisz imiê i nazwisko, id pracy, nazwê departamentu, zarobki, oraz odpowiedni grade dla ka¿dego pracownika
SELECT e.first_name, e.last_name, e.job_id, d.department_name, e.salary, j.grade
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN job_grades j ON e.salary BETWEEN j.min_salary AND j.max_salary;

--11.	Wypisz imiê nazwisko oraz zarobki dla osób które zarabiaj¹ wiêcej ni¿ œrednia wszystkich, uporz¹dkuj malej¹co wed³ug zarobków
SELECT first_name, last_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;

--12.	Wypisz id imie i nazwisko osób, które pracuj¹ w departamencie z osobami maj¹cymi w nazwisku „u”
SELECT e.employee_id, e.first_name, e.last_name
FROM employees e
WHERE e.department_id IN (
    SELECT DISTINCT e2.department_id
    FROM employees e2
    WHERE e2.last_name LIKE '%u%'
);
