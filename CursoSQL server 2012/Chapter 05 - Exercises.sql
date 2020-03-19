---------------------------------------------------------------------
-- TK 70-461 - Chapter 05 - Grouping and Windowing
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Writing Grouped Queries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Writing Grouped Queries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Aggregate Information About Customer Orders
---------------------------------------------------------------------

-- 2.

-- compute number of orders per customer for customers from Spain
USE TSQL2012;

SELECT C.custid, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY C.custid;

-- 3.

-- add city to the SELECT list
SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY C.custid;

-- 4.

-- add city to GROUP BY as well
SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY C.custid, C.city;

---------------------------------------------------------------------
-- Exercise 2 - Define Multiple Grouping Sets
---------------------------------------------------------------------

-- 1.

-- add total of all orders; present detail first
SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE C.country = N'Spain'
GROUP BY GROUPING SETS ( (C.custid, C.city), () )
ORDER BY GROUPING(C.custid);

---------------------------------------------------------------------
-- Lesson 02 - Pivoting and Unpivoting Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Pivoting Data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Pivot Data Using a Table Expression
---------------------------------------------------------------------

-- 2.

-- attempt to return maximum shipping date for each order year and shipper ID
-- with order years on rows and shipper IDs (1, 2 and 3) on columns
SELECT YEAR(orderdate) AS orderyear, [1], [2], [3]
FROM Sales.Orders
  PIVOT( MAX(shippeddate) FOR shipperid IN ([1],[2],[3]) ) AS P;

-- 3.

-- correct the query from step 2 to return only one row per order year
-- by using a table expression

WITH PivotData AS
(
	SELECT YEAR(orderdate) AS orderyear, shipperid, shippeddate
	FROM Sales.Orders
)
SELECT orderyear, [1], [2], [3]
FROM PivotData
  PIVOT( MAX(shippeddate) FOR shipperid IN ([1],[2],[3]) ) AS P;


---------------------------------------------------------------------
-- Exercise 2 - Pivot Data and Compute Counts
---------------------------------------------------------------------

-- 1.

-- show customer IDs on rows, shipper IDs on columns, count of orders in intersection

-- first attempt to use a query similar to the one in the module, but with COUNT(*)
WITH PivotData AS
(
  SELECT
    custid   ,  -- grouping column
    shipperid   -- spreading column
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3]
FROM PivotData
  PIVOT( COUNT(*) FOR shipperid IN ([1],[2],[3]) ) AS P;

-- 2.

-- solve the problem by either returning the key or a dummy column
WITH PivotData AS
(
  SELECT
    custid   ,  -- grouping column
    shipperid,  -- spreading column
    1 AS aggcol -- aggregation column
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3]
FROM PivotData
  PIVOT( COUNT(aggcol) FOR shipperid IN ([1],[2],[3]) ) AS P;

---------------------------------------------------------------------
-- Lesson 03 - Using Window Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Using Window Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Use Window Aggregate Functions
---------------------------------------------------------------------

-- 2.

-- per each customer and order compute moving average value of the customer's last three orders
SELECT custid, orderid, orderdate, val,
  AVG(val) OVER(PARTITION BY custid
                ORDER BY orderdate, orderid
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW) AS movingavg
FROM Sales.OrderValues;

---------------------------------------------------------------------
-- Exercise 2 - Using Window Ranking and Offset Functions
---------------------------------------------------------------------

-- 1.

-- filter for each shipper the three orders with the highest freight
WITH C AS
(
  SELECT shipperid, orderid, freight,
    ROW_NUMBER() OVER(PARTITION BY shipperid
                      ORDER BY freight DESC, orderid) AS rownum
  FROM Sales.Orders
)
SELECT shipperid, orderid, freight
FROM C
WHERE rownum <= 3
ORDER BY shipperid, rownum;

-- 2.

-- compute the difference between the current order value and the value of the customer's previous order,
-- as well as the difference between the current order value and the value of the customer's next order

SELECT custid, orderid, orderdate, val,
  val - LAG(val)  OVER(PARTITION BY custid
                       ORDER BY orderdate, orderid) AS diffprev,
  val - LEAD(val) OVER(PARTITION BY custid
                       ORDER BY orderdate, orderid) AS diffnext
FROM Sales.OrderValues;
