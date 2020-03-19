--SELECT
--[CustomerID],
--SUM(CASE WHEN   [ShipMethodID] = 1 THEN  freight END) AS freight1, 
--MAX(CASE WHEN   [ShipMethodID] = 1 THEN  [CurrencyRateID] END) AS  [CurrencyRateID1],
--SUM(CASE WHEN   [ShipMethodID] = 2 THEN  freight END) AS freight2, 
--MAX(CASE WHEN   [ShipMethodID] = 2 THEN  [CurrencyRateID] END) AS  [CurrencyRateID2],
--SUM(CASE WHEN   [ShipMethodID] = 3 THEN  freight END) AS freight3, 
--MAX(CASE WHEN   [ShipMethodID] = 3 THEN  [CurrencyRateID] END) AS  [CurrencyRateID3]        
--FROM [AdventureWorks2012].[Sales].[SalesOrderHeader]
--GROUP BY  [CustomerID]

;WITH PivotData AS
(
       SELECT
              [CustomerID], -- grouping column
              [ShipMethodID], -- spreading column
			  [ShipMethodID]+1000 as   [ShipMethodID2],
              freight -- aggregation column
			  ,CurrencyRateID
         FROM [AdventureWorks2012].[Sales].[SalesOrderHeader]
)
SELECT [CustomerID], [1], [2], [3], [1001],[1002],[1003]
FROM PivotData
       PIVOT (SUM(freight) FOR [ShipMethodID] IN ([1],[2],[3])) AS P1
	   PIVOT ( COUNT(CurrencyRateID) FOR [ShipMethodID2] IN ([1001],[1002],[1003])) AS P2