
/*########################
# OBS: Create overlapping indexes
*/
USE [WideWorldImporters];
GO

CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_ExamBook762Ch4_A]
ON [Sales].[Invoices]
(
    [CustomerID],
    [InvoiceDate]
)
INCLUDE ([TotalDryItems]);

CREATE NONCLUSTERED INDEX [IX_Sales_Invoices_ExamBook762Ch4_B]
ON [Sales].[Invoices]
(
    [CustomerID],
    [InvoiceDate],
    [CustomerPurchaseOrderNumber]
)
INCLUDE ([TotalDryItems]);
GO


GO

USE [WideWorldImporters];
;WITH IndexColumns
AS (SELECT '[' + s.name + '].[' + t.name + ']' AS TableName,
           ix.name AS IndexName,
           c.name AS ColumnName,
           ix.index_id,
           ixc.index_column_id,
           COUNT(*) OVER (PARTITION BY t.object_id, ix.index_id) AS ColumnCount
    FROM sys.schemas AS s
        INNER JOIN sys.tables AS t
            ON t.schema_id = s.schema_id
        INNER JOIN sys.indexes AS ix
            ON ix.object_id = t.object_id
        INNER JOIN sys.index_columns AS ixc
            ON ixc.object_id = ix.object_id
               AND ixc.index_id = ix.index_id
        INNER JOIN sys.columns AS c
            ON c.object_id = ixc.object_id
               AND c.column_id = ixc.column_id
    WHERE ixc.is_included_column = 0
          AND LEFT(ix.name, 2)NOT IN ( 'PK', 'UQ', 'FK' )
   )
SELECT DISTINCT
    ix1.TableName,
    ix1.IndexName AS Index1,
    ix2.IndexName AS Index2
FROM IndexColumns AS ix1
    INNER JOIN IndexColumns AS ix2
        ON ix1.TableName = ix2.TableName
           AND ix1.IndexName <> ix2.IndexName
           AND ix1.index_column_id = ix2.index_column_id
           AND ix1.ColumnName = ix2.ColumnName
           AND ix1.index_column_id < 3
           AND ix1.index_id < ix2.index_id
           AND ix1.ColumnCount <= ix2.ColumnCount
ORDER BY ix1.TableName,
         ix2.IndexName;