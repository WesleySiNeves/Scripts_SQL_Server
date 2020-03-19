---------------------------------------------------------------------
-- TK 70-461 - Chapter 01 - Querying Foundations
-- Code
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Understanding the Foundations of T-SQL
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Using T-SQL in a Relational Way
---------------------------------------------------------------------

USE TSQL2012;

SELECT country
FROM HR.Employees;

SELECT DISTINCT country
FROM HR.Employees;

SELECT empid, lastname
FROM HR.Employees;

SELECT empid, lastname
FROM HR.Employees
ORDER BY empid;

SELECT empid, lastname
FROM HR.Employees
ORDER BY 1;

SELECT empid, firstname + ' ' + lastname
FROM HR.Employees;

SELECT empid, firstname + ' ' + lastname AS fullname
FROM HR.Employees;

---------------------------------------------------------------------
-- Lesson 02 - Logical Query Processing
---------------------------------------------------------------------

---------------------------------------------------------------------
-- T-SQL as a Declarative English-Like Language
---------------------------------------------------------------------

SELECT shipperid, phone, companyname
FROM Sales.Shippers;

---------------------------------------------------------------------
-- Logical Query Processing Phases
---------------------------------------------------------------------
SELECT Employees.country,
       YEAR(Employees.hiredate) AS yearhired,
       COUNT(*) AS numemployees
FROM HR.Employees
WHERE Employees.hiredate >= '20030101'
GROUP BY Employees.country,
         YEAR(Employees.hiredate)
HAVING COUNT(*) > 1
ORDER BY Employees.country,
         yearhired DESC;

-- fails
SELECT country, YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE yearhired >= 2003;

-- fails
SELECT empid, country, YEAR(hiredate) AS yearhired, yearhired - 1 AS prevyear
FROM HR.Employees;
