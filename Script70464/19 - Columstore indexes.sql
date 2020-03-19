-- View Logical Reads for a Query
USE AdventureWorksDW
GO

-- Execute the query once to get data into cache
SELECT p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear,
		AVG(fpi.UnitCost),
		SUM(fpi.UnitsOut)
FROM dbo.FactProductInventory as fpi
INNER JOIN dbo.DimProduct as p ON
fpi.ProductKey = p.ProductKey
INNER JOIN dbo.DimDate as d ON
fpi.DateKey = d.DateKey
GROUP BY p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear
ORDER BY p.EnglishProductName,
		d.CalendarYear,
		d.WeekNumberOfYear


-- Now execute and log statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear,
		AVG(fpi.UnitCost),
		SUM(fpi.UnitsOut)
FROM dbo.FactProductInventory as fpi
INNER JOIN dbo.DimProduct as p ON
fpi.ProductKey = p.ProductKey
INNER JOIN dbo.DimDate as d ON
fpi.DateKey = d.DateKey
GROUP BY p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear
ORDER BY p.EnglishProductName,
		d.CalendarYear,
		d.WeekNumberOfYear

-- Create a non-clustered columnstore index
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO
USE AdventureWorksDW
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [IX_NCS_FactProductInventory]
ON dbo.FactProductInventory
(
	ProductKey,
	DateKey,
	UnitCost,
	UnitsIn,
	UnitsOut,
	UnitsBalance
);


-- Try to insert a row (this will fail)
INSERT INTO dbo.FactProductInventory
VALUES (214, 20101231, '2010-12-31', 9.54, 2, 0, 4);

-- Now execute and log statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear,
		AVG(fpi.UnitCost),
		SUM(fpi.UnitsOut)
FROM dbo.FactProductInventory as fpi
INNER JOIN dbo.DimProduct as p ON
fpi.ProductKey = p.ProductKey
INNER JOIN dbo.DimDate as d ON
fpi.DateKey = d.DateKey
GROUP BY p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear
ORDER BY p.EnglishProductName,
		d.CalendarYear,
		d.WeekNumberOfYear

-- On the Messages tab, note the elapsed time in the last line of the statistics report

-- Drop the non-clustered columnstore index, existing clustered index, and foreign keys
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO
DROP INDEX [IX_NCS_FactProductInventory] ON [dbo].[FactProductInventory];
GO
ALTER TABLE dbo.FactProductInventory DROP CONSTRAINT PK_FactProductInventory
GO
ALTER TABLE [dbo].[FactProductInventory] DROP CONSTRAINT [FK_FactProductInventory_DimDate];
GO
ALTER TABLE [dbo].[FactProductInventory] DROP CONSTRAINT [FK_FactProductInventory_DimProduct];
GO


-- Create a clustered columnstore index
CREATE CLUSTERED COLUMNSTORE INDEX [IX_CS_FactProductInventory]
ON dbo.FactProductInventory;

-- Insert a row
INSERT INTO dbo.FactProductInventory
VALUES (214, 20101231, '2010-12-31', 9.54, 2, 0, 4);


-- Now execute and log statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear,
		AVG(fpi.UnitCost),
		SUM(fpi.UnitsOut)
FROM dbo.FactProductInventory as fpi
INNER JOIN dbo.DimProduct as p ON
fpi.ProductKey = p.ProductKey
INNER JOIN dbo.DimDate as d ON
fpi.DateKey = d.DateKey
GROUP BY p.EnglishProductName,
		d.WeekNumberOfYear,
		d.CalendarYear
ORDER BY p.EnglishProductName,
		d.CalendarYear,
		d.WeekNumberOfYear

-- On the Messages tab, note the elapsed time in the last line of the statistics report


 