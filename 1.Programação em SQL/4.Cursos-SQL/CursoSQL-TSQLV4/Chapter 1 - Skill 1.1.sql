---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 1 - Manage Data with Transact-SQL
-- Skill 1.1: Create Transact-SQL SELECT queries
-- © Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice SQL environment and Sample databases
---------------------------------------------------------------------

-- Database server:
-- The code samples in this book can be executed in SQL Server 2016 Service Pack 1 (SP1) or later
-- and Azure SQL Database.
-- If you prefer to work with a local instance, SQL Server Developer
-- Edition is free if you sign up for the free Visual Studio Dev
-- Essentials program: https://myprodscussu1.app.vssubscriptions.visualstudio.com/Downloads?q=SQL%20Server%20Developer
-- In the installation's Feature Selection step, you need to choose only the Database Engine Services feature.

-- SQL Server Management Studio:
-- Download and install SQL Server Management Studio from here: https://msdn.microsoft.com/en-us/library/mt238290.aspx

-- Sample database:
-- This book uses the TSQLV4 sample database.
-- It is supported in both SQL Server 2016 and Azure SQL Database.
-- Download and install TSQLV4 from here: http://tsql.solidq.com/SampleDatabases/TSQLV4.zip

---------------------------------------------------------------------
-- Further reading
---------------------------------------------------------------------

-- If you are looking for further reading for more practice and 
-- more advanced topics beyond this book, see:
-- TSQL Fundamentals, 3rd Edition for more practice of fundamentals: https://www.microsoftpressstore.com/store/t-sql-fundamentals-9781509302000
-- T-SQL Querying for more advanced querying and query tuning: https://www.microsoftpressstore.com/store/t-sql-querying-9780735685048?w_ptgrevartcl=T-SQL+Querying_2193978
-- Itzik Ben-Gan's column in SQL Server Pro: http://sqlmag.com/author/itzik-ben-gan

---------------------------------------------------------------------
-- Understanding the Foundations of T-SQL
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Using T-SQL in a Relational Way
---------------------------------------------------------------------

USE TSQLV4;

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

SELECT empid, firstname + ' ' + lastname
FROM HR.Employees


SELECT empid, firstname + ' ' + lastname AS fullname
FROM HR.Employees;

--Veja que tambem podemos retornar Colunas com mesmo nome
select 4 as Id, 2 as Id
union 
select 3 , 4
order by 2

--Exemplo sobre Valores Nulos

SELECT Customers.custid,
       Customers.region,
       valorIgual = CASE
                        WHEN Customers.region = 'BC' THEN
                            'SIM'
                        ELSE
                            'NAO'
                    END
FROM Sales.Customers;

  




---------------------------------------------------------------------
-- Logical Query Processing
---------------------------------------------------------------------

---------------------------------------------------------------------
-- T-SQL as a Declarative English-Like Language
---------------------------------------------------------------------

SELECT shipperid, phone, companyname
FROM Sales.Shippers;

---------------------------------------------------------------------
-- Logical Query Processing Phases
---------------------------------------------------------------------

--1)
SELECT country, YEAR(hiredate) AS yearhired, COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20140101'
GROUP BY country, YEAR(hiredate)
HAVING numemployees > 1
ORDER BY country, yearhired DESC;


--2)
SELECT country, YEAR(hiredate) AS yearhired, COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20140101'
GROUP BY country, YEAR(hiredate)
HAVING COUNT(*) > 1
ORDER BY numemployees


--3)
SELECT country, YEAR(hiredate) AS yearhired, COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20140101'
GROUP BY country, yearhired
HAVING COUNT(*) > 1
ORDER BY numemployees



--4)
SELECT country, YEAR(hiredate) AS yearhired, COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20140101'
GROUP BY country, YEAR(hiredate)
HAVING COUNT(*) > 1
ORDER BY country, yearhired DESC;

-- fails
SELECT country, YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE yearhired >= 2014;

-- fails
SELECT empid, country, YEAR(hiredate) AS yearhired, yearhired - 1 AS prevyear
FROM HR.Employees;

