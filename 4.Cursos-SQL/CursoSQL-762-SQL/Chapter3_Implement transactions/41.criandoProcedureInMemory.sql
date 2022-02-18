USE ExamBook762Ch3_IMOLTP;
GO

CREATE PROCEDURE Examples.OrderInsert_NC
    @OrderID INT,
    @CustomerCode NVARCHAR(10)
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English')
    DECLARE @OrderDate DATETIME = GETDATE();
    INSERT INTO Examples.Order_IM
    (
        OrderId,
        OrderDate,
        CustomerCode
    )
    VALUES
    (@OrderID, @OrderDate, @CustomerCode);
END;
GO


/*########################
# OBS: Criando Procedures Normal
*/



-- Create interpreted stored procedure
CREATE PROCEDURE Examples.OrderInsert_Interpreted
    @OrderID INT,
    @CustomerCode NVARCHAR(10),
    @TargetTable NVARCHAR(20)
AS
DECLARE @OrderDate DATETIME = GETDATE();
DECLARE @SQLQuery NVARCHAR(MAX);
SET @SQLQuery
    = 'INSERT INTO ' + @TargetTable + ' (OrderId, OrderDate, CustomerCode) VALUES (' + CAST(@OrderID AS NVARCHAR(6))
      + ',''' + CONVERT(NVARCHAR(20), @OrderDate, 101) + ''',''' + @CustomerCode + ''')';
EXEC (@SQLQuery);
GO



/*########################
# OBS: rode o Script abaixo para teste
*/


SET STATISTICS TIME OFF;
SET NOCOUNT ON;
DECLARE @starttime DATETIME = SYSDATETIME();
DECLARE @timems INT;
DECLARE @i INT = 1;
DECLARE @rowcount INT = 1000;
DECLARE @CustomerCode NVARCHAR(10);
--Reset disk-based table
TRUNCATE TABLE Examples.Order_Disk;
-- Disk-based table and interpreted stored procedure
BEGIN TRAN;
WHILE @i <= @rowcount
BEGIN;
    SET @CustomerCode = 'cust' + CAST(@i AS NVARCHAR(6));
    EXEC Examples.OrderInsert_Interpreted @i,
                                          @CustomerCode,
                                          'Examples.Order_Disk';
    SET @i += 1;
END;
COMMIT;
SET @timems = DATEDIFF(ms, @starttime, SYSDATETIME());
SELECT 'Disk-based table and interpreted stored procedure: ' AS [Description],
       CAST(@timems AS NVARCHAR(10)) + ' ms' AS Duration;
-- Memory-based table and interpreted stored procedure
SET @i = 1;
SET @starttime = SYSDATETIME();
BEGIN TRAN;
WHILE @i <= @rowcount
BEGIN;
    SET @CustomerCode = 'cust' + CAST(@i AS NVARCHAR(6));
    EXEC Examples.OrderInsert_Interpreted @i,
                                          @CustomerCode,
                                          'Examples.Order_IM';
    SET @i += 1;
END;
COMMIT;
SET @timems = DATEDIFF(ms, @starttime, SYSDATETIME());
SELECT 'Memory-optimized table and interpreted stored
procedure: ' AS [Description],
CAST(@timems AS NVARCHAR(10)) + ' ms' AS Duration;
-- Reset memory-optimized table


DELETE FROM Examples.Order_IM;
SET @i = 1;
SET @starttime = SYSDATETIME();
BEGIN TRAN;
WHILE @i <= @rowcount
BEGIN;
    SET @CustomerCode = 'cust' + CAST(@i AS NVARCHAR(6));
    EXEC Examples.OrderInsert_NC @i, @CustomerCode;
    SET @i += 1;
END;
COMMIT;
SET @timems = DATEDIFF(ms, @starttime, SYSDATETIME());
SELECT 'Memory-optimized table and natively compiled stored
procedure:' AS [Description],
CAST(@timems AS NVARCHAR(10)) + ' ms' AS Duration;
GO





INSERT INTO Examples.Order_IM
(
    OrderID,
    OrderDate,
    CustomerCode
)
VALUES
(   0,         -- OrderID - int
    GETDATE(), -- OrderDate - datetime
    N''        -- CustomerCode - nvarchar(5)
)





SET STATISTICS IO ON 
SET STATISTICS TIME ON 
SELECT * FROM Examples.Order_Disk AS OD

SELECT * FROM Examples.Order_IM AS OI

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
 

 
 /*
 MEMORY_OPTIMIZED
Aplica-se a: SQL Server 2014 a SQL Server 2017 e Banco de dados SQL do Azure.

BUCKET_COUNT
Aplica-se a: SQL Server 2014 a SQL Server 2017 e Banco de dados SQL do Azure.

Indica o número de buckets que devem ser criados no índice de hash. O valor máximo para BUCKET_COUNT em índices de hash é 1.073.741.824. Para obter mais informações sobre o número de buckets, veja Índices para tabelas com otimização de memória. bucket_count é um argumento obrigatório.

HASH
Aplica-se a: SQL Server 2014 a SQL Server 2017 e Banco de dados SQL do Azure.
 */
 CREATE TYPE [RetornoTotalOrcado] AS TABLE(  
  [OrderQty] [smallint] NOT NULL,  
  [ProductID] [int] NOT NULL,  
  [SpecialOfferID] [int] NOT NULL,  
  [LocalID] [int] NOT NULL,  
  
  INDEX [IX_ProductID] HASH ([ProductID]) WITH ( BUCKET_COUNT = 8),  
  INDEX [IX_SpecialOfferID] NONCLUSTERED( [OrderQty]) 
)  
WITH ( MEMORY_OPTIMIZED = ON )  
