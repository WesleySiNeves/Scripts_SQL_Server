---------------------------------------------------------------------
-- TK 70-461 - Chapter 13 - Designing and Implementing T-SQL Routines
-- Code
---------------------------------------------------------------------

USE TSQL2012;
GO
SET NOCOUNT ON;
GO

---------------------------------------------------------------------
-- Chapter 13 - Lesson 1: Designing and Implementing Stored Procedures
---------------------------------------------------------------------

USE TSQL2012;
GO
SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
FROM Sales.Orders
WHERE custid = 37
	AND orderdate >= '2007-04-01'
	AND orderdate < '2007-07-01'; 
-- This query is limited because it has literal values in the WHERE clause. Let's make the code a little more general by using variables in place of those literals values:

USE TSQL2012;
GO
DECLARE	@custid   AS INT,
	@orderdatefrom AS DATETIME,
	@orderdateto   AS DATETIME;
SET @custid = 37;
SET @orderdatefrom = '2007-04-01';
SET @orderdateto = '2007-07-01';
SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
FROM Sales.Orders
WHERE custid = @custid
	AND orderdate >= @orderdatefrom
	AND orderdate < @orderdateto;
GO 

IF OBJECT_ID('Sales.GetCustomerOrders', 'P') IS NOT NULL
	DROP PROC Sales.GetCustomerOrders;
GO
CREATE PROC Sales.GetCustomerOrders
	@custid   AS INT,
	@orderdatefrom AS DATETIME = '19000101',
	@orderdateto   AS DATETIME = '99991231',
	@numrows  AS INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
	FROM Sales.Orders
	WHERE custid = @custid
		AND orderdate >= @orderdatefrom
		AND orderdate < @orderdateto;
	SET @numrows = @@ROWCOUNT;
	RETURN;
END
GO 
-- After you execute the above code and create the stored procedure, you can call the stored procedure as follows:
DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
  @custid   = 37, 
  @orderdatefrom = '20070401',
  @orderdateto  = '20070701',
  @numrows  = @rowsreturned OUTPUT;
SELECT @rowsreturned AS "Rows Returned";


-- Testing for the existence of a stored procedure
IF OBJECT_ID('Sales.GetCustomerOrders', 'P') IS NOT NULL
	DROP PROC Sales.GetCustomerOrders;
GO

-- Stored procedure parameters
CREATE PROC Sales.GetCustomerOrders
	@custid   AS INT,
	@orderdatefrom AS DATETIME = '19000101',
	@orderdateto   AS DATETIME = '99991231',
	@numrows  AS INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT orderid, custid, shipperid, orderdate, requireddate, shippeddate
	FROM [Sales].[Orders]
	WHERE custid = @custid
		AND orderdate >= @orderdatefrom
		AND orderdate < @orderdateto;
	SET @numrows = @@ROWCOUNT;
	RETURN;
END


-- Executing Stored Procedures
EXEC sp_configure;

-- Input parameters
EXEC Sales.GetCustomerOrders 37, '20070401', '20070701';

EXEC Sales.GetCustomerOrders  @custid   = 37,   @orderdatefrom = '20070401',  @orderdateto  = '20070701';

EXEC Sales.GetCustomerOrders
	@orderdatefrom = '20070401',
	@orderdateto  = '20070701',
	@custid   = 37; 
GO

EXEC Sales.GetCustomerOrders
  @custid   = 37;
GO

-- Output Parameters
CREATE PROC Sales.GetCustomerOrders
	@custid   AS INT,
	@orderdatefrom AS DATETIME = '19000101',
	@orderdateto   AS DATETIME = '99991231',
	@numrows AS INT = 0 OUTPUT
AS <rest of procedure>

DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
  @custid   = 37, 
  @orderdatefrom = '20070401',
  @orderdateto  = '20070701',
  @numrows  = @rowsreturned;
SELECT @rowsreturned AS 'Rows Returned';
GO

DECLARE @rowsreturned AS INT;
EXEC Sales.GetCustomerOrders
  @custid   = 37, 
  @orderdatefrom = '20070401',
  @orderdateto  = '20070701',
  @numrows  = @rowsreturned OUTPUT;
SELECT @rowsreturned AS 'Rows Returned';
GO

-- Branching Logic
-- IF/ELSE
DECLARE @var1 AS INT, @var2 AS INT;
SET @var1 = 1;
SET @var2 = 2;
IF @var1 = @var2
	PRINT 'The variables are equal';
ELSE
	PRINT 'The variables are not equal';
GO

DECLARE @var1 AS INT, @var2 AS INT;
SET @var1 = 1;
SET @var2 = 1;
IF @var1 = @var2
	PRINT 'The variables are equal';
ELSE
	PRINT 'The variables are not equal';
	PRINT '@var1 does not equal @var2';
GO


