USE WideWorldImporters;

SELECT *
  FROM Sales.InvoiceLines AS IL;


-- ==================================================================
--Observa��o:Targeting analytically valuable columns only in columnstore
/* No indice COLUMNSTORE so fica os dados quentes da tabela

Certas colunas faziam parte do �ndice de armazenamento de colunas n�o agrupado.
 Isso pode reduzir o quantidade de dados duplicados
*/
-- ==================================================================
--DROP INDEX NCCX_Sales_OrderLines ON Sales.OrderLines

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines
ON Sales.OrderLines (OrderID, StockItemID, Description, Quantity, UnitPrice, PickedQuantity)
ON USERDATA;


-- ==================================================================
--Observa��o:Delaying adding rows to compressed rowgroups
/*
Os �ndices Columnstore devem ser mantidos na mesma transa��o com a modifica��o
declara��o, assim como �ndices normais. No entanto, as modifica��es s�o feitas em um multi-passo
processo otimizado para o carregamento dos dados


 existe uma configura��o que permite controlar a quantidade de tempo que os dados permanecem no
Deltastore. A configura��o �: COMPRESSION_DELAY, e as unidades s�o minutos. Isso diz
que os dados permanecem no grupo de linhas delta durante pelo menos um certo n�mero de minutos.
*/
-- ==================================================================

--Exemplo

SELECT * FROM Sales.OrderLines AS OL

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCX_Sales_OrderLines
ON Sales.OrderLines(OrderID,StockItemID,Description,Quantity,UnitPrice,PickedQuantity)
WITH( COMPRESSION_DELAY = 5) ON USERDATA;

-- ==================================================================
--Observa��o:Using filtered non-clustered columnstore indexes to target colder data
-- ==================================================================


CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders
ON Sales.Orders (PickedByPersonID, SalespersonPersonID, OrderDate, PickingCompletedWhen)
WHERE PickedByPersonId IS NOT NULL;


-- ==================================================================
--Observa��o: Inicio Da demo
/* 
 */
-- ==================================================================


USE WideWorldImportersDW

--DROP TABLE IF EXISTS Fact.SaleBase 


--Cria uma Heap
SELECT *
INTO Fact.SaleBase
FROM Fact.Sale;

--O SELECT * INTO  n�o copia indices
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
--Observa��o: Query

-- ==================================================================
/*
Tabela 'Date'. Contagem de verifica��es 5, leituras l�gicas 79, leituras f�sicas 1, leituras antecipadas 19, le
Tabela 'SaleBase'. Contagem de verifica��es 5, leituras l�gicas 6199, leituras f�sicas 0, leituras antecipadas 
Tabela 'Workfile'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0, 
Tabela 'Worktable'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0,
Tabela 'Customer'. Contagem de verifica��es 5, leituras l�gicas 40, leituras f�sicas 1, leituras antecipadas 20
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

Tabela 'SaleBase'. Contagem de verifica��es 1, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0,
Tabela 'SaleBase'. Segmento lido 1, segmento ignorado 0.
Tabela 'Worktable'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0
Tabela 'Customer'. Contagem de verifica��es 1, leituras l�gicas 15, leituras f�sicas 0, leituras antecipadas 0
Tabela 'Date'. Contagem de verifica��es 1, leituras l�gicas 28, leituras f�sicas 0, leituras antecipadas 0, le
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


--Cria��o do Indice
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