----------------------------------------------------------------------
-- TK 70-461 - Chapter 17 - Understanding Further Optimization Aspects
-- Exercises
----------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Understanding Plan Iterators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Determining Execution Plan Iterators
---------------------------------------------------------------------

-- 3.
USE TSQL2012;
GO

-- 4.
SELECT C.custid, C.companyname, C.address, C.city,
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid;

-- 8.
SELECT C.custid, C.companyname, C.address, C.city,
 O.orderid
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid;

-- 10.
SELECT C.custid, C.companyname, C.address, C.city,
 O.orderid, O.orderdate
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid
WHERE C.city = N'Berlin';

-- 12.
SELECT C.city, MIN(O.orderid) AS minorderid
FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
  ON C.custid = O.custid
GROUP BY C.city;
GO

---------------------------------------------------------------------
-- Lesson 02 - Using Parameterized Queries and Batch Operations
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Query Parameterization and Stored Procedures
---------------------------------------------------------------------

-- 3.
USE TSQL2012;

-- 4.
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = 13;

-- 6.
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = 71;
GO

-- 8.
CREATE PROCEDURE Sales.GetCustomerOrders
(@custid INT)
AS
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = @custid;
GO

-- 9.
DBCC FREEPROCCACHE;
GO

-- 10.
EXEC Sales.GetCustomerOrders @custid = 13;
EXEC Sales.GetCustomerOrders @custid = 71;
GO

-- 12.
ALTER PROCEDURE Sales.GetCustomerOrders
(@custid INT)
WITH RECOMPILE
AS
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = @custid;
GO

-- 13.
EXEC Sales.GetCustomerOrders @custid = 13;
EXEC Sales.GetCustomerOrders @custid = 71;
GO

-- 15.
DROP PROCEDURE Sales.GetCustomerOrders;
GO


---------------------------------------------------------------------
-- Lesson 03 - Using Optimizer Hints and Plan Guides
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Optimizer Hints
---------------------------------------------------------------------

-- 3.
USE TSQL2012;
GO

-- 4.
CREATE PROCEDURE Sales.GetCustomerOrders
(@custid INT)
AS
SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = @custid
OPTION (RECOMPILE);
GO

-- 5.
EXEC Sales.GetCustomerOrders @custid = 13;
EXEC Sales.GetCustomerOrders @custid = 71;
GO

-- 7.
DROP PROCEDURE Sales.GetCustomerOrders;
GO

