USE WideWorldImporters
GO
/* ==================================================================
--Data: 29/08/2018 
--Autor :Wesley Neves
--Observação:  Aqui temos uma procedure que limpa o cache e volta os indices 
-- ==================================================================
*/

CREATE OR ALTER PROCEDURE Reinitialize
AS
BEGIN

    CREATE NONCLUSTERED INDEX [FK_Sales_InvoiceLines_InvoiceID]
    ON Sales.InvoiceLines ([InvoiceID])
    WITH (DROP_EXISTING = ON);

    CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_CustomerID]
    ON Sales.Invoices ([CustomerID])
    WITH (DROP_EXISTING = ON);



    DECLARE @db INT = (
                          SELECT DB_ID()
                      );
    DBCC Flushprocindb(@db)WITH NO_INFOMSGS;
	DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
	
END;

go

/* ==================================================================
--Data: 29/08/2018 
--Autor :Wesley Neves
--Observação: Demo 1
 
-- ==================================================================
*/

USE WideWorldImporters

DECLARE @customerIdMin INT = 800,@customerIdMax INT = 830

SELECT IL.StockItemID,
       IL.ExtendedPrice,
       I.CustomerID,
	   I.InvoiceID,
	   0- IL.Quantity,
	   I.InvoiceDate
  FROM Sales.InvoiceLines AS IL 
      JOIN Sales.Invoices AS I
          ON IL.InvoiceID = I.InvoiceID
 WHERE I.CustomerID >= @customerIdMin AND I.CustomerID <=@customerIdMax
 ORDER BY I.InvoiceID,IL.StockItemID
 


 /* ==================================================================
 --Data: 29/08/2018 
 --Autor :Wesley Neves
 --Observação: Apos alterações vistas no Sql Sentry One criamos o segunte indice
  ---Vamos executar novamente 
 -- ==================================================================
 */
IF EXISTS (
          SELECT 1
            FROM sys.indexes
           WHERE indexes.name = 'FK_Sales_InvoiceLines_InvoiceID'
                 AND indexes.object_id = OBJECT_ID('[WideWorldImporters].[Sales].[InvoiceLines]')
          )
BEGIN
    DROP INDEX [FK_Sales_InvoiceLines_InvoiceID]
    ON WideWorldImporters.Sales.InvoiceLines;
END;
GO

CREATE INDEX [FK_Sales_InvoiceLines_InvoiceID]
ON WideWorldImporters.Sales.InvoiceLines ([InvoiceID] ASC)
INCLUDE
(
[ExtendedPrice],
[Quantity],
[StockItemID]
);
GO


/*novamente fizemos uma alteração no indice e rodamos a consulta*/

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'FK_Sales_Invoices_CustomerID' AND object_ID = OBJECT_ID('[WideWorldImporters].[Sales].[Invoices]'))
BEGIN
 DROP INDEX [FK_Sales_Invoices_CustomerID] ON [WideWorldImporters].[Sales].[Invoices]
END
GO

CREATE INDEX [FK_Sales_Invoices_CustomerID] ON [WideWorldImporters].[Sales].[Invoices]
([CustomerID] ASC)
INCLUDE ([InvoiceDate])
GO
