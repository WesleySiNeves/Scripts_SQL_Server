
/*########################
# OBS: Demo de identificação do problema com Falta de Statisticas 
*/
CREATE DATABASE ExamBook762Ch4_Statistics;
GO


ALTER DATABASE ExamBook762Ch4_Statistics SET AUTO_CREATE_STATISTICS OFF;
ALTER DATABASE ExamBook762Ch4_Statistics SET AUTO_UPDATE_STATISTICS OFF;
ALTER DATABASE ExamBook762Ch4_Statistics
SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
GO
USE ExamBook762Ch4_Statistics;
GO

CREATE SCHEMA Examples;
GO

CREATE TABLE Examples.OrderLines
(
    OrderLineID INT NOT NULL,
    OrderID INT NOT NULL,
    StockItemID INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    PackageTypeID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18, 2) NULL,
    TaxRate DECIMAL(18, 3) NOT NULL,
    PickedQuantity INT NOT NULL,
    PickingCompletedWhen DATETIME2(7) NULL,
    LastEditedBy INT NOT NULL,
    LastEditedWhen DATETIME2(7) NOT NULL
);
GO
INSERT INTO Examples.OrderLines
SELECT *
FROM WideWorldImporters.Sales.OrderLines;
GO


/*########################
# OBS: Agora vamos criar um indice e identificar as statisticas
*/

CREATE INDEX ix_OrderLines_StockItemID
ON Examples.OrderLines (StockItemID);
GO

DBCC SHOW_STATISTICS ('Examples.OrderLines', ix_OrderLines_StockItemID )
WITH HISTOGRAM;
GO


/*########################
# Quando o índice é adicionado à tabela, suas estatísticas também são criadas.
 No entanto, um Um número significativo de inserções ou atualizações na tabela
 pode tornar essas estatísticas obsoletas.
Execute as instruções na Listagem 4-3 para atualizar as linhas e verificar 
as estatísticas posteriormente para confirmar que não houve alteração
*/
UPDATE Examples.OrderLines
SET StockItemID = 1
WHERE OrderLineID < 45000;

DBCC SHOW_STATISTICS('Examples.OrderLines', ix_OrderLines_StockItemID)
WITH HISTOGRAM ;


/*########################
# OBS: Agora vamso rodar a query com o plano de execução ativado
veja que o sql erra na estimativa achando que vai ser retornadas
1048 linhas, assim ele usa seek, mas na verdade vai ser retornado
mais de 48 mil linhas
*/

SET STATISTICS TIME ON ;
--Tempo de CPU = 15 ms, tempo decorrido = 545 ms.
SELECT StockItemID
FROM Examples.OrderLines
WHERE StockItemID = 1;
SET STATISTICS TIME OFF

/*########################
# OBS: Veja agora o tempo se vc habilidar o autoupdateStatistisc
*/

ALTER DATABASE ExamBook762Ch4_Statistics SET AUTO_UPDATE_STATISTICS ON 

--Aqui o Sql server disparou um evento interno para autalizar statisticas
-- Tempo de CPU = 31 ms, tempo decorrido = 919 ms.
SET STATISTICS TIME ON ;
SELECT StockItemID
FROM Examples.OrderLines
WHERE StockItemID = 1;
SET STATISTICS TIME OFF