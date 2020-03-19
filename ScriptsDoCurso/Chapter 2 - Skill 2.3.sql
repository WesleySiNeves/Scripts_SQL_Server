---------------------------------------------------------------------
-- Exam Ref 70-761 Querying Data with Transact-SQL
-- Chapter 2 - Query Data with Advanced Transact-SQL Components
-- Skill 2.3: Group and pivot data by using queries
-- � Itzik Ben-Gan
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Writing grouped queries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Working with a single grouping set
---------------------------------------------------------------------

-- grouped query without GROUP BY clause
USE TSQLV4;

SELECT COUNT(*) AS numorders
FROM Sales.Orders;

-- grouped query with GROUP BY clause
SELECT shipperid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid;

-- grouping set with multiple elements
SELECT Orders.shipperid,
       YEAR(Orders.shippeddate) AS shippedyear,
       COUNT(*) AS numorders
  FROM Sales.Orders
 GROUP BY Orders.shipperid,
          YEAR(Orders.shippeddate);

-- filtering groups
SELECT Orders.shipperid,
       YEAR(Orders.shippeddate) AS shippedyear,
       COUNT(*) AS numorders
  FROM Sales.Orders
 WHERE Orders.shippeddate IS NOT NULL
 GROUP BY Orders.shipperid,
          YEAR(Orders.shippeddate)
HAVING COUNT(*) < 100;

-- general aggregate functions ignore NULLs
SELECT OrderValues.shipperid,
       COUNT(*) AS numorders,
       COUNT(OrderValues.shippeddate) AS shippedorders,
       MIN(OrderValues.shippeddate) AS firstshipdate,
       MAX(OrderValues.shippeddate) AS lastshipdate,
       SUM(OrderValues.val) AS totalvalue
  FROM Sales.OrderValues
 GROUP BY OrderValues.shipperid;

-- aggregating distinct cases
SELECT shipperid, COUNT(DISTINCT shippeddate),COUNT(shippeddate) AS numshippingdates
FROM Sales.Orders
GROUP BY shipperid;
GO

-- grouped query cannot refer to detail elements after grouping
SELECT S.shipperid,
       S.companyname,
       COUNT(*) AS numorders
  FROM Sales.Shippers AS S
 INNER JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
 GROUP BY S.shipperid;
GO

-- solution 1: add column to grouping set
SELECT S.shipperid,
       S.companyname,
       COUNT(*) AS numorders
  FROM Sales.Shippers AS S
 INNER JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
 GROUP BY S.shipperid,
          S.companyname;

-- solution 2: apply an aggregate to the column
SELECT S.shipperid,
       MAX(S.companyname) AS companyname,
       COUNT(*) AS numorders
  FROM Sales.Shippers AS S
 INNER JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
 GROUP BY S.shipperid;

-- solution 3: join after aggregating
WITH C AS
(
  SELECT shipperid, COUNT(*) AS numorders
  FROM Sales.Orders
  GROUP BY shipperid
)
SELECT S.shipperid, S.companyname, numorders
FROM Sales.Shippers AS S
  INNER JOIN C
    ON S.shipperid = C.shipperid;

---------------------------------------------------------------------
-- Working with multiple grouping sets
---------------------------------------------------------------------

-- using the GROUPING SETS clause
SELECT Orders.shipperid,
       YEAR(Orders.shippeddate) AS shipyear,
       COUNT(*) AS numorders
  FROM Sales.Orders
 WHERE Orders.shippeddate IS NOT NULL -- exclude unshipped orders
 GROUP BY GROUPING SETS((Orders.shipperid, YEAR(Orders.shippeddate)), (Orders.shipperid), (YEAR(Orders.shippeddate)), ());

--using the CUBE clause
SELECT Orders.shipperid,
       YEAR(Orders.shippeddate) AS shipyear,
       COUNT(*) AS numorders
  FROM Sales.Orders
 WHERE Orders.shippeddate IS NOT NULL
 GROUP BY CUBE(Orders.shipperid, YEAR(Orders.shippeddate));

-- using the ROLLUP clause
SELECT Orders.shipcountry,
       Orders.shipregion,
       Orders.shipcity,
       COUNT(*) AS numorders
  FROM Sales.Orders
 GROUP BY ROLLUP(Orders.shipcountry, Orders.shipregion, Orders.shipcity);

-- GROUPING and GROUPING_ID

-- GROUPING
SELECT Orders.shipcountry,
       GROUPING(Orders.shipcountry) AS grpcountry,
       Orders.shipregion,
       GROUPING(Orders.shipregion) AS grpregion,
       Orders.shipcity,
       GROUPING(Orders.shipcity) AS grpcity,
       COUNT(*) AS numorders
  FROM Sales.Orders
 GROUP BY ROLLUP(Orders.shipcountry, Orders.shipregion, Orders.shipcity);

-- GROUPING_ID
SELECT GROUPING_ID(Orders.shipcountry, Orders.shipregion, Orders.shipcity) AS grp_id,
       Orders.shipcountry,
       Orders.shipregion,
       Orders.shipcity,
       COUNT(*) AS numorders
  FROM Sales.Orders
 GROUP BY ROLLUP(Orders.shipcountry, Orders.shipregion, Orders.shipcity);

---------------------------------------------------------------------
-- Pivoting and unpivoting data
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Pivoting data
---------------------------------------------------------------------

-- show customer IDs on rows, shipper IDs on columns, total freight in intersection
WITH PivotData
  AS (SELECT Orders.custid, -- grouping column
             Orders.shipperid, -- spreading column
             Orders.freight -- aggregation column
        FROM Sales.Orders)
