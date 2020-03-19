---------------------------------------------------------------------
-- TK 70-461 - Chapter 16 - Understanding Cursors, Sets and Temporary Tables
-- Code
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Evaluating the Use of Cursor/Iterative Solutions vs. Set-Based Solutions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- iterations for operations that have to be done per row
---------------------------------------------------------------------

-- procedure doing work for an input customer
USE TSQL2012;

IF OBJECT_ID(N'Sales.ProcessCustomer', N'P') IS NOT NULL
  DROP PROC Sales.ProcessCustomer;
GO

CREATE PROC Sales.ProcessCustomer
(
  @custid AS INT
)
AS

PRINT 'Processing customer ' + CAST(@custid AS VARCHAR(10));
GO

-- iterations with a cursor
SET NOCOUNT ON;

DECLARE @curcustid AS INT;

DECLARE cust_cursor CURSOR FAST_FORWARD FOR
  SELECT custid
  FROM Sales.Customers;

OPEN cust_cursor;

FETCH NEXT FROM cust_cursor INTO @curcustid;

WHILE @@FETCH_STATUS = 0
BEGIN
  EXEC Sales.ProcessCustomer @custid = @curcustid;

  FETCH NEXT FROM cust_cursor INTO @curcustid;
END;

CLOSE cust_cursor;

DEALLOCATE cust_cursor;
GO

-- iterations without a cursor
SET NOCOUNT ON;

DECLARE @curcustid AS INT;

SET @curcustid = (SELECT TOP (1) custid
                  FROM Sales.Customers
                  ORDER BY custid);

WHILE @curcustid IS NOT NULL
BEGIN
  EXEC Sales.ProcessCustomer @custid = @curcustid;
  
  SET @curcustid = (SELECT TOP (1) custid
                    FROM Sales.Customers
                    WHERE custid > @curcustid
                    ORDER BY custid);
END;
GO

---------------------------------------------------------------------
-- cursor vs. set-based solutions to data manipulation tasks
---------------------------------------------------------------------

-- definition of helper function GetNums
IF OBJECT_ID(N'dbo.GetNums', N'IF') IS NOT NULL DROP FUNCTION dbo.GetNums;
GO
CREATE FUNCTION dbo.GetNums(@low AS BIGINT, @high AS BIGINT) RETURNS TABLE
AS
RETURN
  WITH
    L0   AS (SELECT c FROM (VALUES(1),(1)) AS D(c)),
    L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
    L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
    L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
    L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
    L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
    Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
            FROM L5)
  SELECT @low + rownum - 1 AS n
  FROM Nums
  ORDER BY rownum
  OFFSET 0 ROWS FETCH FIRST @high - @low + 1 ROWS ONLY;
GO

-- create and populate table Transactions
IF OBJECT_ID(N'dbo.Transactions', N'U') IS NOT NULL DROP TABLE dbo.Transactions;

CREATE TABLE dbo.Transactions
(
  actid  INT   NOT NULL,                -- partitioning column
  tranid INT   NOT NULL,                -- ordering column
  val    MONEY NOT NULL,                -- measure
  CONSTRAINT PK_Transactions PRIMARY KEY(actid, tranid)
);

DECLARE
  @num_partitions     AS INT = 100,
  @rows_per_partition AS INT = 10000;

TRUNCATE TABLE dbo.Transactions;

INSERT INTO dbo.Transactions WITH (TABLOCK) (actid, tranid, val)
  SELECT NP.n, RPP.n,
    (ABS(CHECKSUM(NEWID())%2)*2-1) * (1 + ABS(CHECKSUM(NEWID())%5))
  FROM dbo.GetNums(1, @num_partitions) AS NP
    CROSS JOIN dbo.GetNums(1, @rows_per_partition) AS RPP;
GO

-- cursor solution for running totals (66 seconds)
DECLARE @Result AS TABLE
(
  actid   INT,
  tranid  INT,
  val     MONEY,
  balance MONEY
);

DECLARE
  @actid    AS INT,
  @prvactid AS INT,
  @tranid   AS INT,
  @val      AS MONEY,
  @balance  AS MONEY;

DECLARE C CURSOR FAST_FORWARD FOR
  SELECT actid, tranid, val
  FROM dbo.Transactions
  ORDER BY actid, tranid;

OPEN C

FETCH NEXT FROM C INTO @actid, @tranid, @val;

SELECT @prvactid = @actid, @balance = 0;

WHILE @@fetch_status = 0
BEGIN
  IF @actid <> @prvactid
    SELECT @prvactid = @actid, @balance = 0;

  SET @balance = @balance + @val;

  INSERT INTO @Result VALUES(@actid, @tranid, @val, @balance);
  
  FETCH NEXT FROM C INTO @actid, @tranid, @val;
END

CLOSE C;

DEALLOCATE C;

SELECT * FROM @Result;
GO

-- set-based solution for running totals using window functions (4 seconds)
SELECT actid, tranid, val,
  SUM(val) OVER(PARTITION BY actid
                ORDER BY tranid
                ROWS UNBOUNDED PRECEDING) AS balance
FROM dbo.Transactions;

-- set-based solution for running totals using joins (46 minutes, 53 seconds)
SELECT T1.actid, T1.tranid, T1.val,
  SUM(T2.val) AS balance
FROM dbo.Transactions AS T1
  JOIN dbo.Transactions AS T2
    ON T2.actid = T1.actid
   AND T2.tranid <= T1.tranid
GROUP BY T1.actid, T1.tranid, T1.val;

---------------------------------------------------------------------
-- Lesson 02 - Using Temporary Tables vs. Table Variables
---------------------------------------------------------------------

