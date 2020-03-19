-- Demonstration 14 - Scalar Function

-- Step 1 - Open a new query window against the tempdb database.

USE tempdb;
GO

-- Step 2 - Create a function
--          Note that SQL Server 2012 now includes a new function
--          for calculating the end of the current month (EOMONTH)

CREATE FUNCTION dbo.EndOfPreviousMonth (@DateToTest date)
RETURNS date
AS BEGIN
  RETURN DATEADD(day, 0 - DAY(@DateToTest), @DateToTest);
END;
GO

-- Step 3 - Query the function. The first query will return
--          the date of the end of last month. The second
--          query will return the date of the end of the
--          year 2009.

SELECT dbo.EndOfPreviousMonth(SYSDATETIME());
SELECT dbo.EndOfPreviousMonth('2010-01-01');
GO

-- Step 4 - Determine if the function is deterministic. The function
--          is not deterministic.

SELECT OBJECTPROPERTY(OBJECT_ID('dbo.EndOfPreviousMonth'),'IsDeterministic');
GO

-- Step 5 Question for students: SQL Server now includes
--        an EOMONTH function. How could you modify the function
--        above to use that new function?

-- Step 6 - Drop the function

DROP FUNCTION dbo.EndOfPreviousMonth;
GO