DECLARE @var1 AS INT, @var2 AS INT;
SET @var1 = 1;
SET @var2 = 1;
IF @var1 = @var2
	BEGIN
		PRINT 'The variables are equal';
		PRINT '@var1 equals @var2';
	END
ELSE
	BEGIN
		PRINT 'The variables are not equal';
		PRINT '@var1 does not equal @var2';
	END
GO

-- While
SET NOCOUNT ON;
DECLARE @count AS INT = 1;
WHILE @count <= 10
	BEGIN
		PRINT CAST(@count AS NVARCHAR);
		SET @count += 1;
	END;

SET NOCOUNT ON;
DECLARE @count AS INT = 1;
WHILE @count <= 100
	BEGIN
		IF @count = 10
			BREAK;
		IF @count = 5
			BEGIN
				SET @count += 2;
				CONTINUE;
			END
		PRINT CAST(@count AS NVARCHAR);
		SET @count += 1;
	END;

DECLARE @categoryid AS INT;
SET @categoryid = (SELECT MIN(categoryid) FROM Production.Categories);
WHILE @categoryid IS NOT NULL
BEGIN
  PRINT CAST(@categoryid AS NVARCHAR);
  SET @categoryid = (SELECT MIN(categoryid) FROM Production.Categories 
    WHERE categoryid > @categoryid);
END;
GO

DECLARE @categoryname AS NVARCHAR(15);
SET @categoryname = (SELECT MIN(categoryname) FROM Production.Categories);
WHILE @categoryname IS NOT NULL
BEGIN
  PRINT @categoryname;
  SET @categoryname = (SELECT MIN(categoryname) FROM Production.Categories 
    WHERE categoryname > @categoryname);
END;
GO

-- WAITFOR

WAITFOR DELAY '00:00:20';
WAITFOR TIME '23:46:00';

-- GOTO
PRINT 'First PRINT statement';
GOTO MyLabel;
PRINT 'Second PRINT statement';
MyLabel:
PRINT 'End';

-- Stored procedure results
IF OBJECT_ID('Sales.ListSampleResultsSets', 'P') IS NOT NULL
  DROP PROC Sales.ListSampleResultsSets;
GO
CREATE PROC Sales.ListSampleResultsSets
AS
	BEGIN
		SELECT TOP (1) productid, productname, supplierid, 
			categoryid, unitprice, discontinued
		FROM Production.Products;
		SELECT TOP (1) orderid, productid, unitprice, qty, discount
		FROM Sales.OrderDetails;
	END
GO
EXEC Sales.ListSampleResultsSets



---------------------------------------------------------------------
-- Chapter 13 - Lesson 2: Implementing Triggers
---------------------------------------------------------------------

-- AFTER triggers
--CREATE TRIGGER TriggerName
--    ON [dbo].[TableName]
--    FOR DELETE, INSERT, UPDATE
--    AS
--    BEGIN
--    SET NOCOUNT ON


IF OBJECT_ID('Sales.tr_SalesOrderDetailsDML', 'TR') IS NOT NULL
	DROP TRIGGER Sales.tr_SalesOrderDetailsDML;
GO
CREATE TRIGGER Sales.tr_SalesOrderDetailsDML
ON Sales.OrderDetails
AFTER DELETE, INSERT, UPDATE
AS
BEGIN
  IF @@ROWCOUNT = 0 RETURN; -- Must be 1st statement
  SET NOCOUNT ON;
END;

IF OBJECT_ID('Sales.tr_SalesOrderDetailsDML', 'TR') IS NOT NULL
	DROP TRIGGER Sales.tr_SalesOrderDetailsDML;
GO
CREATE TRIGGER Sales.tr_SalesOrderDetailsDML
ON Sales.OrderDetails
AFTER DELETE, INSERT, UPDATE
AS
BEGIN
  IF @@ROWCOUNT = 0 RETURN; 
  SET NOCOUNT ON;
  SELECT COUNT(*) AS InsertedCount FROM Inserted;
  SELECT COUNT(*) AS DeletedCount FROM Deleted;
END;

IF OBJECT_ID('Production.tr_ProductionCategories_categoryname', 'TR') IS NOT NULL	DROP TRIGGER Production.tr_ProductionCategories_categoryname;
GO
CREATE TRIGGER Production.tr_ProductionCategories_categoryname
ON Production.Categories
AFTER INSERT, UPDATE
AS
BEGIN
  IF @@ROWCOUNT = 0 RETURN; 
  SET NOCOUNT ON;
  IF EXISTS (SELECT COUNT(*)
        FROM Inserted AS I
        JOIN Production.Categories AS C
          ON I.categoryname = C.categoryname
		GROUP BY I.categoryname
		HAVING COUNT(*) > 1 )
    BEGIN
      THROW 50000, 'Duplicate category names not allowed', 0;
    END;
END;
GO

