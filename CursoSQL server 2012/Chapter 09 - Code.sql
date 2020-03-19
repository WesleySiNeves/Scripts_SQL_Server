-- Chapter 09 - Designing and Creating Views, Inline Functions and Synonyms 

-- Lesson 1: Designing and Implementing Views and Inline Functions
CREATE VIEW Sales.OrderTotalsByYear
  WITH SCHEMABINDING
AS
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

--You can read from a view just as you would a table. So you can SELECT from it as follows:
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear; 
--Now let's put this example in the context of the basic syntax for the CREATE VIEW statement:

CREATE VIEW [ schema_name . ] view_name [ (column [ ,...n ] ) ]
[ WITH <view_attribute> [ ,...n ] ]
AS select_statement
[ WITH CHECK OPTION ] [ ; ]

--You can specify the set of output columns following the view name. For example, you could rewrite the CREATE VIEW statement for Sales.OrderTotalsByYear and specify the column names right after the view name instead of in the SELECT statement:
CREATE VIEW Sales.OrderTotalsByYear(orderyear, qty)
  WITH SCHEMABINDING 
AS
SELECT
  YEAR(O.orderdate),
  SUM(OD.qty) 
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

--After you have created a view, you can use the ALTER VIEW command to change the view's structure and add or remove the view properties. An ALTER VIEW simply redefines how the view works by re-issuing the entire view definition. For example, you could redefine the Sales.OrderTotalsByYear view to add a new column for the region the order was shipped to, the shipregion column: 
ALTER VIEW Sales.OrderTotalsByYear
  WITH SCHEMABINDING 
AS
SELECT
  O.shipregion,
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate), O.shipregion;
GO

--Now you can change the way you SELECT from the view, just as you would a table to include the new column; and you can optionally order the results with an ORDER BY:
SELECT shipregion, orderyear, qty
FROM Sales.OrderTotalsByYear
ORDER BY shipregion;

--You drop a view in the same way you would a table:
DROP VIEW Sales.OrderTotalsByYear;

--When you need to create a new view and conditionally replace the old view, you must first drop the old view and then create the new view. The following example shows one method:
IF OBJECT_ID('Sales.OrderTotalsByYear', 'V') IS NOT NULL
	DROP VIEW Sales.OrderTotalsByYear;
GO
CREATE VIEW Sales.OrderTotalsByYear
...
--To explore view metadata using T-SQL, you can query the sys.views catalog view:
USE TSQL2012;
GO
SELECT name, object_id, principal_id, schema_id, type 
FROM sys.views;

--You can also query the INFORMATION_SCHEMA.TABLES system view, but it is slightly more complex:
SELECT SCHEMA_NAME, TABLE_NAME, TABLE_TYPE 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'VIEW';

--Using sys.views is more reliable, and from it you can join to other catalog views such as sys.sql_modules to get further information.
--An inline table-valued function returns a row set based on a SELECT statement you coded into the function. In effect, you treat the table-valued function as a table and SELECT FROM it. For example, you can create an inline function that would operate just like the Sales.OrderTotalsByYear view, with no parameters, as follows:
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear ()
RETURNS TABLE
AS
RETURN
	(
	SELECT
	  YEAR(O.orderdate) AS orderyear,
	  SUM(OD.qty) AS qty
	FROM Sales.Orders AS O
	  JOIN Sales.OrderDetails AS OD
		ON OD.orderid = O.orderid
	GROUP BY YEAR(orderdate)
	);
GO

--In the above example, the SELECT statement was just as complex as the original Sales.OrderTotalsByYear view. If you don't need any additional columns from the table, you could actually simplify the function by selecting from the view directly:
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear ()
RETURNS TABLE
AS
RETURN
	(
	SELECT orderyear, qty FROM Sales.OrderTotalsByYear 
	);
GO

--Consider that if you only wanted to see the year 2007, you would just put that in a WHERE clause when selecting from the view. 
SELECT orderyear, qty
FROM [Sales].[OrderTotalsByYear]
WHERE orderyear = 2007; 


--To make the WHERE clause more flexible, you can declare a variable and then filter based on the variable:
DECLARE @orderyear int = 2007;
SELECT orderyear, qty
FROM Sales.OrderTotalsByYear
WHERE orderyear = @orderyear;

--Keeping this in mind, it is now just a quick step to an inline function. Instead of declaring a variable @orderyear, define the parameter @orderyear in the function while filtering the SELECT statement in the same way as previously:
USE TSQL2012;
GO
IF OBJECT_ID (N'Sales.fn_OrderTotalsByYear', N'IF') IS NOT NULL
    DROP FUNCTION Sales.fn_OrderTotalsByYear;
GO
CREATE FUNCTION Sales.fn_OrderTotalsByYear (@orderyear int)
RETURNS TABLE
AS
RETURN
	(
	SELECT orderyear, qty FROM Sales.OrderTotalsByYear 
	WHERE orderyear = @orderyear
	);
GO

--You can query the function but pass the year you want to see:
SELECT orderyear, qty FROM Sales.fn_OrderTotalsByYear(2007);


-- Lesson 2: Using Synonyms
--To create a synonym, you simply assign a synonym name, and specify the name of the database object it will be assigned to. For example, you could define a synonym called Categories and put it in the dbo schema so that users do not need to remember the schema-object name Production.Categories in their queries. You can issue:
USE TSQL2012;
GO
CREATE SYNONYM dbo.Categories FOR Production.Categories;
GO

--Then the end user can select from Categories without needing to specify a schema:
SELECT categoryid, categoryname, description *  
FROM Categories;

--The basic syntax for creating a synonym is quite simple:
CREATE SYNONYM schema_name.synonym_name FOR object_name

--You can drop a synonym using the DROP SYNONYM statement:
DROP SYNONYM dbo.Categories
--There is no ALTER SYNONYM. As a result, just as with a database schema, to change a synonym you must drop and recreate it.

--For example, suppose the database DB01 has a view called Sales.Reports, and it is on the same server as TSQL2012. Then to query it from TSQL2012, you must write something like:
SELECT report_id, report_name FROM ReportsDB.Sales.Reports

--Now suppose you add a synonym, called simply Sales.Reports:
CREATE SYNONYM Sales.Reports FOR ReportsDB.Sales.Reports 

--The query is now simplified to:
SELECT report_id, report_name FROM Sales.Reports

