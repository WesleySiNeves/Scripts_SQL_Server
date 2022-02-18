-- Demonstration 3B

-- Step 1: Open a new query window to the tempdb database

USE peopleSQLNexus;
GO

-- Step 2: Create a temporary table

CREATE TABLE #People
( 
personid UNIQUEIDENTIFIER,
firstname VARCHAR(80),
lastname VARCHAR(80),
dob DATETIME,
dod DATETIME,
sex CHAR(1)
);
GO

-- Step 3: Populate the table

INSERT #People
SELECT TOP(250)*
FROM dbo.people



-- Step 4: Query the table and show actual row estimates

SELECT count(*) FROM #People;
GO

-- Step 5: Disconnect and reconnect 
--         (right-click the query window and choose Connection then Disconnect,
--          then right-click the query window and choose Connection then Connect,
--          in the Connect to Server window, click Connect)

-- Step 6: Attempt to query the table again (this will fail)

USE tempdb;
GO

SELECT count(*) FROM #People;
GO

DROP TABLE #People

-- Do the same with a Table Variable

USE peopleSQLNexus;

DECLARE @people TABLE 
( 
personid UNIQUEIDENTIFIER,
firstname VARCHAR(80),
lastname VARCHAR(80),
dob DATETIME,
dod DATETIME,
sex CHAR(1)
)
INSERT @people
SELECT *
FROM dbo.people


-- Now run the select. It will fail. Run it all as a batch
SELECT count(*) FROM @people
