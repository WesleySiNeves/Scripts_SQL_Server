-- =============================================================
-- Chapter 9, Lesson 1
-- Exercise 1 Building a view for a report
-- =============================================================
--You have been asked to develop the database interface for a report on the TSQL2012 database. The application needs a view that shows the quantity sold and total sales for all sales, by year, per customer and per shipper. The user would also like to be able to filter the results by upper and lower total quantity. 
--1.	Start with the current [Sales].[OrderTotalsByYear] as shown in the Lesson above. Type in the SELECT statement without the view definition:
USE TSQL2012;
GO
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);

--2.	Note that the [Sales].[OrderValues] view does contain the computed sales amount, as 
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
       AS NUMERIC(12, 2)) AS val

--3.	Combine the two queries:
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);

--4.	Now add the columns for custid to return the customer id and the shipperid. Note that you must now change the GROUP BY clause in order to expose those two ids: 
SELECT
  O.custid,
  O.shipperid,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(O.orderdate), O.custid, O.shipperid;

--5.	So far so good, but you need to show the shipper and customer names in the results for the report. So you need to add JOINs to the [Sales].[Customers] table and to the [Sales].[Shippers] table:
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Sales.Customers AS C
	ON O.custid = C.custid
  JOIN Sales.Shippers AS S
	ON O.shipperid = S.shipperid
GROUP BY YEAR(O.orderdate);

--6.	Now add the customer company name (companyname) and the shipping company name (companyname). You must expand the GROUP BY clause to expose those columns:
SELECT
  C.companyname AS customercompany,
  S.companyname AS shippercompany,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Sales.Customers AS C
	ON O.custid = C.custid
  JOIN Sales.Shippers AS S
	ON O.shipperid = S.shipperid
GROUP BY YEAR(O.orderdate), C.companyname, S.companyname;

--7.	Now turn this into a view called [Sales].[OrderTotalsByYearCustShip]:
IF OBJECT_ID (N'Sales.OrderTotalsByYearCustShip', N'V') IS NOT NULL
    DROP VIEW Sales.OrderTotalsByYearCustShip;
GO
CREATE VIEW [Sales].[OrderTotalsByYearCustShip]
  WITH SCHEMABINDING
AS
SELECT
  C.companyname AS customercompany,
  S.companyname AS shippercompany,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty,
  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
     AS NUMERIC(12, 2)) AS val
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
  JOIN Sales.Customers AS C
	ON O.custid = C.custid
  JOIN Sales.Shippers AS S
	ON O.shipperid = S.shipperid
GROUP BY YEAR(O.orderdate), C.companyname, S.companyname;
GO
--Test the view by SELECTing from it:
SELECT SELECT customercompany, shippercompany, orderyear, qty, val 
FROM [Sales].[OrderTotalsByYearCustShip]
ORDER BY customercompany, shippercompany, orderyear;

-- 8.	To clean up, drop the view.
IF OBJECT_ID(N'Sales.OrderTotalsByYearCustShip', N'V') IS NOT NULL
    DROP VIEW Sales.OrderTotalsByYearCustShip

-- =============================================================
-- Chapter 9, Lesson 1
-- Exercise 2 Convert a View into an Inline Function
-- =============================================================
--1.	Now change the view into an inline function that filters by low and high values of the total quantity. Add two parameters called @highqty and @lowqty, both integers, and add a WHERE clause to filter the results. Name the function [Sales].[fn_ OrderTotalsByYearCustShip]:
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYearCustShip', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYearCustShip;
GO
CREATE FUNCTION [Sales].[fn_OrderTotalsByYearCustShip] (@lowqty int, @highqty int)
RETURNS TABLE
AS
RETURN
	(
	SELECT
	  C.companyname AS customercompany,
	  S.companyname AS shippercompany,
	  YEAR(O.orderdate) AS orderyear,
	  SUM(OD.qty) AS qty,
	  CAST(SUM(OD.qty * OD.unitprice * (1 - OD.discount))
		 AS NUMERIC(12, 2)) AS val
	FROM Sales.Orders AS O
	  JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
	  JOIN Sales.Customers AS C
		ON O.custid = C.custid
	  JOIN Sales.Shippers AS S
		ON O.shipperid = S.shipperid
	GROUP BY YEAR(O.orderdate), C.companyname, S.companyname
	HAVING SUM(OD.qty) >= @lowqty AND SUM(OD.qty) <= @highqty
	);
GO

-- 2.	Now test the function:
SELECT customercompany, shippercompany, orderyear, qty, val  
FROM [Sales].[fn_OrderTotalsByYearCustShip] (100, 200)
ORDER BY customercompany, shippercompany, orderyear;
--Experiment with other values until you are certain you understand how the function and its filtering is working.

-- 3.	Cleanup: To clean up, just drop the view and the function:
IF OBJECT_ID (N'Sales.OrderTotalsByYearCustShip', N'V') IS NOT NULL
    DROP VIEW Sales.OrderTotalsByYearCustShip;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYearCustShip', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYearCustShip;
GO

-- =============================================================
-- Chapter 9, Lesson 2
-- Exercise 1 Using Synonyms to provide more descriptive names for reporting
-- =============================================================