SELECT custid,
       [1],
       [2],
       [3]
  FROM PivotData
    PIVOT (   SUM(freight)
              FOR shipperid IN ([1], [2], [3])) AS P;

-- Replace NULLs with 0.00
WITH PivotData AS
(
  SELECT
    custid,   
    shipperid,
    freight   
  FROM Sales.Orders
)
SELECT custid,
  ISNULL([1], 0.00) AS [1],
  ISNULL([2], 0.00) AS [2],
  ISNULL([3], 0.00) AS [3]
FROM PivotData
  PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

-- when applying PIVOT to Orders table direclty get a result row for each order
SELECT custid, [1], [2], [3]
FROM Sales.Orders
  PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

---------------------------------------------------------------------
-- Unpivoting data
---------------------------------------------------------------------

-- sample data for UNPIVOT example
USE TSQLV4;
DROP TABLE IF EXISTS Sales.FreightTotals;
GO

WITH PivotData AS
(
  SELECT
    custid,    -- grouping column
    shipperid, -- spreading column
    freight    -- aggregation column
  FROM Sales.Orders
)
SELECT *
INTO Sales.FreightTotals
FROM PivotData
  PIVOT( SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

SELECT * FROM Sales.FreightTotals;

-- unpivot data
SELECT custid, shipperid, freight
FROM Sales.FreightTotals
  UNPIVOT( freight FOR shipperid IN([1],[2],[3]) ) AS U;

-- keep NULLs
WITH C AS
(
  SELECT custid,
    ISNULL([1], 0.00) AS [1],
    ISNULL([2], 0.00) AS [2],
    ISNULL([3], 0.00) AS [3]
  FROM Sales.FreightTotals
)
SELECT custid, shipperid, NULLIF(freight, 0.00) AS freight
FROM C
  UNPIVOT( freight FOR shipperid IN([1],[2],[3]) ) AS U;

-- cleanup
DROP TABLE IF EXISTS Sales.FreightTotals;

---------------------------------------------------------------------
-- Using window functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Window aggregate functions
---------------------------------------------------------------------

-- partitioning

-- returning detail as well as aggregates
SELECT OrderValues.custid,
       OrderValues.orderid,
       OrderValues.val,
       SUM(OrderValues.val) OVER (PARTITION BY OrderValues.custid) AS custtotal,
       SUM(OrderValues.val) OVER () AS grandtotal
  FROM Sales.OrderValues;

-- computing percents of detail out of aggregates
SELECT OrderValues.custid,
       OrderValues.orderid,
       OrderValues.val,
       CAST(100.0 * OrderValues.val / SUM(OrderValues.val) OVER (PARTITION BY OrderValues.custid) AS NUMERIC(5, 2)) AS pctcust,
       CAST(100.0 * OrderValues.val / SUM(OrderValues.val) OVER () AS NUMERIC(5, 2)) AS pcttotal
  FROM Sales.OrderValues;

-- framing

 --computing running total
SELECT custid, orderid, orderdate, val,
  SUM(val) OVER(PARTITION BY custid
                ORDER BY orderdate, orderid
                ROWS BETWEEN UNBOUNDED PRECEDING
                         AND CURRENT ROW) AS runningtotal
FROM Sales.OrderValues;

-- filter running totals that are less than 1000.00
WITH RunningTotals AS
(
  SELECT custid, orderid, orderdate, val,
    SUM(val) OVER(PARTITION BY custid
                  ORDER BY orderdate, orderid
                  ROWS BETWEEN UNBOUNDED PRECEDING
                           AND CURRENT ROW) AS runningtotal
  FROM Sales.OrderValues
)
SELECT *
FROM RunningTotals
WHERE runningtotal < 1000.00;

---------------------------------------------------------------------
-- Window ranking functions
---------------------------------------------------------------------

SELECT custid, orderid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  RANK()       OVER(ORDER BY val) AS rnk,
  DENSE_RANK() OVER(ORDER BY val) AS densernk,
  NTILE(100)   OVER(ORDER BY val) AS ntile100
FROM Sales.OrderValues;

---------------------------------------------------------------------
-- Window offset functions
---------------------------------------------------------------------

-- LAG and LEAD retrieving values from previous and next rows
SELECT OrderValues.custid,
       OrderValues.orderid,
       OrderValues.orderdate,
       OrderValues.val,
       LAG(OrderValues.val) OVER (PARTITION BY OrderValues.custid
                                      ORDER BY OrderValues.orderdate,
                                               OrderValues.orderid) AS prev_val,
       LEAD(OrderValues.val) OVER (PARTITION BY OrderValues.custid
                                       ORDER BY OrderValues.orderdate,
                                                OrderValues.orderid) AS next_val
  FROM Sales.OrderValues;

-- FIRST_VALUE and LAST_VALUE retrieving values from first and last rows in frame
SELECT OrderValues.custid,
       OrderValues.orderid,
       OrderValues.orderdate,
       OrderValues.val,
       FIRST_VALUE(OrderValues.val) OVER (PARTITION BY OrderValues.custid
                                              ORDER BY OrderValues.orderdate,
                                                       OrderValues.orderid
                                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS first_val,
       LAST_VALUE(OrderValues.val) OVER (PARTITION BY OrderValues.custid
                                             ORDER BY OrderValues.orderdate,
                                                      OrderValues.orderid
                                              ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS last_val
  FROM Sales.OrderValues
 ORDER BY OrderValues.custid,
          OrderValues.orderdate,
          OrderValues.orderid;