---------------------------------------------------------------------
-- Getting started with the SELECT statement
---------------------------------------------------------------------

---------------------------------------------------------------------
-- The FROM clause
---------------------------------------------------------------------

-- basic example
SELECT H.empid, H.firstname, H.lastname, H.country
FROM HR.Employees H;

-- assigning a table alias
SELECT E.empid, firstname, lastname, country
FROM HR.Employees AS E;


SELECT E.empid, Employees.firstname, lastname, country
FROM HR.Employees AS E
---------------------------------------------------------------------
-- The SELECT clause
---------------------------------------------------------------------

-- projection of a subset of the source attributes
SELECT empid, firstname, lastname
FROM HR.Employees;

-- bug due to missing comma
SELECT empid, firstname lastname
FROM HR.Employees;

-- aliasing for renaming
SELECT empid AS employeeid, firstname, lastname
FROM HR.Employees;

-- expression without an alias
SELECT empid, firstname + N' ' + lastname
FROM HR.Employees;

-- aliasing expressions
SELECT empid, firstname + N' ' + lastname AS fullname
FROM HR.Employees;

-- removing duplicates with DISTINCT
SELECT DISTINCT country, region, city
FROM HR.Employees;

-- SELECT without FROM
SELECT 10 AS col1, 'ABC' AS col2;

---------------------------------------------------------------------
-- Filtering data with predicates
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Predicates and three-valued-logic
---------------------------------------------------------------------


-- content of Employees table
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees;


SELECT country, YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE YEAR(hiredate) >= 2014;



-- employees from the United States
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE country = N'USA';


--Convert Implicts
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE country = 'USA';

-- employees from Washington State
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region = N'WA';

-- employees that are not from Washington State
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA';

-- handling NULLs incorrectly
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA'
   OR region = NULL;


/* ==================================================================
--Data: 30/07/2018 
--Autor :Wesley Neves
--Observação: Executa a comparação de igualdade e mostra a utilidade da 
configuração ANSI_NULLS 
por padrão ela esta ativa no banco ou seja qualquer valor comparado com valor null
e calculado como indefinido
 
-- ==================================================================
*/

--Comparacao com igualdade
SELECT IIF(NULL = NULL, 'Sim', 'Nao');
SET ANSI_NULLS  OFF
SELECT IIF(NULL = NULL, 'Sim', 'Nao');

-- employees that are not from Washington State, resolving the NULL problem
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA'
   OR region IS NULL;

---------------------------------------------------------------------
-- Filtering character data
---------------------------------------------------------------------
use TSQLV4;

-- regular character string
SELECT Employees.empid,
       Employees.firstname,
       Employees.lastname
FROM HR.Employees
WHERE Employees.lastname = 'Davis';

-- Unicode character string
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'Davis';

-- employees whose last name starts with the letter D.
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';

---------------------------------------------------------------------
-- Filtering date and time data
---------------------------------------------------------------------

/*Aqui vemos as diferenças de usar uma comparação de datas 
no primeiro exemplo temos as data  '02/12/16' que nesse formato depende do idioma padrão  do SQL Server
no formato '20160212' é imdependente de linguagem
 */

-- language-dependent literal
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '02/12/16';

-- language-neutral literal
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '20160212';

-- create table Sales.Orders2
/*Só é aceito apartir do SQL server 2016*/
DROP TABLE IF EXISTS Sales.Orders2;

SELECT Orders.orderid,
       CAST(Orders.orderdate AS DATETIME) AS orderdate,
       Orders.empid,
       Orders.custid
INTO Sales.Orders2
FROM Sales.Orders;

-- filtering a range, the unrecommended way
--Essa pratica não é recomendada 
SELECT Orders2.orderid,
       Orders2.orderdate,
       Orders2.empid,
       Orders2.custid
FROM Sales.Orders2
WHERE Orders2.orderdate
BETWEEN '20160401' AND '20160430 23:59:59.999'
ORDER BY Orders2.orderdate DESC;


-- filtering a range, the recommended way
SELECT Orders2.orderid,
       Orders2.orderdate,
       Orders2.empid,
       Orders2.custid
