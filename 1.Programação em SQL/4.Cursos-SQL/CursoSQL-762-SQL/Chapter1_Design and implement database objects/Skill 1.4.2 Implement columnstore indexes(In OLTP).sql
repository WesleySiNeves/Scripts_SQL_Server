USE WideWorldImporters;

SELECT *
  FROM Sales.InvoiceLines AS IL;


-- ==================================================================
--Observação:Targeting analytically valuable columns only in columnstore
/* No indice COLUMNSTORE so fica os dados quentes da tabela

Certas colunas faziam parte do índice de armazenamento de colunas não agrupado.
 Isso pode reduzir o quantidade de dados duplicados
*/
-- ==================================================================
--DROP INDEX NCCX_Sales_OrderLines ON Sales.OrderLines

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines
ON Sales.OrderLines (OrderID, StockItemID, Description, Quantity, UnitPrice, PickedQuantity)
ON USERDATA;


-- ==================================================================
--Observação:Delaying adding rows to compressed rowgroups
/*
Os índices Columnstore devem ser mantidos na mesma transação com a modificação
declaração, assim como índices normais. No entanto, as modificações são feitas em um multi-passo
processo otimizado para o carregamento dos dados


 existe uma configuração que permite controlar a quantidade de tempo que os dados permanecem no
Deltastore. A configuração é: COMPRESSION_DELAY, e as unidades são minutos. Isso diz
que os dados permanecem no grupo de linhas delta durante pelo menos um certo número de minutos.
*/
-- ==================================================================

--Exemplo

SELECT * FROM Sales.OrderLines AS OL

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines
ON Sales.OrderLines(OrderID,StockItemID,Description,Quantity,UnitPrice,PickedQuantity)
WITH( COMPRESSION_DELAY = 5) ON USERDATA;

-- ==================================================================
--Observação:Using filtered non-clustered columnstore indexes to target colder data
-- ==================================================================


CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders
ON Sales.Orders (PickedByPersonID, SalespersonPersonID, OrderDate, PickingCompletedWhen)
WHERE PickedByPersonId IS NOT NULL;


-- ==================================================================
--Observação: Inicio Da demo
/* 
 */
-- ==================================================================


USE WideWorldImportersDW

--DROP TABLE IF EXISTS Fact.SaleBase 


--Cria uma Heap
SELECT *
INTO Fact.SaleBase
FROM Fact.Sale;

--O SELECT * INTO  não copia indices
/*
CREATE TABLE [Fact].[SaleBase](
	[Sale Key] [BIGINT] IDENTITY(1,1) NOT NULL,
	[City Key] [INT] NOT NULL,
	[Customer Key] [INT] NOT NULL,
	[Bill To Customer Key] [INT] NOT NULL,
	[Stock Item Key] [INT] NOT NULL,
	[Invoice Date Key] [DATE] NOT NULL,
	[Delivery Date Key] [DATE] NULL,
	[Salesperson Key] [INT] NOT NULL,
	[WWI Invoice ID] [INT] NOT NULL,
	[Description] [NVARCHAR](100) NOT NULL,
	[Package] [NVARCHAR](50) NOT NULL,
	[Quantity] [INT] NOT NULL,
	[Unit Price] [DECIMAL](18, 2) NOT NULL,
	[Tax Rate] [DECIMAL](18, 3) NOT NULL,
	[Total Excluding Tax] [DECIMAL](18, 2) NOT NULL,
	[Tax Amount] [DECIMAL](18, 2) NOT NULL,
	[Profit] [DECIMAL](18, 2) NOT NULL,
	[Total Including Tax] [DECIMAL](18, 2) NOT NULL,
	[Total Dry Items] [INT] NOT NULL,
	[Total Chiller Items] [INT] NOT NULL,
	[Lineage Key] [INT] NOT NULL
) ON [USERDATA]
*/


--DROP INDEX CColumnsStore ON Fact.SaleBase

CREATE CLUSTERED COLUMNSTORE INDEX CColumnsStore ON Fact.SaleBase;


-- ==================================================================
--Observação: Query

-- ==================================================================
/*
Tabela 'Date'. Contagem de verificações 5, leituras lógicas 79, leituras físicas 1, leituras antecipadas 19, le
Tabela 'SaleBase'. Contagem de verificações 5, leituras lógicas 6199, leituras físicas 0, leituras antecipadas 
Tabela 'Workfile'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0, 
Tabela 'Worktable'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0,
Tabela 'Customer'. Contagem de verificações 5, leituras lógicas 40, leituras físicas 1, leituras antecipadas 20
*/

SET STATISTICS IO ON 

SELECT Date.[Fiscal Year],
       Customer.Category,
       SUM(SaleBase.Quantity) AS NumSales
  FROM Fact.SaleBase
  JOIN Dimension.Customer
    ON Customer.[Customer Key] = SaleBase.[Customer Key]
  JOIN Dimension.Date ON Date.Date = SaleBase.[Invoice Date Key]
 GROUP BY Date.[Fiscal Year],
 Customer.Category
 ORDER BY Date.[Fiscal Year],
          Customer.Category;

SET STATISTICS IO OFF


/* Rode novamente 

Tabela 'SaleBase'. Contagem de verificações 1, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0,
Tabela 'SaleBase'. Segmento lido 1, segmento ignorado 0.
Tabela 'Worktable'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0
Tabela 'Customer'. Contagem de verificações 1, leituras lógicas 15, leituras físicas 0, leituras antecipadas 0
Tabela 'Date'. Contagem de verificações 1, leituras lógicas 28, leituras físicas 0, leituras antecipadas 0, le
*/


/* Agora coloque uma clausula where
*/



SET STATISTICS IO ON 

SELECT Date.[Fiscal Year],
       Customer.Category,
       SUM(SaleBase.Quantity) AS NumSales
  FROM Fact.SaleBase
  JOIN Dimension.Customer
    ON Customer.[Customer Key] = SaleBase.[Customer Key]
  JOIN Dimension.Date ON Date.Date = SaleBase.[Invoice Date Key]
  WHERE SaleBase.[Sale Key] = 26974
 GROUP BY Date.[Fiscal Year],
 Customer.Category
 ORDER BY Date.[Fiscal Year],
          Customer.Category;

SET STATISTICS IO OFF


--Criação do Indice
CREATE UNIQUE INDEX [Sale Key] ON Fact.SaleBase ([Sale Key]);

--CREATE INDEX [WWI Invoice ID] ON Fact.SaleBase([WWI Invoice ID])


SET STATISTICS IO ON 

SELECT Date.[Fiscal Year],
       Customer.Category,
       SUM(SaleBase.Quantity) AS NumSales
  FROM Fact.SaleBase
  JOIN Dimension.Customer
    ON Customer.[Customer Key] = SaleBase.[Customer Key]
  JOIN Dimension.Date ON Date.Date = SaleBase.[Invoice Date Key]
  WHERE SaleBase.[Sale Key] = 26974
 GROUP BY Date.[Fiscal Year],
 Customer.Category
 ORDER BY Date.[Fiscal Year],
          Customer.Category;

SET STATISTICS IO OFF