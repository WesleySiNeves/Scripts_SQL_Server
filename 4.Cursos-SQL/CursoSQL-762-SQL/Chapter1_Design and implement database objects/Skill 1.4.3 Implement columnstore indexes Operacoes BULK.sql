/*
*/

DROP TABLE IF EXISTS [Fact].[SaleLimited]

CREATE TABLE [Fact].[SaleLimited] (
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
    [Quantity] [INT] NOT NULL);


	-- ==================================================================
	--Observação: Bulk loading data into a clustered columnstore
-- ==================================================================

--Criando um indice
--DROP INDEX [CColumnStore] ON [Fact].[SaleLimited]
CREATE CLUSTERED COLUMNSTORE INDEX [CColumnStore] ON [Fact].[SaleLimited];

--Inserir 100,000 mil registros
INSERT INTO Fact.SaleLimited WITH (TABLOCK) ([City Key],
                                             [Customer Key],
                                             [Bill To Customer Key],
                                             [Stock Item Key],
                                             [Invoice Date Key],
                                             [Delivery Date Key],
                                             [Salesperson Key],
                                             [WWI Invoice ID],
                                             [Description],
                                             [Package],
                                             [Quantity])
SELECT TOP (100000) Sale.[City Key],
       Sale.[Customer Key],
       [Bill To Customer Key],
       Sale.[Stock Item Key],
       Sale.[Invoice Date Key],
       [Delivery Date Key] ,
       Sale.[Salesperson Key],
       Sale.[WWI Invoice ID],
       Sale.Description,
       Sale.Package,
       Sale.Quantity
  FROM Fact.Sale;

--Aqui vc ve os dados do Indice --Foi adicionado 4 grupos de filas deltastore
--por que minha maquina tem 4 processadores
SELECT Store.state_desc,
       Store.total_rows,
       Store.deleted_rows,
       Store.transition_to_compressed_state_desc AS transition
  FROM sys.dm_db_column_store_row_group_physical_stats Store
 WHERE Store.object_id = OBJECT_ID('Fact.SaleLimited') ;


 --Agora rode isso
ALTER INDEX CColumnStore
ON Fact.SaleLimited
REORGANIZE
WITH (COMPRESS_ALL_ROW_GROUPS = ON);