--1.	Assume the following scenario: the TSQL2012 system has been in production for some time now, and you have been asked to provide access for a new reporting application to the database. However, the current view names are not as descriptive as the reporting users would like, so you will use synonyms to make them more descriptive. Start in the TSQL2012 database: 
USE TSQL2012;
GO

--2.	Now create a special schema for reports
CREATE SCHEMA Reports AUTHORIZATION dbo;
GO

--3.	Create a synonym for the Sales.CustOrders view. Look first at the data:
SELECT custid, ordermonth, qty  FROM Sales.CustOrders;
--You have determined that the data actually shows the customer id, then total of the qty column, by month. Therefore create the TotalCustQtyByMonth synonym and test it:
CREATE SYNONYM Reports.TotalCustQtyByMonth FOR Sales.CustOrders;
SELECT  custid, ordermonth, qty  FROM Reports.TotalCustQtyByMonth;

--4.	Next, create a synonym for the Sales.EmpOrders view by inspecting the data first:
SELECT empid, ordermonth, qty, val, numorders FROM Sales.EmpOrders;
--The data shows employee id, then the total qty and val columns, by month. Therefore create the TotalEmpQtyValOrdersByMonth synonym for it and test: 
CREATE SYNONYM Reports.TotalEmpQtyValOrdersByMonth FOR Sales.EmpOrders;
SELECT empid, ordermonth, qty, val, numorders FROM Reports.TotalEmpQtyValOrdersByMonth;

--5.	Next, inspect the data for Sales.OrderTotalsByYear:
SELECT orderyear, qty FROM Sales.OrderTotalsByYear;
--This view shows the total qty value by year, so name the synonym TotalQtyByYear:
CREATE SYNONYM Reports.TotalQtyByYear FOR Sales.OrderTotalsByYear;
SELECT orderyear, qty FROM Reports.TotalQtyByYear;

--6.	Last, inspect the data for Sales.OrderValues:
SELECT orderid, custid, empid, shipperid, orderdate, requireddate, shippeddate, qty, val 
FROM Sales.OrderValues;

--This view shows the total of val and qty for each order, so name the synonym TotalQtyValOrders:
CREATE SYNONYM Reports.TotalQtyValOrders FOR Sales.OrderValues;
SELECT orderid, custid, empid, shipperid, orderdate, requireddate, shippeddate, qty, val 
FROM Reports.TotalQtyValOrders;
--Note that there is no unique key on the combination of columns in the GROUP BY of the Sales.OrderValues view. Right now, the number of rows grouped is also the number or orders, but that is not guaranteed. Your feedback to the development team should be that if this set of columns does define a unique row in the table, they should create a uniqueness constraint (or a unique index) on the table to enforce it. 

--7.	Now inspect the metadata for the synonyms. Note that you can use the SCHEMA_NAME() function to display the schema name without having to join to the sys.schemas table.
SELECT name, object_id, principal_id, schema_id, parent_object_id  FROM sys.synonyms;
SELECT SCHEMA_NAME(schema_id) AS schemaname, name, object_id, principal_id, schema_id, parent_object_id FROM sys.synonyms;

--8.	Now you can optionally clean up the TSQL database and remove your work.
DROP SYNONYM Reports.TotalCustQtyByMonth;
DROP SYNONYM Reports.TotalEmpQtyValOrdersByMonth;
DROP SYNONYM Reports.TotalQtyByYear;
DROP SYNONYM Reports.TotalQtyValOrders;
GO
DROP SCHEMA Reports;
GO


-- =============================================================
-- Chapter 9, Lesson 2
-- Exercise 2 Useing Synonyms to simplify a cross-database query
-- =============================================================

--1.	You want to show the reporting team that they could run their reports from a dedicated reporting database on the server without having to directly query the main TSQL2012 database. You have decided to use synonyms to prototype the strategy. First, create a new reporting database called TSQL2012Reports:
USE Master;
GO
CREATE DATABASE TSQL2012Reports;
GO

--2.	Now in the reporting database, create a schema called Reports
USE TSQL2012Reports;
GO
CREATE SCHEMA Reports AUTHORIZATION dbo;
GO

--3.	As an initial test, create the TotalCustQtyByMonth synonym to the nonexistent local object Sales.CustOrders and test:
CREATE SYNONYM Reports.TotalCustQtyByMonth FOR Sales.CustOrders;
GO
SELECT custid, ordermonth, qty FROM Reports.TotalCustQtyByMonth; -- Fails
GO
DROP SYNONYM Reports.TotalCustQtyByMonth;
GO

--4.	Next, create the TotalCustQtyByMonth synonym referencing the Sales.CustOrders view in the TSQL2012 database and test it:
CREATE SYNONYM Reports.TotalCustQtyByMonth FOR TSQL2012.Sales.CustOrders;
GO
SELECT custid, ordermonth, qty FROM Reports.TotalCustQtyByMonth; -- Succeeds 
GO

--5.	After you've demonstrated to the reporting team that this scenario can work, clean up and remove the database:
DROP SYNONYM Reports.TotalCustQtyByMonth;
GO
DROP SCHEMA Reports;
GO
USE Master;
GO
DROP DATABASE TSQL2012Reports;
GO