INSERT INTO Production.Categories (categoryname,description)
     VALUES ('TestCategory1', 'Test1 description v1');

UPDATE Production.Categories
  SET categoryname = 'Beverages' WHERE categoryname = 'TestCategory1';

DELETE FROM Production.Categories WHERE categoryname = 'TestCategory1';

-- Nested AFTER triggers
EXEC sp_configure 'nested triggers';

-- INSTEAD OF triggers
IF OBJECT_ID('Production.tr_ProductionCategories_categoryname', 'TR') IS NOT NULL
DROP TRIGGER Production.tr_ProductionCategories_categoryname;
GO
CREATE TRIGGER Production.tr_ProductionCategories_categoryname
ON Production.Categories
INSTEAD OF INSERT
AS
BEGIN
  SET NOCOUNT ON;
  IF EXISTS (SELECT COUNT(*)
        FROM Inserted AS I
        JOIN Production.Categories AS C
          ON I.categoryname = C.categoryname
		GROUP BY I.categoryname
		HAVING COUNT(*) > 1 )  
    BEGIN
      THROW 50000, 'Duplicate category names not allowed', 0;
     END;
  ELSE 
    INSERT Production.Categories (categoryname, description)
      SELECT categoryname, description FROM Inserted;
END;
GO 
-- Cleanup
IF OBJECT_ID('Production.tr_ProductionCategories_categoryname', 'TR') IS NOT NULL
  DROP TRIGGER Production.tr_ProductionCategories_categoryname;

-- DML Trigger Functions referenced by an INSERT or UPDATE statement. For example, 
IF UPDATE(qty)
  PRINT 'Column qty affected';

UPDATE Sales.OrderDetails
	SET qty = 99
	WHERE orderid = 10249 AND productid = 16;




---------------------------------------------------------------------
-- Chapter 13 - Lesson 3: Implementing User-Defined Functions
---------------------------------------------------------------------

-- Scalar UDFs
CREATE FUNCTION dbo.FunctionName
(
    @param1 int,
	@param2 int
)
RETURNS INT
AS
BEGIN
    RETURN @param1 + @param2
END


IF OBJECT_ID('Sales.fn_extension', 'FN') IS NOT NULL
	DROP FUNCTION Sales.fn_extension
GO
CREATE FUNCTION Sales.fn_extension
(
  @unitprice AS MONEY,
  @qty AS INT
)
RETURNS MONEY
AS
BEGIN
    RETURN @unitprice * @qty
END;
GO

SELECT Orderid, unitprice, qty, Sales.fn_extension(unitprice, qty) AS extension
FROM Sales.OrderDetails;

SELECT Orderid, unitprice, qty, Sales.fn_extension(unitprice, qty) AS extension
FROM Sales.OrderDetails
WHERE Sales.fn_extension(unitprice, qty) > 1000;

-- Table-valued UDFs
CREATE FUNCTION dbo.FunctionName
(
    @param1 int,
    @param2 char(5)
)
RETURNS TABLE AS RETURN
(
    SELECT @param1 AS c1,
	       @param2 AS c2
)

IF OBJECT_ID('Sales.fn_FilteredExtension', 'IF') IS NOT NULL
	DROP FUNCTION Sales.fn_FilteredExtension;
GO
CREATE FUNCTION Sales.fn_FilteredExtension
(
  @lowqty AS SMALLINT,
  @highqty AS SMALLINT
 )
RETURNS TABLE AS RETURN
(
    SELECT orderid, unitprice, qty
	FROM Sales.OrderDetails
	WHERE qty BETWEEN @lowqty AND @highqty
);
GO


SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtension (10,20);


RETURNS TABLE AS RETURN
(
<SELECT …>
);


-- Multistatement table-valued UDF
CREATE FUNCTION dbo.FunctionName
(
    @param1 int,
    @param2 char(5)
)
RETURNS @returntable TABLE
(
	c1 int,
	c2 char(5)
)
AS
BEGIN
    INSERT @returntable
    SELECT @param1, @param2
    RETURN 
END;
GO

IF OBJECT_ID('Sales.fn_FilteredExtension2', 'TF') IS NOT NULL
	DROP FUNCTION Sales.fn_FilteredExtension2;
GO
CREATE FUNCTION Sales.fn_FilteredExtension2
(
  @lowqty AS SMALLINT,
  @highqty AS SMALLINT
 )
RETURNS @returntable TABLE 
(
	orderid  INT,
	unitprice  MONEY,
	qty  SMALLINT
)
AS
BEGIN
  INSERT @returntable
	SELECT orderid, unitprice, qty
	FROM Sales.OrderDetails
	WHERE qty BETWEEN @lowqty AND @highqty
  RETURN
END;
GO


-- Now use the function:
SELECT orderid, unitprice, qty
FROM Sales.fn_FilteredExtension2 (10,20);







