---------------------------------------------------------------------
-- TK 70-461 - Chapter 13 - Designing and Implementing T-SQL Routines
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 1: Designing and Implementing Stored Procedures
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice: Writing T-SQL Stored Procedures
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 Creating a Stored Procedure to perform administrative tasks
---------------------------------------------------------------------

-- 1.	First develop a WHILE loop 
DECLARE @databasename AS NVARCHAR(128);
SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name NOT IN 
  ('master', 'model', 'msdb', 'tempdb'));
WHILE @databasename IS NOT NULL
BEGIN
  PRINT @databasename;
  SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb') AND name > @databasename);
END
GO

-- 2. In the next few steps
SELECT CONVERT(NVARCHAR, GETDATE(), 120)

-- 3. Now use the REPLACE() function
SELECT REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR, 
    GETDATE(), 120), ' ', '_'), ':', ''), '-', '');

-- 4. You can now add the BACKUP DATABASE command
DECLARE @databasename AS NVARCHAR(128)
	, @timecomponent AS NVARCHAR(50)
	, @sqlcommand AS NVARCHAR(1000);
SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name 
    NOT IN ('master', 'model', 'msdb', 'tempdb'));
WHILE @databasename IS NOT NULL
BEGIN
  SET @timecomponent = REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR, 
    GETDATE(), 120), ' ', '_'), ':', ''), '-', '');
  SET @sqlcommand = 'BACKUP DATABASE ' + @databasename + ' TO DISK =
       ''C:\Backups\' + @databasename + '_' + @timecomponent + '.bak''';
  PRINT @sqlcommand;
  --EXEC(@sqlcommand);
  SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name 
    NOT IN ('master', 'model', 'msdb', 'tempdb') AND name > @databasename);
END;
GO

-- 5. Now convert the script to a stored procedure:
IF OBJECT_ID('dbo.BackupDatabases', 'P') IS NOT NULL 
	DROP PROCEDURE dbo.BackupDatabases
GO
CREATE PROCEDURE dbo.BackupDatabases
AS
BEGIN
  DECLARE @databasename AS NVARCHAR(128)
    , @timecomponent AS NVARCHAR(50)
    , @sqlcommand AS NVARCHAR(1000);
  SET @databasename = (SELECT MIN(name) FROM sys.databases 
    WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb'));
  WHILE @databasename IS NOT NULL
    BEGIN
      SET @timecomponent = REPLACE(REPLACE(REPLACE(
          CONVERT(NVARCHAR, GETDATE(), 120), ' ', '_'), ':', ''), '-', '');
      SET @sqlcommand = 'BACKUP DATABASE ' + @databasename + ' TO DISK = 
          ''C:\Backups\' + @databasename + '_' + @timecomponent + '.bak''';
      PRINT @sqlcommand;
      --EXEC(@sqlcommand);
      SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name 
          NOT IN ('master', 'model', 'msdb', 'tempdb') AND name > @databasename);
  END;
  RETURN;
END;
GO

-- 6. After you run the code in step 6 to create the procedure, test it. 
EXEC dbo.BackupDatabases

-- 7. Finally, add a parameter to the procedure called @databasetype, 
IF OBJECT_ID('dbo.BackupDatabases', 'P') IS NOT NULL 
	DROP PROCEDURE dbo.BackupDatabases;
GO
CREATE PROCEDURE dbo.BackupDatabases
  @databasetype AS NVARCHAR(30)
