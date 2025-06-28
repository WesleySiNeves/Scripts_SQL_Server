USE WideWorldImportersDW

-- ==================================================================
--Observa��o: Operadores do plano de execu��o
/*
O desempenho da consulta sofrer� quando a classifica��o precisar usar tempdb em vez de mem�ria.
Use a dica de ferramenta para o operador SELECT para verificar a propriedade Memory Grant que mostra
quantidade de mem�ria que o SQL Server est� alocando para a consulta. No SQL Server 2016, voc� pode
agora adicione uma dica de consulta para solicitar um tamanho m�nimo de concess�o de mem�ria como uma porcentagem do padr�o
limite para substituir a mem�ria m�nima por propriedade de consulta definida no servidor da seguinte forma:
*/
-- ==================================================================


SELECT *
  FROM Fact.Sale AS S
OPTION (min_grant_percent = 100);



/*
Operador Hash Match (Agregado)
Agrega��es em uma consulta podem ter um efeito negativo no desempenho e devem ser revisadas
cuidadosamente. A Figura 4-15 mostra o plano de consulta criado para a seguinte consulta agregada:
*/


/*

Neste caso, o operador Hash Match (Aggregate) agrupa as linhas do Index Scan
Operador (n�o-agrupado) contribui com uma porcentagem significativa para o custo da consulta. Atuar
essa agrega��o, o SQL Server cria uma tabela de hash tempor�ria na mem�ria para contar as linhas
pelo ano da fatura. Observe a largura maior da seta enviando dados para o Hash Match
(Agregado) em compara��o com a largura da seta enviando os resultados para a pr�xima
operador como um indicador de que um conjunto de linhas maior foi reduzido a uma linha menor definida
Opera��o.
Op��es a serem consideradas para minimizar o impacto no desempenho ao executar
agrega��es � minimizar o n�mero de linhas para agregar onde for poss�vel ou usar um
visualiza��o indexada para pr�-agregar linhas.
*/


SELECT
YEAR(InvoiceDate) AS InvoiceYear,
COUNT(InvoiceID) AS InvoiceCount
FROM Sales.Invoices
GROUP BY YEAR(InvoiceDate);


-- ==================================================================
--Observa��o: Veja a op��o de criar um view Indexada para otimizar a consulta
-- ==================================================================

GO


CREATE VIEW Sales.vSalesByYear
WITH SCHEMABINDING
AS
SELECT YEAR(InvoiceDate) AS InvoiceYear,
       COUNT_BIG(*) AS InvoiceCount
  FROM Sales.Invoices
 GROUP BY YEAR(InvoiceDate);
GO

CREATE UNIQUE CLUSTERED INDEX idx_vSalesByYear
ON Sales.vSalesByYear (InvoiceYear);
GO


/*
Como resultado da adi��o da exibi��o indexada, o SQL Server n�o requer mais o Hash
Operador Match (Agregador) e, em vez disso, usa uma Varredura de �ndice em Cluster (ViewClustered)
operador para recuperar dados. Como os dados s�o pr�-agregados, a varredura de �ndice � muito mais r�pida
nesse caso, seria contra um �ndice contendo todas as linhas da tabela.
*/
SELECT * FROM Sales.vSalesByYear AS VSBY


-- ==================================================================
--Observa��o: Hash Match (Inner Join) operator
/*
At� agora, as consultas que examinamos s�o relativamente simples e l�em dados de
apenas uma mesa. Agora, vamos considerar uma consulta que combina dados de v�rias tabelas para
produza o plano de consulta mostrado


Neste exemplo, vemos a adi��o do operador Hash Match (Inner Join) em dois
lugares no plano de consulta. Tamb�m vemos que essas duas opera��es t�m os dois maiores custos
no plano e, portanto, devem ser as primeiras opera��es que avaliamos para poss�vel otimiza��o.
O SQL Server usa esse operador quando coloca dados em tabelas de hash tempor�rias para que ele possa
corresponder linhas em dois conjuntos de dados diferentes e produzir um �nico conjunto de resultados. Especificamente

O SQL converte ou hashes linhas do conjunto de dados menor em um valor que � mais
eficiente para compara��es e, em seguida, armazena esses valores em uma tabela de hash em tempdb. Ent�o isso
compara cada linha no maior conjunto de dados com a tabela de hash para encontrar linhas correspondentes a serem unidas.
Contanto que o conjunto de dados menor seja de fato pequeno, essa opera��o de compara��o � r�pida, mas
o desempenho pode sofrer quando os dois conjuntos de dados s�o grandes.

Al�m disso, se uma consulta exigir
muitas dessas opera��es, o tempdb pode sofrer press�o de mem�ria. Por �ltimo, � importante
observe que o operador Hash Match (Inner Join) � um operador de bloqueio, j� que requer SQL
Servidor para coletar dados de cada conjunto de dados antes que ele possa executar a jun��o
*/
-- ==================================================================


-- ==================================================================
--Observa��o: Veja que aqui vamos eliminar os dois Hash Match
-- ==================================================================
SELECT si.StockItemName,
       c.ColorName,
       s.SupplierName
  FROM Warehouse.StockItems si
 INNER JOIN Warehouse.Colors c
    ON c.ColorID    = si.ColoriD
 INNER JOIN Purchasing.Suppliers s
    ON s.SupplierID = si.SupplierID;


-- ==================================================================
--Observa��o: Vamos criar um Indice
 --ADD indexes to eliminate Hash Match (Inner Join) operators
-- ==================================================================


CREATE NONCLUSTERED INDEX
IX_Purchasing_Suppliers_ExamBook762Ch4_SupplierID
ON Purchasing.Suppliers
(
SupplierID ASC,
SupplierName
);
GO
CREATE NONCLUSTERED INDEX
IX_Warehouse_StockItems_ExamBook762Ch4_ColorID
ON Warehouse.StockItems
(
ColorID ASC,
SupplierID ASC,
StockItemName ASC
);


-- ==================================================================
--Observa��o: Agora vamso ver o novo plano de execu��o , antes tinhamos 
-- dois hash math joins ,agora temos dois Nested Loops
/*
 */
-- ================================================================== 

SELECT
si.StockItemName,
c.ColorName,
s.SupplierName
FROM Warehouse.StockItems si
INNER JOIN Warehouse.Colors c ON
c.ColorID = si.ColoriD
INNER JOIN Purchasing.Suppliers s ON
s.SupplierID = si.SupplierID;

