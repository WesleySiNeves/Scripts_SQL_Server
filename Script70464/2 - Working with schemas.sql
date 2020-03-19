

-- Demonstration 2 - Working with Schemas

-- Step 1: Open a query window to the tempdb database


-- Step 2: Create a schema



DROP TABLE IF EXISTS Flights

DROP TABLE IF EXISTS Reporting.Flights

DROP SCHEMA IF EXISTS Reporting

DROP TABLE IF EXISTS Operations.Flights

 
DROP TABLE IF EXISTS Flights

DROP SCHEMA IF EXISTS Operations
GO


CREATE SCHEMA Reporting AUTHORIZATION dbo;
GO

-- Step 3: Create a schema with an included object
CREATE SCHEMA Operations AUTHORIZATION dbo

  CREATE TABLE Flights (FlightID int IDENTITY(1,1) PRIMARY KEY,
                        Origin nvarchar(3),
                        Destination nvarchar(3));
GO

-- Step 4: Use object explorer to work out which schema 
--         the table has been created in

  CREATE TABLE Operations.Flights (FlightID int IDENTITY(1,1) PRIMARY KEY,
                        Origin nvarchar(3),
                        Destination nvarchar(3));

-- Step 5: Drop the table

DROP TABLE Operations.Flights;

DROP TABLE Flights;

GO

-- Step 6: Drop the schema
DROP SCHEMA Operations;
GO



-- Step 7: Use the same syntax but execute each part of the 
--         statement separately

CREATE SCHEMA Operations AUTHORIZATION dbo


CREATE TABLE Flights (FlightID int IDENTITY(1,1) PRIMARY KEY,
                      Origin nvarchar(3),
                      Destination nvarchar(3));

-- Step 8: Again, use object explorer to work out which schema 
--         the table has been created in


-- Step 9: Create the same table in a different schema
CREATE TABLE Reporting.Flights (FlightID int IDENTITY(1,1) PRIMARY KEY,
                      Origin nvarchar(3),
                      Destination nvarchar(3));


SELECT * FROM Flights

SELECT * FROM Reporting.Flights