AS
BEGIN
  DECLARE @databasename AS NVARCHAR(128)
  , @timecomponent AS NVARCHAR(50)
  , @sqlcommand AS NVARCHAR(1000);
  IF @databasetype NOT IN ('User', 'System')
    BEGIN
      THROW 50000, 'dbo.BackupDatabases: @databasename must be User or System', 0;
      RETURN;
  END;
  IF @databasetype = 'System'
    SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name IN 
       ('master', 'model', 'msdb'));
  ELSE
    SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name NOT IN
       ('master', 'model', 'msdb', 'tempdb'));
  WHILE @databasename IS NOT NULL
    BEGIN
      SET @timecomponent = REPLACE(REPLACE(REPLACE(CONVERT(
          NVARCHAR, GETDATE(), 120), ' ', '_'), ':', ''), '-', '');
      SET @sqlcommand = 'BACKUP DATABASE ' + @databasename + ' TO DISK = 
          ''C:\Backups\' + @databasename + '_' + @timecomponent + '.bak''';
      PRINT @sqlcommand;
      --EXEC(@sqlcommand);
      IF @databasetype = 'System'
        SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name IN
            ('master', 'model', 'msdb') AND name > @databasename);
      ELSE
        SET @databasename = (SELECT MIN(name) FROM sys.databases WHERE name NOT IN
            ('master', 'model', 'msdb', 'tempdb') AND name > @databasename);
  END;
  RETURN;
END
GO

-- 8. Now test the procedure. If you pass no parameters, or a parameter other than 'user' or 'system', you should see an error message. If you pass the correct parameters, you should see the backup commands printed out.
EXEC dbo.BackupDatabases;
GO

EXEC dbo.BackupDatabases 'User';
GO

EXEC dbo.BackupDatabases 'System';
GO

EXEC dbo.BackupDatabases 'Unknown'


---------------------------------------------------------------------
-- Exercise 2 - Developing an Insert Stored Procedure for the Data Access Layer
---------------------------------------------------------------------
-- 1. Open up SQL Server 2012 Management Studio 
-- Version 1 A simple insert stored procedure
USE TSQL2012;
GO
IF OBJECT_ID('Production.InsertProducts', 'P') IS NOT NULL 
  DROP PROCEDURE Production.InsertProducts
GO
CREATE PROCEDURE Production.InsertProducts
  @productname AS NVARCHAR(40) 
  , @supplierid AS INT 
  , @categoryid AS INT 
  , @unitprice AS MONEY = 0
  , @discontinued AS BIT = 0
AS
BEGIN
  INSERT Production.Products (productname, supplierid, categoryid,
     unitprice, discontinued)
    VALUES (@productname, @supplierid, @categoryid, @unitprice,
       @discontinued);
  RETURN;
END;
GO

-- 2. To test the procedure, 
EXEC Production.InsertProducts
  @productname = 'Test Product' 
  , @supplierid = 10 
  , @categoryid = 1 
  , @unitprice  = 100
  , @discontinued = 0;
GO
-- Inspect the results
SELECT * FROM Production.Products WHERE productname = 'Test Product';
GO
-- Remove the new row
DELETE FROM Production.Products WHERE productname = 'Test Product';

-- 3. Now test the stored procedure with an invalid parameter value. 
EXEC Production.InsertProducts
  @productname = 'Test Product' 
  , @supplierid = 10
  , @categoryid = 1
  , @unitprice  = -100
  , @discontinued = 0

-- 4. Now add error handling
-- Version 2 with error handling
IF OBJECT_ID('Production.InsertProducts', 'P') IS NOT NULL 
  DROP PROCEDURE Production.InsertProducts
GO
CREATE PROCEDURE Production.InsertProducts
  @productname AS NVARCHAR(40) 
  , @supplierid AS INT 
  , @categoryid AS INT 
  , @unitprice AS MONEY = 0
  , @discontinued AS BIT = 0
AS
BEGIN
BEGIN TRY
  INSERT Production.Products (productname, supplierid, categoryid, 
    unitprice, discontinued)
  VALUES (@productname, @supplierid, @categoryid, 
    @unitprice, @discontinued);
END TRY
BEGIN CATCH
  THROW;
  RETURN;
END CATCH;
END;
GO

-- 5. Again, test the stored procedure with an invalid unitprice parameter
EXEC Production.InsertProducts
  @productname = 'Test Product' 
  , @supplierid = 10
  , @categoryid = 1 
  , @unitprice  = -100
  , @discontinued = 0

-- 6. Now, let's add parameter testing to the stored procedure. Load or key in the following
-- Version 3 With parameter testing
IF OBJECT_ID('Production.InsertProducts', 'P') IS NOT NULL 
  DROP PROCEDURE Production.InsertProducts
GO
CREATE PROCEDURE Production.InsertProducts
  @productname AS NVARCHAR(40) 
  , @supplierid AS INT 
  , @categoryid AS INT 
  , @unitprice AS MONEY = 0
  , @discontinued AS BIT = 0
AS
BEGIN
  DECLARE @ClientMessage NVARCHAR(100);
  BEGIN TRY
    -- Test parameters
    IF NOT EXISTS(SELECT 1 FROM Production.Suppliers 
      WHERE supplierid = @supplierid)
      BEGIN
        SET @ClientMessage = 'Supplier id ' 
            + CAST(@supplierid AS VARCHAR) + ' is invalid';
        THROW 50000, @ClientMessage, 0;
      END
    IF NOT EXISTS(SELECT 1 FROM Production.Categories 
        WHERE categoryid = @categoryid)
      BEGIN
        SET @ClientMessage = 'Category id ' 
           + CAST(@categoryid AS VARCHAR) + ' is invalid';
        THROW 50000, @ClientMessage, 0;
      END;
    IF NOT(@unitprice >= 0) 
      BEGIN
        SET @ClientMessage = 'Unitprice ' 
          + CAST(@unitprice AS VARCHAR) + ' is invalid. Must be >= 0.';
        THROW 50000, @ClientMessage, 0;
      END;
    -- Perform the insert
    INSERT Production.Products (productname, supplierid, categoryid, 
      unitprice, discontinued)
    VALUES (@productname, @supplierid, @categoryid, @unitprice, @discontinued);
  END TRY
  BEGIN CATCH
    THROW;
  END CATCH;
END;
GO

-- 7. Test the stored procedure with a unitprice parameter out of range
EXEC Production.InsertProducts
  @productname = 'Test Product' 
  , @supplierid = 10
  , @categoryid = 1
  , @unitprice  = -100
  , @discontinued = 0

-- 8. Test the stored procedure with a different invalid parameter, in this case an invalid supplierid:
EXEC Production.InsertProducts
  @productname = 'Test Product' 
  , @supplierid = 100
  , @categoryid = 1
  , @unitprice  = 100
  , @discontinued = 0


---------------------------------------------------------------------
-- Lesson 2: Implementing Triggers
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice: Writing DML Triggers
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Inspecting the Inserted and Deleted tables
---------------------------------------------------------------------
-- 1. First recreate the trigger on the Sales.SalesOrderDetails table as follows.
USE TSQL2012;
GO
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
-- 2.	First ensure that some selected data values can be entered. 
DELETE FROM  Sales.OrderDetails 
WHERE orderid = 10249 and productid in (15, 16);
GO

-- 3. Now add some data to the table. 
INSERT INTO Sales.OrderDetails (orderid,productid,unitprice,qty,discount)
	VALUES (10249, 16, 9.00, 1, 0.60) , 
	(10249, 15, 9.00, 1, 0.40); 
GO

-- 4. Now update one of those two rows. 
UPDATE Sales.OrderDetails
	SET unitprice = 99
	WHERE orderid = 10249 AND productid = 16;
GO

-- 5. Now delete those two rows. 
DELETE FROM  Sales.OrderDetails 
WHERE orderid = 10249 and productid in (15, 16);

-- 6. Finally, drop the trigger:
IF OBJECT_ID('Sales.tr_SalesOrderDetailsDML', 'TR') IS NOT NULL
	DROP TRIGGER Sales.tr_SalesOrderDetailsDML;
GO

---------------------------------------------------------------------
-- Exercise 2 - Write an AFTER trigger to enforce a business rule
---------------------------------------------------------------------
-- 1.	You need to write a trigger 
USE TSQL2012;
GO
-- Step 1: Basic trigger
IF OBJECT_ID('Sales.OrderDetails_AfterTrigger', 'TR') IS NOT NULL
	DROP Trigger Sales.OrderDetails_AfterTrigger;
GO
CREATE TRIGGER Sales.OrderDetails_AfterTrigger ON Sales.OrderDetails
AFTER INSERT, UPDATE
AS
BEGIN
  IF @@ROWCOUNT = 0 RETURN;
  SET NOCOUNT ON;
  -- Perform the check
  DECLARE @unitprice AS money, @discount AS NUMERIC(4,3);
  SELECT @unitprice = unitprice FROM inserted;
  SELECT @discount = discount FROM inserted;
  IF @unitprice < 10 AND @discount > .5
    BEGIN
      THROW 50000, 'Discount must be <= .5 when unitprice < 10', 0;
    END;
END;
GO

-- 2. Next, test the trigger with two rows. 
INSERT INTO Sales.OrderDetails (orderid,productid,unitprice,qty,discount)
	VALUES (10249, 16, 9.00, 1, 0.60) , 
	(10249, 15, 9.00, 1, 0.40);  


--3. Now try the same insert with the order of the rows reversed. This time the violating row is not found:
INSERT INTO Sales.OrderDetails (orderid,productid,unitprice,qty,discount)
  	VALUES (10249, 15, 9.00, 1, 0.40), 
	(10249, 16, 9.00, 1, 0.60) ; 

-- 4. Delete the wrongly inserted rows:
DELETE FROM Sales.OrderDetails WHERE orderid = 10249 AND productid IN (15, 16);
GO

-- 5. Now revise the trigger to capture and test all the rows:
IF OBJECT_ID('Sales.OrderDetails_AfterTrigger', 'TR') IS NOT NULL
	DROP Trigger Sales.OrderDetails_AfterTrigger;
GO
CREATE TRIGGER Sales.OrderDetails_AfterTrigger ON Sales.OrderDetails
AFTER INSERT, UPDATE
AS
BEGIN
  IF @@ROWCOUNT = 0 RETURN;
  SET NOCOUNT ON;
  -- Check all rows
  IF EXISTS(SELECT * FROM inserted AS I WHERE unitprice < 10 AND discount > .5)
    BEGIN
      THROW 50000, 'Discount must be <= .5 when unitprice < 10', 0;
    END
END
GO

-- 6. Re-run the same test with multiple rows:
INSERT INTO Sales.OrderDetails (orderid,productid,unitprice,qty,discount)
  	VALUES (10249, 15, 9.00, 1, 0.40), 
	(10249, 16, 9.00, 1, 0.60) ; 
-- 7. Now the trigger should capture the violating row or rows no matter how many rows you insert or update.

-- 8. As a last step, drop the trigger:
IF OBJECT_ID('Sales.OrderDetails_AfterTrigger', 'TR') IS NOT NULL
	DROP Trigger Sales.OrderDetails_AfterTrigger;
GO


---------------------------------------------------------------------
-- Lesson 3: Implementing User-Defined Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice: Writing User-Defined Functions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Writing a Scalar UDF to compute a discounted cost
---------------------------------------------------------------------
-- 1.	Start by writing a query to determine the cost of an item after applying the discount. The Sales.SalesOrder table has two columns used in the computation: unitprice (the price per unit), and qty (the number of units sold). 
SELECT orderid
  , productid
  , unitprice
  , qty
  , discount
FROM Sales.OrderDetails;

-- 2.	The product of these two is the extended cost
SELECT orderid
  , productid
  , unitprice
  , qty
  , discount
  , unitprice * qty AS totalcost 
FROM Sales.OrderDetails

-- 3.	The discount is a fraction
SELECT orderid
  , productid
  , unitprice
  , qty
  , discount
  , unitprice * qty as totalcost 
  , (unitprice * qty) * (1 - discount) as costafterdiscount
FROM Sales.OrderDetails;

-- 4.	Now you have enough to insert this into a function. The function only needs two parameters: unitprice and qty:
IF OBJECT_ID('Sales.fn_CostAfterDiscount', 'FN') IS NOT NULL
  DROP FUNCTION Sales.fn_CostAfterDiscount;
GO
CREATE FUNCTION Sales.fn_CostAfterDiscount(
  @unitprice AS MONEY,
  @qty AS SMALLINT,
  @discount AS NUMERIC(4,3)
) RETURNS MONEY
AS
BEGIN
  RETURN (@unitprice * @qty) * (1 - @discount);
END;
GO 

-- 5.	Now inspect the results:
SELECT Orderid
  , unitprice
  , qty
  , discount
  , Sales.fn_CostAfterDiscount(unitprice, qty, discount) AS costafterdiscount 
FROM Sales.OrderDetails;
6.	Save this function for the next exercise. If you are not doing Exercise 2 right away, you can use the following code to drop the function:
IF OBJECT_ID('Sales.fn_CostAfterDiscount', 'FN') IS NOT NULL
  DROP FUNCTION Sales.fn_CostAfterDiscount;
GO

---------------------------------------------------------------------
-- Exercise 2 - Creating Table-Valued UDFs
---------------------------------------------------------------------

-- 1.	You must write a function that will return a table of the Sales.OrderDetails rows
SELECT orderid, unitprice, qty, (unitprice * qty) AS extension
  FROM Sales.OrderDetails;

-- 2.	To add the filter, you could use a couple variables:
DECLARE @lowqty AS SMALLINT = 10
  , @highqty AS SMALLINT = 20;
SELECT orderid, unitprice, qty, (unitprice * qty) AS extension
FROM Sales.OrderDetails
WHERE qty BETWEEN @lowqty AND @highqty;

-- 3.	Now you have enough for the function. Start with the Management Studio snippet for an inline table-valued function:
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

-- 4.	Use the variable as the parameters, and assign the name fn_FilteredExtension. Remember to remove the assigned values from the variables when making them parameters.
IF OBJECT_ID('Sales.fn_FilteredExtension', 'FN') IS NOT NULL
  DROP FUNCTION Sales.fn_FilteredExtension;
GO
CREATE FUNCTION Sales.fn_FilteredExtension
(
  @lowqty AS SMALLINT,
  @highqty AS SMALLINT
 )
RETURNS TABLE AS RETURN
(
    SELECT orderid, unitprice, qty, (unitprice * qty) AS extension
	FROM Sales.OrderDetails
	WHERE qty BETWEEN @lowqty AND @highqty
);
GO

-- 5.	Now test the function:
SELECT *
FROM Sales.fn_FilteredExtension (10,20);
-- 6. Finally, drop the function:
IF OBJECT_ID('Sales.fn_FilteredExtension', 'FN') IS NOT NULL
  DROP FUNCTION Sales.fn_FilteredExtension;
GO