---------------------------------------------------------------------
-- scope
---------------------------------------------------------------------

-- temp table
CREATE TABLE #T1
(
  col1 INT NOT NULL
);

INSERT INTO #T1(col1) VALUES(10);

EXEC('SELECT col1 FROM #T1;');
GO

SELECT col1 FROM #T1;
GO

DROP TABLE #T1;
GO

-- table variable not visible in inner levels
DECLARE @T1 AS TABLE
(
  col1 INT NOT NULL
);

INSERT INTO @T1(col1) VALUES(10);

EXEC('SELECT col1 FROM @T1;');
GO

-- error
Msg 1087, Level 15, State 2, Line 1
Must declare the table variable "@T1".

-- table variable not visible across batches
DECLARE @T1 AS TABLE
(
  col1 INT NOT NULL
);

INSERT INTO @T1(col1) VALUES(10);
GO

SELECT col1 FROM @T1;
GO

-- error
Msg 1087, Level 15, State 2, Line 2
Must declare the table variable "@T1".

---------------------------------------------------------------------
-- DDL and indexes
---------------------------------------------------------------------

-- temp table: run from two sessions
CREATE TABLE #T1
(
  col1 INT  NOT NULL,
  col2 INT  NOT NULL,
  col3 DATE NOT NULL,
  CONSTRAINT PK_#T1 PRIMARY KEY(col1)
);

-- error in second
Msg 2714, Level 16, State 5, Line 1
There is already an object named 'PK_#T1' in the database.
Msg 1750, Level 16, State 0, Line 1
Could not create constraint. See previous errors.

-- cleanup in first
DROP TABLE #T1;

-- run from two sessions
CREATE TABLE #T1
(
  col1 INT  NOT NULL,
  col2 INT  NOT NULL,
  col3 DATE NOT NULL,
  PRIMARY KEY(col1)
);

-- can create indexes after the fact
CREATE UNIQUE NONCLUSTERED INDEX idx_col2 ON #T1(col2);

-- cleanup
DROP TABLE #T1;

-- table variable: not allowed to name constraints
DECLARE @T1 AS TABLE
(
  col1 INT  NOT NULL,
  col2 INT  NOT NULL,
  col3 DATE NOT NULL,
  CONSTRAINT PK_@T1 PRIMARY KEY(col1)
);

-- error
Msg 156, Level 15, State 2, Line 6
Incorrect syntax near the keyword 'CONSTRAINT'.

-- unnamed constraints
DECLARE @T1 AS TABLE
(
  col1 INT  NOT NULL,
  col2 INT  NOT NULL,
  col3 DATE NOT NULL,
  PRIMARY KEY(col1)
);

-- cannot create indexes after the fact
-- need to define constraints that create indexes
DECLARE @T1 AS TABLE
(
  col1 INT  NOT NULL,
  col2 INT  NOT NULL,
  col3 DATE NOT NULL,
  PRIMARY KEY(col1),
  UNIQUE(col2)
);

---------------------------------------------------------------------
-- physical representation in tempdb
---------------------------------------------------------------------

-- temp table
CREATE TABLE #T1
(
  col1 INT NOT NULL
);

INSERT INTO #T1(col1) VALUES(10);

SELECT name FROM tempdb.sys.objects WHERE name LIKE '#%';

DROP TABLE #T1;
GO

-- output
name
----------
#T1_________________________________________________________________________________________________________________000000000018

-- table variable
DECLARE @T1 AS TABLE
(
  col1 INT NOT NULL
);

INSERT INTO @T1(col1) VALUES(10);

SELECT name FROM tempdb.sys.objects WHERE name LIKE '#%';

-- output
name
----------
#BD095663

---------------------------------------------------------------------
-- transaction
---------------------------------------------------------------------

-- temp table
CREATE TABLE #T1
(
  col1 INT NOT NULL
);

BEGIN TRAN

  INSERT INTO #T1(col1) VALUES(10);

ROLLBACK TRAN

SELECT col1 FROM #T1;

DROP TABLE #T1;
GO

-- output
col1
-----------

-- table variable
DECLARE @T1 AS TABLE
(
  col1 INT NOT NULL
);

BEGIN TRAN

  INSERT INTO @T1(col1) VALUES(10);

ROLLBACK TRAN

SELECT col1 FROM @T1;

-- output
col1
-----------
10

---------------------------------------------------------------------
-- statistics
---------------------------------------------------------------------

-- to measure IO costs
SET STATISTICS IO ON;

-- temp table has histograms, 9 logical reads
CREATE TABLE #T1
(
  col1 INT  NOT NULL,
  col2 INT  NOT NULL,
  col3 DATE NOT NULL,
  PRIMARY KEY(col1),
  UNIQUE(col2)
);

INSERT INTO #T1(col1, col2, col3)
  SELECT n, n * 2, CAST(SYSDATETIME() AS DATE)
  FROM dbo.GetNums(1, 1000000);

SELECT col1, col2, col3
FROM #T1
WHERE col2 <= 5;

DROP TABLE #T1;
GO

-- table variable doesn't have histograms, 2485 logical reads
DECLARE @T1 AS TABLE
(
  col1 INT  NOT NULL,
  col2 INT  NOT NULL,
  col3 DATE NOT NULL,
  PRIMARY KEY(col1),
  UNIQUE(col2)
);

INSERT INTO @T1(col1, col2, col3)
  SELECT n, n * 2, CAST(SYSDATETIME() AS DATE)
  FROM dbo.GetNums(1, 1000000);

SELECT col1, col2, col3
FROM @T1
WHERE col2 <= 5;
GO

-- turn off IO costs
SET STATISTICS IO OFF;
