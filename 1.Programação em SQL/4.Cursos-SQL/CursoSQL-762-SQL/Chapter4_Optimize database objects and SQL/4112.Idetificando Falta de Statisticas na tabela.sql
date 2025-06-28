
/*########################
# OBS: Demo de identifica��o do problema com Falta de Statisticas 
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
# Quando o �ndice � adicionado � tabela, suas estat�sticas tamb�m s�o criadas.
 No entanto, um Um n�mero significativo de inser��es ou atualiza��es na tabela
 pode tornar essas estat�sticas obsoletas.
Execute as instru��es na Listagem 4-3 para atualizar as linhas e verificar 
as estat�sticas posteriormente para confirmar que n�o houve altera��o
*/
UPDATE Examples.OrderLines
SET StockItemID = 1
WHERE OrderLineID < 45000;

DBCC SHOW_STATISTICS('Examples.OrderLines', ix_OrderLines_StockItemID)
WITH HISTOGRAM ;


/*########################
# OBS: Agora vamso rodar a query com o plano de execu��o ativado
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