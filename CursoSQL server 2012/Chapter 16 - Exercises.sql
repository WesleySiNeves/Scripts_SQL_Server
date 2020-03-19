---------------------------------------------------------------------
-- TK 70-461 - Chapter 16 - Understanding Cursors, Sets and Temporary Tables
-- Exercises
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Lesson 01 - Evaluating the Use of Cursor/Iterative Solutions vs. Set-Based Solutions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Cursor-Based vs. Set-Based Solutions
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise - Computing an Aggregate
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Compute an Aggregate with a Cursor-Based Solution
---------------------------------------------------------------------

-- 2.

-- create an index to support the computation

USE TSQL2012;
CREATE INDEX idx_actid_val ON dbo.Transactions(actid, val);

-- 3.

-- write a cursor solution and measure it's performance
SET NOCOUNT ON;
DECLARE @Result AS TABLE
(
  actid INT,
  mx    MONEY
);

DECLARE
  @actid     AS INT,
  @val       AS MONEY,
  @prevactid AS INT,
  @prevval   AS MONEY;

DECLARE tx_cursor CURSOR FAST_FORWARD FOR
  SELECT actid, val
  FROM dbo.Transactions
  ORDER BY actid, val;

OPEN tx_cursor;

FETCH NEXT FROM tx_cursor INTO @actid, @val;

SELECT @prevactid = @actid, @prevval = @val;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @actid <> @prevactid
    INSERT INTO @Result(actid, mx)
      VALUES(@prevactid, @prevval);

  SELECT @prevactid = @actid, @prevval = @val;

  FETCH NEXT FROM tx_cursor INTO @actid, @val;
END

IF @prevactid IS NOT NULL
  INSERT INTO @Result(actid, mx)
    VALUES(@prevactid, @prevval);

CLOSE tx_cursor;

DEALLOCATE tx_cursor;

SELECT actid, mx
FROM @Result;
GO

---------------------------------------------------------------------
-- Exercise 2 - Compute an Aggregate with a Set-Based Solution
---------------------------------------------------------------------

-- 1.

-- write a set-based solution and measure it's performance
SELECT actid, MAX(val) AS mx
FROM dbo.Transactions
GROUP BY actid;

---------------------------------------------------------------------
-- Lesson 02 - Using Temporary Tables vs. Table Variables
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Practice - Choosing Optimal Temporary Object
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Exercise 1 - Compare Current Counts of Orders to Previous 
--              Yearly Counts of Orders Using CTEs
---------------------------------------------------------------------

USE TSQL2012;

-- 2.

-- a query returning yearly counts of orders
SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(orderdate);

-- 3.

-- handle the task using a CTE
WITH YearlyCounts AS
(
  SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
  FROM Sales.Orders
  GROUP BY YEAR(orderdate)
)
SELECT C.orderyear, C.numorders, C.numorders - P.numorders AS diff
FROM YearlyCounts AS C
  INNER JOIN YearlyCounts AS P
    ON C.orderyear = P.orderyear + 1;

---------------------------------------------------------------------
-- Exercise 2 - Compare Current Counts of Orders to Previous 
--              Yearly Counts of Orders Using a Table Variable
---------------------------------------------------------------------

--1.

-- using table variable or temp table expensive work done only once (think of a much bigger Orders table than in the sample database)
-- since result that needs to be persisted is so small, table variable would do

DECLARE @YearlyCounts AS TABLE
(
  orderyear INT NOT NULL,
  numorders INT NOT NULL,
  PRIMARY KEY(orderyear)
);

INSERT INTO @YearlyCounts(orderyear, numorders)
  SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
  FROM Sales.Orders
  GROUP BY YEAR(orderdate);

SELECT C.orderyear, C.numorders, C.numorders - P.numorders AS diff
FROM @YearlyCounts AS C
  INNER JOIN @YearlyCounts AS P
    ON C.orderyear = P.orderyear + 1;