FROM Sales.Orders2
WHERE Orders2.orderdate >= '20160401'
      AND Orders2.orderdate < '20160501';

---------------------------------------------------------------------
-- Sorting data
---------------------------------------------------------------------

-- query with no ORDER BY doesn't guarantee presentation ordering
SELECT Employees.empid,
       Employees.firstname,
       Employees.lastname,
       Employees.city,
       MONTH(Employees.birthdate) AS birthmonth
FROM HR.Employees
WHERE Employees.country = N'USA'
      AND Employees.region = N'WA';

-- simple ORDER BY example
SELECT Employees.empid,
       Employees.firstname,
       Employees.lastname,
       Employees.city,
       MONTH(Employees.birthdate) AS birthmonth
FROM HR.Employees
WHERE Employees.country = N'USA'
      AND Employees.region = N'WA'
ORDER BY Employees.city;

-- use descending order
SELECT Employees.empid,
       Employees.firstname,
       Employees.lastname,
       Employees.city,
       MONTH(Employees.birthdate) AS birthmonth
FROM HR.Employees
WHERE Employees.country = N'USA'
      AND Employees.region = N'WA'
ORDER BY Employees.city DESC;

-- order by multiple columns
SELECT Employees.empid,
       Employees.firstname,
       Employees.lastname,
       Employees.city,
       MONTH(Employees.birthdate) AS birthmonth
FROM HR.Employees
WHERE Employees.country = N'USA'
      AND Employees.region = N'WA'
ORDER BY Employees.city,
         Employees.empid;


-- order by ordinals (bad practice)
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;

-- change SELECT list but forget to change ordinals in ORDER BY
SELECT empid, city, firstname, lastname, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;

-- order by elements not in SELECT
SELECT Employees.empid,
       Employees.city
FROM HR.Employees
WHERE Employees.country = N'USA'
      AND Employees.region = N'WA'
ORDER BY Employees.birthdate;

-- when DISTINCT specified, can only order by elements in SELECT

-- following fails
SELECT DISTINCT
    Employees.city
FROM HR.Employees
WHERE Employees.country = N'USA'
      AND Employees.region = N'WA'
ORDER BY Employees.birthdate;

-- following succeeds
SELECT DISTINCT city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city;


/*Vc pode fazer referencia a um Alias na fase do Order BY*/
SELECT Employees.empid,
       Employees.firstname,
       Employees.lastname,
       Employees.city,
       MONTH(Employees.birthdate) AS birthmonth
FROM HR.Employees
WHERE Employees.country = N'USA'
      AND Employees.region = N'WA'
ORDER BY birthmonth;

/*Valores NULLS são retornados Primeiros*/
SELECT Orders.orderid,
       Orders.shippeddate
FROM Sales.Orders
WHERE Orders.custid = 20
ORDER BY Orders.shippeddate;



SELECT OrderDetails.productid
FROM Sales.OrderDetails
ORDER BY OrderDetails.orderid;


select * from  [Sales].[OrderDetails]
order by orderid

--1)Usando o group By , e entendendo a diferença do Sum e do Count
SELECT OrderDetails.orderid,
       COUNT(OrderDetails.productid),
       SUM(OrderDetails.unitprice) AS Total,
       SUM(OrderDetails.qty) QuantidadeVendida,
       COUNT(OrderDetails.qty)
FROM Sales.OrderDetails
GROUP BY OrderDetails.orderid;
---------------------------------------------------------------------
-- Filtering data with TOP and OFFSET-FETCH
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Filtering Data with TOP
---------------------------------------------------------------------

-- return the three most recent orders
SELECT TOP (3)
    Orders.orderid,
    Orders.orderdate,
    Orders.custid,
    Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC;

-- can use percent
SELECT TOP (1) PERCENT
    Orders.orderid,
    Orders.orderdate,
    Orders.custid,
    Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC;
GO

-- can use expression, like parameter or variable, as input
DECLARE @n AS BIGINT = 5;

SELECT TOP (@n)
    Orders.orderid,
    Orders.orderdate,
    Orders.custid,
    Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC;
