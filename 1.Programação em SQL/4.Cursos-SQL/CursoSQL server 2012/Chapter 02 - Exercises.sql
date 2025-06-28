---------------------------------------------------------------------
-- TK 70-461 - Chapter 02 - Getting Started with the SELECT Statement
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Using the FROM and SELECT Clauses
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using the FROM and SELECT Clauses
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1: Writing a Simple Query and Using Table Aliases
---------------------------------------------------------------------

-- 2.

USE TSQL2012;

SELECT shipperid, companyname, phone
FROM Sales.Shippers;

-- 3.

SELECT S.shipperid, companyname, phone
FROM Sales.Shippers AS S;

---------------------------------------------------------------------
-- Exercise 2: Using Column Aliases and Delimited Identifiers
---------------------------------------------------------------------


-- 1.

SELECT S.shipperid, companyname, phone AS phone number
FROM Sales.Shippers AS S;

-- 2.

SELECT S.shipperid, companyname, phone AS [phone number]
FROM Sales.Shippers AS S;

---------------------------------------------------------------------
-- Lesson 02 - Working with Data Types and Built-In Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Working with Data Types and Built-in Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1: Apply String Concatenation and Use a Date and Time Function
---------------------------------------------------------------------

-- 2.

SELECT empid, 
  firstname + N' ' + lastname AS fullname, 
  YEAR(birthdate) AS birthyear
FROM HR.Employees;

---------------------------------------------------------------------
-- Exercise 2: Use Additional Date and Time Functions
---------------------------------------------------------------------

-- 1.

-- end of current month
SELECT EOMONTH(SYSDATETIME()) AS end_of_current_month;
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), 12, 31) AS end_of_current_year;

---------------------------------------------------------------------
-- Exercise 3: Use String and Conversion Functions
---------------------------------------------------------------------

-- 1.

-- using string functions
SELECT productid, 
  RIGHT(REPLICATE('0', 10) + CAST(productid AS VARCHAR(10)), 10) AS str_productid
FROM Production.Products;

-- 2.

-- using FORMAT
SELECT productid, 
  FORMAT(productid, 'd10') AS str_productid
FROM Production.Products;
