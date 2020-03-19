/*########################
# OBS: Comparando Plano e execu�o estimado e o real
*/

CREATE DATABASE ExamBook762Ch4_QueryPlans;
GO
USE ExamBook762Ch4_QueryPlans;
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
CREATE INDEX ix_OrderLines_StockItemID
ON Examples.OrderLines (StockItemID);
GO


/*########################
# OBS: Agora vamos for�ar o Sql server a gerar um plano de execu��o estimado
para gerar um plano de consulta estimado. A inclus�o
da instru��o SET SHOWPLAN_XML ON instrui o SQL Server a gerar o
plano estimado sem executar a consulta
*/



/*########################
# OBS: Op��es

SET SHOWPLAN_TEXT ON Retorna uma �nica coluna contendo um arquivo hier�rquico.
�rvore que descreve as opera��es e inclui o operador f�sico e, opcionalmente,
o operador l�gico.


SET SHOWPLAN_ALL ON Retorna as mesmas informa��es que SET
SHOWPLAN_TEXT, exceto que as informa��es est�o espalhadas por um conjunto de colunas
que voc� pode ver mais facilmente valores de propriedade para cada operador
1)
*/


/*########################
# OBS: Veja as discrepancias entre as estimativas de updade
e as estimativas de select
*/

SET SHOWPLAN_XML ON;
GO
BEGIN TRANSACTION;
UPDATE Examples.OrderLines
SET StockItemID = 300
WHERE StockItemID < 100;
SELECT OrderID,
       Description,
       UnitPrice
FROM Examples.OrderLines
WHERE StockItemID = 300;
ROLLBACK TRANSACTION;
GO
SET SHOWPLAN_XML OFF;
GO



/*########################
#
Instru��o SET STATISTICS XML ON para que o SQL Server gere um gr�fico real
plano de consulta. Como alternativa, voc� pode usar a instru��o SET STATISTICS PROFILE ON
obter as informa��es do plano de consulta em uma �rvore hier�rquica com informa��es
 de perfil dispon�veis atrav�s das colunas no conjunto de resultados. 
 o SQL Server reconheceu a altera��o de mais de 20% nas estat�sticas da tabela e 
 realizou uma atualiza��o autom�tica que, em Por sua vez, 
 for�ou uma recompila��o do plano de consulta da instru��o SELECT. Desta vez a consulta
*/


/*########################
# OBS: Generate actual query plan
*/
			SET STATISTICS XML ON;
			GO
			BEGIN TRANSACTION;
			UPDATE Examples.OrderLines
			SET StockItemID = 300
			WHERE StockItemID < 100;
			SELECT OrderID,
				   Description,
				   UnitPrice
			FROM Examples.OrderLines
			WHERE StockItemID = 300;
			ROLLBACK TRANSACTION;
			GO
			SET STATISTICS XML OFF;
			GO