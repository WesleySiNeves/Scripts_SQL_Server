
/*########################
# OBS: Criando um type em memory
*/

CREATE TYPE [RetornoTotalOrcado] AS TABLE
(
    [OrderQty] [SMALLINT] NOT NULL,
    [ProductID] [INT] NOT NULL,
    [SpecialOfferID] [INT] NOT NULL,
    [LocalID] [INT] NOT NULL,
    INDEX [IX_ProductID] HASH ([ProductID]) WITH (BUCKET_COUNT = 8),
    INDEX [IX_SpecialOfferID] NONCLUSTERED ([OrderQty])
)
WITH (MEMORY_OPTIMIZED = ON);



/*########################
# OBS: Configure delayed durability
--Set no nível do banco de dados apenas, todas as transações confirmadas como atrasado durável
*
*/
ALTER DATABASE ExamBook762Ch3_IMOLTP SET DELAYED_DURABILITY = FORCED;


--Override database delayed durability at commit for durable transaction
BEGIN TRANSACTION;
INSERT INTO Examples.Order_IM_Hash
(OrderId, OrderDate, CustomerCode)
VALUES (1, getdate(), 'cust1');
COMMIT TRANSACTION WITH (DELAYED_DURABILITY = OFF);
GO


--Set at transaction level only
ALTER DATABASE ExamBook762Ch3_IMOLTP SET DELAYED_DURABILITY = ALLOWED;
BEGIN TRANSACTION;
INSERT INTO Examples.Order_IM_Hash
(
    OrderId,
    OrderDate,
    CustomerCode
)
VALUES
(2, GETDATE(), 'cust2');
COMMIT TRANSACTION WITH (DELAYED_DURABILITY = ON);



GO


--Set within a natively compiled stored procedure
CREATE PROCEDURE Examples.OrderInsert_NC_DD
    @OrderID INT,
    @CustomerCode NVARCHAR(10)
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (DELAYED_DURABILITY = ON, TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English')
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



--Disable delayed durability completely for all transactions
-- and natively compiled stored procedures
ALTER DATABASE ExamBook762Ch3_IMOLTP SET DELAYED_DURABILITY = DISABLED;