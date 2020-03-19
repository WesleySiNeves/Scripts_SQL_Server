---------------------------------------------------------------------
-- TK 70-461 - Chapter 12 - Implementing Transactions, Error Handling and Dynamic SQL
-- Code
---------------------------------------------------------------------

USE TSQL2012;
GO
SET NOCOUNT ON;
GO

---------------------------------------------------------------------
-- Lesson 01 - Lesson 1: Managing Transactions and Concurrency
---------------------------------------------------------------------

-- Implicit Transactions
SET IMPLICIT_TRANSACTIONS ON;
-- You can also issue the command:
SET ANSI_DEFAULTS ON;
-- This command just effectively issues the first command for you.

USE TSQL2012;
BEGIN TRANSACTION Tran1;
ROLLBACK TRAN;

-- Mark a Transaction
USE TSQL2012;
BEGIN TRAN Tran1 WITH MARK;
	-- <transaction work>
COMMIT TRAN; -- or ROLLBACK TRAN
-- <other work>

-- Later, supposing you need to restore the database to the transaction mark:
RESTORE DATABASE TSQ2012 FROM DISK = 'C:SQLBackups\TSQL2012.bak'
	WITH NORECOVERY;
GO
RESTORE LOG TSQL2012 FROM DISK = 'C:\SQLBackups\TSQL2012.trn'
	WITH STOPATMARK = 'Tran1';
GO


---------------------------------------------------------------------
-- Lesson 02 - Lesson 2: Implementing Error Handling
---------------------------------------------------------------------

RAISERROR ('Error in usp_InsertCategories stored procedure', 16, 0);

-- Formatting the RAISERROR string
RAISERROR ('Error in % stored procedure', 16, 0, N'usp_InsertCategories');

-- In addition, you can use a variable: 
GO
DECLARE @message AS NVARCHAR(1000) = N'Error in % stored procedure';
RAISERROR (@message, 16, 0, N'usp_InsertCategories');

-- And you can add the formatting outside RAISERROR using the FORMATMESSAGE function:
GO
DECLARE @message AS NVARCHAR(1000) = N'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
RAISERROR (@message, 16, 0);

-- THROW and RAISERROR
-- You can issue a simple THROW as follows:
THROW 50000, 'Error in usp_InsertCategories stored procedure', 0;

-- Because THROW does not allow formatting of the message parameter, you can use FORMATMESSAGE()
GO
DECLARE @message AS NVARCHAR(1000) = N'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
THROW 50000, @message, 0;

-- There are some additional important differences between THROW and RAISERROR:
-- RAISERROR does not normally terminate a batch:
RAISERROR ('Hi there', 16, 0);
PRINT 'RAISERROR error'; -- Prints
GO

-- However, THROW does terminate the batch:
THROW 50000, 'Hi there', 0;
PRINT 'THROW error'; -- Does not print
GO

-- TRY_CONVERT()
-- The first statement returns a NULL, signaling that the conversion will not work. 
-- The second statement returns the converted datetime value as a datetime data type. 
SELECT TRY_CONVERT(DATETIME, '1752-12-31');
SELECT TRY_CONVERT(DATETIME, '1753-01-01');

-- TRY_PARSE() allows you to take an input string containing data of an indeterminate data type and test whether or not it can be converted to a specific data type. 
-- The following example attempts to parse two strings:
SELECT TRY_PARSE('1' AS INTEGER);
SELECT TRY_PARSE('B' AS INTEGER);


-- Calling the error functions from the CATCH block:
BEGIN CATCH
	-- Error handling
	SELECT ERROR_NUMBER() AS errornumber
		, ERROR_MESSAGE() AS errormessage
		, ERROR_LINE() AS errorline
		, ERROR_SEVERITY() AS errorseverity
		, ERROR_STATE() AS errorstate;
END CATCH;

---------------------------------------------------------------------
-- Lesson 03 - Lesson 3: Using Dynamic SQL
---------------------------------------------------------------------

-- Dynamic SQL Overview
-- Sample query:
USE TSQL2012;
GO
SELECT COUNT(*) AS ProductRowCount  FROM [Production].[Products];

-- Now suppose you want to substitute a variable for the table and schema name:
USE TSQL2012;
GO
DECLARE @tablename  AS NVARCHAR(261) = N'[Production].[Products]';
SELECT COUNT(*) FROM @tablename;

-- But concatenate that variable with a string literal, and you can print out the command:
USE TSQL2012;
GO
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
PRINT N'SELECT COUNT(*) FROM ' + @tablename;

-- Or you can use the SELECT statement to get the same effect but in a result set:
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
SELECT N'SELECT COUNT(*) FROM ' + @tablename;

-- In each case, the result is valid T-SQL:
SELECT COUNT(*) AS ProductRowCount FROM [Production].[Products];

-- You can copy this to a query window and execute it manually, 
-- or you can embed it and execute it immediately using the EXECUTE command 
DECLARE @tablename AS NVARCHAR(261) = N'[Production].[Products]';
EXECUTE(N'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename);


-- Embedded strings and string delimiters
-- Notice the embedded single quote (apostrophe):
USE TSQL2012;
GO
SELECT custid, companyname, contactname, contacttitle, address
 FROM [Sales].[Customers]
WHERE address = N'5678 rue de l'Abbaye ';


-- Embed a second single quote to signal a single quote and not a string delimiter:
SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = N'5678 rue de l''Abbaye';


-- Using a PRINT statement
PRINT N'SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = N''5678 rue de l''''Abbaye'';';

-- An alternative is to use the QUOTENAME function
PRINT QUOTENAME(N'5678 rue de l''Abbaye', '''');

-- Using the EXECUTE command:
-- Executing a string variable:
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000)
	, @tablename AS NVARCHAR(261) = '[Production].[Products]';
SET @SQLString = N'SELECT COUNT(*) AS TableRowCount FROM ' + @tablename;
EXEC(@SQLString);

-- Executing concatenated variables.
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(MAX)
	, @tablename AS NVARCHAR(261) = '[Production].[Products]';
SET @SQLString = N'SELECT COUNT(*) AS TableRowCount FROM ' 
EXEC(@SQLString + @tablename);

-- Using sp_executesql
-- Sending the input in as a parameter
USE TSQL2012;
GO
DECLARE @SQLString AS NVARCHAR(4000), @address AS NVARCHAR(60);
SET @SQLString = N'
SELECT custid, companyname, contactname, contacttitle, address
FROM [Sales].[Customers]
WHERE address = @address';
SET @address = N'5678 rue de l''Abbaye'; 
EXEC sp_executesql 
	@statement = @SQLString
	, @params = N'@address NVARCHAR(60)'
	, @address = @address;

