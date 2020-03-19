---------------------------------------------------------------------
-- TK 70-461 - Chapter 01 - Querying Foundations
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Using T-SQL in a Relational Way
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using T-SQL in a Relational Way
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1: Identify Nonrelational Elements in a Query
---------------------------------------------------------------------

-- 2.

USE TSQL2012;

SELECT custid, YEAR(orderdate)
FROM Sales.Orders
ORDER BY 1, 2;

---------------------------------------------------------------------
-- Exercise 2: Make the Nonrelational Query Relational
---------------------------------------------------------------------

-- 1.

SELECT DISTINCT custid, YEAR(orderdate) AS orderyear
FROM Sales.Orders;

---------------------------------------------------------------------
-- Lesson 02 - Logical Query Processing
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Logical Query Processing
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1: Fix Problem with Grouping
---------------------------------------------------------------------

-- 2.

-- fails
SELECT custid, orderid
FROM Sales.Orders
GROUP BY custid;

-- 3.

SELECT custid, MAX(orderid) AS maxorderid
FROM Sales.Orders
GROUP BY custid;

---------------------------------------------------------------------
-- Exercise 2: Fix Problem with Aliasing
---------------------------------------------------------------------

-- 1.
SELECT Orders.shipperid,
       SUM(Orders.freight) AS totalfreight
FROM Sales.Orders
WHERE Orders.freight > 20000.00
GROUP BY Orders.shipperid;

-- 2.

-- fails
SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
GROUP BY shipperid
HAVING totalfreight > 20000.00;

-- 3.

SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
GROUP BY shipperid
HAVING SUM(freight) > 20000.00;
