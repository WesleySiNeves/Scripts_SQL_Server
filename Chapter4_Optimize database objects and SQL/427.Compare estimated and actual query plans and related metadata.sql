/*########################
# OBS: Comparando Plano e execuão estimado e o real
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
# OBS: Agora vamos forçar o Sql server a gerar um plano de execução estimado
para gerar um plano de consulta estimado. A inclusão
da instrução SET SHOWPLAN_XML ON instrui o SQL Server a gerar o
plano estimado sem executar a consulta
*/



/*########################
# OBS: Opções

SET SHOWPLAN_TEXT ON Retorna uma única coluna contendo um arquivo hierárquico.
árvore que descreve as operações e inclui o operador físico e, opcionalmente,
o operador lógico.


SET SHOWPLAN_ALL ON Retorna as mesmas informações que SET
SHOWPLAN_TEXT, exceto que as informações estão espalhadas por um conjunto de colunas
que você pode ver mais facilmente valores de propriedade para cada operador
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
Instrução SET STATISTICS XML ON para que o SQL Server gere um gráfico real
plano de consulta. Como alternativa, você pode usar a instrução SET STATISTICS PROFILE ON
obter as informações do plano de consulta em uma árvore hierárquica com informações
 de perfil disponíveis através das colunas no conjunto de resultados. 
 o SQL Server reconheceu a alteração de mais de 20% nas estatísticas da tabela e 
 realizou uma atualização automática que, em Por sua vez, 
 forçou uma recompilação do plano de consulta da instrução SELECT. Desta vez a consulta
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