-- ==================================================================
--Observação:
/*1) Determine use cases that support the use of columnstore indexes
 */
-- ==================================================================

/*
Os índices do Columnstore são construídos especificamente para cenários de relatórios, particularmente quando se trata
com grandes quantidades de dados. Os índices Columnstore baseiam-se no conceito de um columnar
banco de dados, 
*/

/*
ste formato é particularmente útil quando você só precisa de uma pequena porcentagem das colunas
da mesa, especialmente quando você precisa de uma grande porcentagem das fileiras da mesa. Para
exemplo, uma consulta do formato SELECT SUM (Col1) FROM TableName; só precisaria
para escanear a estrutura para Col1, e nunca precisaria tocar Col2, Col3 ou Col4
*/

/*
Existem vários tipos de dados que não são suportados:

varchar(max) and nvarchar(max)
rowversion (also known as timestamp)
sql_variant
CLR based types (hierarchyid and spatial types)
xml
ntext, text, and image (though rightfully so as these data types have been deprecated
for some time)
*/

/*
Cada grupo de linhas contém até 1.048.576 linhas cada, quebradas
em segmentos que são todos ordenados fisicamente o mesmo, embora sem ordem lógica.
*/

/*
note que os segmentos das colunas são desenhados de tamanho diferente,
porque cada um dos segmentos é compactado, usando construções semelhantes, como pode ser feito com
compressão de página em estruturas classificadas em linha, mas em vez de uma página de 8K,
a compressão pode ocorrer no grupo de uma única linha,
*/



-- ==================================================================
--Observação: Demo no Ambiente DW
-- ==================================================================



--USE WideWorldImportersDW

--DROP  INDEX [CCX_Fact_Order] ON [Fact].[Order];

CHECKPOINT;
-- Limpa buffers (comandos add-hoc)
 DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS ; -- deleta o cache da query 
 GO
  DBCC  FREEPROCCACHE WITH NO_INFOMSGS; --deleta o plano execução ja feito
  GO
  DBCC FREESESSIONCACHE WITH NO_INFOMSGS


DROP INDEX SpecificQuery ON Fact.[Order]


  
  /*
  Tabela 'Worktable'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0
  Tabela 'Workfile'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0,
  Tabela 'Order'. Contagem de verificações 7, leituras lógicas 871, leituras físicas 3, leituras antecipadas 565
  Tabela 'Customer'. Contagem de verificações 1, leituras lógicas 15, leituras físicas 0, leituras antecipadas 0
  Tabela 'Date'. Contagem de verificações 1, leituras lógicas 28, leituras físicas 1, leituras antecipadas 19, l
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
Tabela 'Worktable'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0,
Tabela 'Workfile'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0, 
Tabela 'Order'. Contagem de verificações 7, leituras lógicas 871, leituras físicas 0, leituras antecipadas 0, l
Tabela 'Customer'. Contagem de verificações 1, leituras lógicas 15, leituras físicas 0, leituras antecipadas 0,
Tabela 'Date'. Contagem de verificações 1, leituras lógicas 28, leituras físicas 0, leituras antecipadas 0, lei
*/

--	DROP INDEX SpecificQuery ON Fact.[Order]


/*Criação do COLUMNSTORE */
CREATE CLUSTERED COLUMNSTORE INDEX [CCX_Fact_Order] ON [Fact].[Order];


-- ==================================================================
--Observação: Agora rode novamente
-- ==================================================================

/*
Tabela 'Order'. Contagem de verificações 1, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0, leit
Tabela 'Order'. Segmento lido 4, segmento ignorado 0.
Tabela 'Worktable'. Contagem de verificações 0, leituras lógicas 0, leituras físicas 0, leituras antecipadas 0, 
Tabela 'Customer'. Contagem de verificações 1, leituras lógicas 15, leituras físicas 1, leituras antecipadas 20,
Tabela 'Date'. Contagem de verificações 1, leituras lógicas 28, leituras físicas 1, leituras antecipadas 19, lei
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