GO



-- no ORDER BY, ordering is arbitrary
SELECT TOP (3)
    Orders.orderid,
    Orders.orderdate,
    Orders.custid,
    Orders.empid
FROM Sales.Orders;


-- be explicit about arbitrary ordering
SELECT TOP (3)
    Orders.orderid,
    Orders.orderdate,
    Orders.custid,
    Orders.empid
FROM Sales.Orders
ORDER BY
    (
        SELECT NULL
    );

-- non-deterministic ordering even with ORDER BY since ordering isn't unique
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;

-- return all ties
SELECT TOP (3) WITH TIES
    Orders.orderid,
    Orders.orderdate,
    Orders.custid,
    Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC;

-- break ties
SELECT TOP (3)
    Orders.orderid,
    Orders.orderdate,
    Orders.custid,
    Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC,
         Orders.orderid DESC;

---------------------------------------------------------------------
-- Filtering Data with OFFSET-FETCH
---------------------------------------------------------------------

/*FETCH NEXT inicia no Sql server 2008*/
-- skip 50 rows, fetch next 25 rows
SELECT Orders.orderid,
       Orders.orderdate,
       Orders.custid,
       Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC,
         Orders.orderid DESC OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;

-- fetch first 25 rows
SELECT Orders.orderid,
       Orders.orderdate,
       Orders.custid,
       Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC,
         Orders.orderid DESC OFFSET 0 ROWS FETCH FIRST 25 ROWS ONLY;


-- skip 50 rows, return all the rest
SELECT Orders.orderid,
       Orders.orderdate,
       Orders.custid,
       Orders.empid
FROM Sales.Orders
ORDER BY Orders.orderdate DESC,
         Orders.orderid DESC OFFSET 50 ROWS;

-- ORDER BY is mandatory; return some 3 rows
SELECT Orders.orderid,
       Orders.orderdate,
       Orders.custid,
       Orders.empid
FROM Sales.Orders
ORDER BY
    (
        SELECT NULL
    ) OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY;
GO

-- can use expressions as input
DECLARE @pagesize AS BIGINT = 25, @pagenum AS BIGINT = 3;

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;
GO

-- For more on TOP and OFFSET-FETCH, including optimization, see
-- T-SQL Querying book's sample chapter: Chapter 5 - TOP and OFFSET-FETCH
-- You can find the online version of this chapter here: https://www.microsoftpressstore.com/articles/article.aspx?p=2314819
-- You can download the PDF version of this chapter here: https://ptgmedia.pearsoncmg.com/images/9780735685048/samplepages/9780735685048.pdf
-- This chapter uses the sample database TSQLV3 which you can download here: http://tsql.solidq.com/SampleDatabases/TSQLV3.zip





---------------------------------------------------------------------
-- Combining sets with set operators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- UNION and UNION ALL
---------------------------------------------------------------------

-- locations that are employee locations or customer locations or both
SELECT Employees.country,
       Employees.region,
       Employees.city
FROM HR.Employees
UNION
SELECT Customers.country,
       Customers.region,
       Customers.city
FROM Sales.Customers;

-- with UNION ALL duplicates are not discarded
SELECT Employees.country,
       Employees.region,
       Employees.city
FROM HR.Employees
UNION ALL
SELECT Customers.country,
       Customers.region,
       Customers.city
FROM Sales.Customers;

---------------------------------------------------------------------
-- INTERSECT
---------------------------------------------------------------------

-- locations that are both employee and customer locations
SELECT Employees.country,
       Employees.region,
       Employees.city
FROM HR.Employees
INTERSECT
SELECT Customers.country,
       Customers.region,
       Customers.city
FROM Sales.Customers;

---------------------------------------------------------------------
-- EXCEPT
---------------------------------------------------------------------

-- locations that are employee locations but not customer locations
SELECT Employees.country,
       Employees.region,
       Employees.city
FROM HR.Employees
EXCEPT
SELECT Customers.country,
       Customers.region,
       Customers.city
FROM Sales.Customers;

-- cleanup
DROP TABLE IF EXISTS Sales.Orders2;
