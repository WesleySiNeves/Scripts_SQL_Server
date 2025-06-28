---------------------------------------------------------------------
-- TK 70-461 - Chapter 04 - Combining Sets
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Using Joins
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Joins
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Match Customers and Orders with Inner Joins
---------------------------------------------------------------------

-- 2.
-- customers and their orders
USE TSQL2012;

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid;

---------------------------------------------------------------------
-- Exercise 2 - Match Customers and Orders with Outer Joins
---------------------------------------------------------------------

-- 1.
-- customers and their orders, including customers without orders
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid;

-- 2.
-- customers without orders
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.orderid IS NULL;

-- 3.
-- all customers; orders from February 2008
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
   AND O.orderdate >= '20080201'
   AND O.orderdate < '20080301';

---------------------------------------------------------------------
-- Lesson 02 - Using Subqueries, Table Expressions and the APPLY Operator
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Subqueries, Table Expressions and the APPLY Operator
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Products with Minimum Unit Price per Category
---------------------------------------------------------------------

-- 2.
-- query returning minimum unit price per category
SELECT categoryid, MIN(unitprice) AS mn
FROM Production.Products
GROUP BY categoryid;

-- 3.
-- join to return products with minimum unit price per category
WITH CatMin AS
(
  SELECT categoryid, MIN(unitprice) AS mn
  FROM Production.Products
  GROUP BY categoryid
)
SELECT P.categoryid, P.productid, P.productname, P.unitprice
FROM Production.Products AS P
  INNER JOIN CatMin AS M
    ON P.categoryid = M.categoryid
    AND P.unitprice = M.mn;

---------------------------------------------------------------------
-- Exercise 2 - N Products with Lowest Unit Price per Supplier
---------------------------------------------------------------------

-- 1.
-- inline function returning the @n products with the lowest unit prices for supplier @supplierid
IF OBJECT_ID(N'Production.GetTopProducts', N'IF') IS NOT NULL DROP FUNCTION Production.GetTopProducts;
GO
CREATE FUNCTION Production.GetTopProducts(@supplierid AS INT, @n AS BIGINT) RETURNS TABLE
AS

RETURN
  SELECT productid, productname, unitprice
  FROM Production.Products
  WHERE supplierid = @supplierid
  ORDER BY unitprice, productid
  OFFSET 0 ROWS FETCH FIRST @n ROWS ONLY;
GO

-- 2.
-- test function
SELECT * FROM Production.GetTopProducts(1, 2) AS P;

-- 3.
-- CROSS APPLY
-- two products with lowest unit prices for each supplier from Japan
-- exclude suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  CROSS APPLY Production.GetTopProducts(S.supplierid, 2) AS A
WHERE S.country = N'Japan';

-- 4.
-- OUTER APPLY
-- two products with lowest unit prices for each supplier from Japan
-- include suppliers without products
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  OUTER APPLY Production.GetTopProducts(S.supplierid, 2) AS A
WHERE S.country = N'Japan';

-- 5.
-- cleanup
IF OBJECT_ID(N'Production.GetTopProducts', N'IF') IS NOT NULL DROP FUNCTION Production.GetTopProducts;

---------------------------------------------------------------------
-- Lesson 03 - Using Set Operators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Set Operators
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Using the EXCEPT Set Operator
---------------------------------------------------------------------

-- 2.
-- return employees who handled orders for customer 1 but not customer 2
SELECT empid
FROM Sales.Orders
WHERE custid = 1

EXCEPT

SELECT empid
FROM Sales.Orders
WHERE custid = 2;

---------------------------------------------------------------------
-- Exercise 2 - Using the INTERSECT Set Operator
---------------------------------------------------------------------

-- 1.
-- return employees who handled orders for both customer 1 and customer 2
SELECT empid
FROM Sales.Orders
WHERE custid = 1

INTERSECT

SELECT empid
FROM Sales.Orders
WHERE custid = 2;
