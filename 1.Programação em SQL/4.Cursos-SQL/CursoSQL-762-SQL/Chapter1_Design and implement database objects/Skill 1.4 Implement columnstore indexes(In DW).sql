-- ==================================================================
--Observa��o:
/*1) Determine use cases that support the use of columnstore indexes
 */
-- ==================================================================

/*
Os �ndices do Columnstore s�o constru�dos especificamente para cen�rios de relat�rios, particularmente quando se trata
com grandes quantidades de dados. Os �ndices Columnstore baseiam-se no conceito de um columnar
banco de dados, 
*/

/*
ste formato � particularmente �til quando voc� s� precisa de uma pequena porcentagem das colunas
da mesa, especialmente quando voc� precisa de uma grande porcentagem das fileiras da mesa. Para
exemplo, uma consulta do formato SELECT SUM (Col1) FROM TableName; s� precisaria
para escanear a estrutura para Col1, e nunca precisaria tocar Col2, Col3 ou Col4
*/

/*
Existem v�rios tipos de dados que n�o s�o suportados:

varchar(max) and nvarchar(max)
rowversion (also known as timestamp)
sql_variant
CLR based types (hierarchyid and spatial types)
xml
ntext, text, and image (though rightfully so as these data types have been deprecated
for some time)
*/

/*
Cada grupo de linhas cont�m at� 1.048.576 linhas cada, quebradas
em segmentos que s�o todos ordenados fisicamente o mesmo, embora sem ordem l�gica.
*/

/*
note que os segmentos das colunas s�o desenhados de tamanho diferente,
porque cada um dos segmentos � compactado, usando constru��es semelhantes, como pode ser feito com
compress�o de p�gina em estruturas classificadas em linha, mas em vez de uma p�gina de 8K,
a compress�o pode ocorrer no grupo de uma �nica linha,
*/



-- ==================================================================
--Observa��o: Demo no Ambiente DW
-- ==================================================================



--USE WideWorldImportersDW

--DROP  INDEX [CCX_Fact_Order] ON [Fact].[Order];

CHECKPOINT;
-- Limpa buffers (comandos add-hoc)
 DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS ; -- deleta o cache da query 
 GO
  DBCC  FREEPROCCACHE WITH NO_INFOMSGS; --deleta o plano execu��o ja feito
  GO
  DBCC FREESESSIONCACHE WITH NO_INFOMSGS


DROP INDEX SpecificQuery ON Fact.[Order]


  
  /*
  Tabela 'Worktable'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0
  Tabela 'Workfile'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0,
  Tabela 'Order'. Contagem de verifica��es 7, leituras l�gicas 871, leituras f�sicas 3, leituras antecipadas 565
  Tabela 'Customer'. Contagem de verifica��es 1, leituras l�gicas 15, leituras f�sicas 0, leituras antecipadas 0
  Tabela 'Date'. Contagem de verifica��es 1, leituras l�gicas 28, leituras f�sicas 1, leituras antecipadas 19, l
  */
SET STATISTICS IO ON 
SELECT Customer.Category,
       Date.[Calendar Month Number],
       COUNT(*) AS SalesCount,
       SUM([Order].[Total Excluding Tax]) AS SalesTotal
  FROM Fact.[Order]
  JOIN Dimension.Date
    ON Date.Date  = [Order].[Order Date Key]
  JOIN Dimension.Customer
    ON Customer.[Customer Key] = [Order].[Customer Key]
 GROUP BY Customer.Category,
          Date.[Calendar Month Number]
 ORDER BY Customer.Category,
          Date.[Calendar Month Number],
          SalesCount,
          SalesTotal;
  SET STATISTICS IO OFF

CREATE NONCLUSTERED INDEX SpecificQuery ON [Fact].[Order]
([Customer Key])
INCLUDE ([Order Date Key],[Total Excluding Tax]);


/*
Tabela 'Worktable'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0,
Tabela 'Workfile'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0, 
Tabela 'Order'. Contagem de verifica��es 7, leituras l�gicas 871, leituras f�sicas 0, leituras antecipadas 0, l
Tabela 'Customer'. Contagem de verifica��es 1, leituras l�gicas 15, leituras f�sicas 0, leituras antecipadas 0,
Tabela 'Date'. Contagem de verifica��es 1, leituras l�gicas 28, leituras f�sicas 0, leituras antecipadas 0, lei
*/

--	DROP INDEX SpecificQuery ON Fact.[Order]


/*Cria��o do COLUMNSTORE */
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Order] ON [Fact].[Order];


-- ==================================================================
--Observa��o: Agora rode novamente
-- ==================================================================

/*
Tabela 'Order'. Contagem de verifica��es 1, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0, leit
Tabela 'Order'. Segmento lido 4, segmento ignorado 0.
Tabela 'Worktable'. Contagem de verifica��es 0, leituras l�gicas 0, leituras f�sicas 0, leituras antecipadas 0, 
Tabela 'Customer'. Contagem de verifica��es 1, leituras l�gicas 15, leituras f�sicas 1, leituras antecipadas 20,
Tabela 'Date'. Contagem de verifica��es 1, leituras l�gicas 28, leituras f�sicas 1, leituras antecipadas 19, lei
*/

SET STATISTICS IO ON 
SELECT Customer.Category,
       Date.[Calendar Month Number],
       COUNT(*) AS SalesCount,
       SUM([Order].[Total Excluding Tax]) AS SalesTotal
  FROM Fact.[Order]
  JOIN Dimension.Date
    ON Date.Date  = [Order].[Order Date Key]
  JOIN Dimension.Customer
    ON Customer.[Customer Key] = [Order].[Customer Key]
 GROUP BY Customer.Category,
          Date.[Calendar Month Number]
 ORDER BY Customer.Category,
          Date.[Calendar Month Number],
          SalesCount,
          SalesTotal;
  SET STATISTICS IO OFF