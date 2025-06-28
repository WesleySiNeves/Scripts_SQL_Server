USE WideWorldImportersDW

-- ==================================================================
--Observação: Operadores do plano de execução
/*
O desempenho da consulta sofrerá quando a classificação precisar usar tempdb em vez de memória.
Use a dica de ferramenta para o operador SELECT para verificar a propriedade Memory Grant que mostra
quantidade de memória que o SQL Server está alocando para a consulta. No SQL Server 2016, você pode
agora adicione uma dica de consulta para solicitar um tamanho mínimo de concessão de memória como uma porcentagem do padrão
limite para substituir a memória mínima por propriedade de consulta definida no servidor da seguinte forma:
*/
-- ==================================================================


SELECT *
  FROM Fact.Sale AS S
OPTION (min_grant_percent = 100);



/*
Operador Hash Match (Agregado)
Agregações em uma consulta podem ter um efeito negativo no desempenho e devem ser revisadas
cuidadosamente. A Figura 4-15 mostra o plano de consulta criado para a seguinte consulta agregada:
*/


/*

Neste caso, o operador Hash Match (Aggregate) agrupa as linhas do Index Scan
Operador (não-agrupado) contribui com uma porcentagem significativa para o custo da consulta. Atuar
essa agregação, o SQL Server cria uma tabela de hash temporária na memória para contar as linhas
pelo ano da fatura. Observe a largura maior da seta enviando dados para o Hash Match
(Agregado) em comparação com a largura da seta enviando os resultados para a próxima
operador como um indicador de que um conjunto de linhas maior foi reduzido a uma linha menor definida
Operação.
Opções a serem consideradas para minimizar o impacto no desempenho ao executar
agregações é minimizar o número de linhas para agregar onde for possível ou usar um
visualização indexada para pré-agregar linhas.
*/


SELECT
YEAR(InvoiceDate) AS InvoiceYear,
COUNT(InvoiceID) AS InvoiceCount
FROM Sales.Invoices
GROUP BY YEAR(InvoiceDate);


-- ==================================================================
--Observação: Veja a opção de criar um view Indexada para otimizar a consulta
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
Como resultado da adição da exibição indexada, o SQL Server não requer mais o Hash
Operador Match (Agregador) e, em vez disso, usa uma Varredura de Índice em Cluster (ViewClustered)
operador para recuperar dados. Como os dados são pré-agregados, a varredura de índice é muito mais rápida
nesse caso, seria contra um índice contendo todas as linhas da tabela.
*/
SELECT * FROM Sales.vSalesByYear AS VSBY


-- ==================================================================
--Observação: Hash Match (Inner Join) operator
/*
Até agora, as consultas que examinamos são relativamente simples e lêem dados de
apenas uma mesa. Agora, vamos considerar uma consulta que combina dados de várias tabelas para
produza o plano de consulta mostrado


Neste exemplo, vemos a adição do operador Hash Match (Inner Join) em dois
lugares no plano de consulta. Também vemos que essas duas operações têm os dois maiores custos
no plano e, portanto, devem ser as primeiras operações que avaliamos para possível otimização.
O SQL Server usa esse operador quando coloca dados em tabelas de hash temporárias para que ele possa
corresponder linhas em dois conjuntos de dados diferentes e produzir um único conjunto de resultados. Especificamente

O SQL converte ou hashes linhas do conjunto de dados menor em um valor que é mais
eficiente para comparações e, em seguida, armazena esses valores em uma tabela de hash em tempdb. Então isso
compara cada linha no maior conjunto de dados com a tabela de hash para encontrar linhas correspondentes a serem unidas.
Contanto que o conjunto de dados menor seja de fato pequeno, essa operação de comparação é rápida, mas
o desempenho pode sofrer quando os dois conjuntos de dados são grandes.

Além disso, se uma consulta exigir
muitas dessas operações, o tempdb pode sofrer pressão de memória. Por último, é importante
observe que o operador Hash Match (Inner Join) é um operador de bloqueio, já que requer SQL
Servidor para coletar dados de cada conjunto de dados antes que ele possa executar a junção
*/
-- ==================================================================


-- ==================================================================
--Observação: Veja que aqui vamos eliminar os dois Hash Match
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
--Observação: Vamos criar um Indice
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
--Observação: Agora vamso ver o novo plano de execução , antes tinhamos 
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

