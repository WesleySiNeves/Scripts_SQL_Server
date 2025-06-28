TRUNCATE TABLE dbo.TestStructure


DECLARE @i AS INT = 0;

WHILE @i < 18660
BEGIN

    SET @i = @i + 1;

    INSERT INTO dbo.TestStructure (filler1,
                                   filler2)
    VALUES ('a', 'b');

END;


 -- ==================================================================
 --Observação: Mostra a porcentagem de fragmentação do indice
 -- ==================================================================

SELECT Phisical.index_type_desc,
       Phisical.page_count,
       Phisical.record_count,
       Phisical.avg_page_space_used_in_percent
  FROM sys.dm_db_index_physical_stats(DB_ID(N'TSQL2017'), OBJECT_ID(N'dbo.TestStructure'),
   NULL, NULL, 
   'DETAILED') AS Phisical;


-- ==================================================================
--Observação: Mais um Insert
-- ==================================================================

    INSERT INTO dbo.TestStructure (filler1,
                                   filler2)
    VALUES ('a', 'b');
	GO 1
     


	 
 -- ==================================================================
 --Observação: Mostra a porcentagem de fragmentação do indice
 -- ==================================================================

SELECT Phisical.index_type_desc,
       Phisical.page_count,
       Phisical.record_count,
       Phisical.avg_page_space_used_in_percent
  FROM sys.dm_db_index_physical_stats(DB_ID(N'TSQL2017'), OBJECT_ID(N'dbo.TestStructure'),
   NULL, NULL, 
   'DETAILED') AS Phisical;




-- ==================================================================
--Observação: Demo 4
-- ==================================================================
TRUNCATE TABLE dbo.TestStructure


--ALTER TABLE  dbo.TestStructure DROP PK__TestStru__3213E83F534B7A2B 
CREATE CLUSTERED INDEX idx_cl_filler1 ON dbo.TestStructure(filler1);?

DECLARE @i AS INT = 0;

WHILE @i < 9000
BEGIN

    SET @i = @i + 1;

    INSERT INTO dbo.TestStructure (
                                   filler1,
                                   filler2)
    VALUES ( CAST(NEWID() AS CHAR(36)), 'b');

END;

SELECT Phisical.index_type_desc,
       Phisical.page_count [Total paginas do Indice],
       Phisical.record_count [Total de Linhas],
       Phisical.avg_page_space_used_in_percent [Porcentagem de dados],
	   Phisical.avg_fragmentation_in_percent [Porcentagem de Fragmentação da Pagina] ,
	   Phisical.fragment_count [Total Paginas com Gragmentadas]
  FROM sys.dm_db_index_physical_stats(DB_ID(N'TSQL2017'), OBJECT_ID(N'dbo.TestStructure'), NULL, NULL, 'DETAILED') 
  AS Phisical;

  ALTER INDEX idx_cl_filler1 ON dbo.TestStructure REORGANIZE