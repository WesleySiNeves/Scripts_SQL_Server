



USE Implanta;

SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

WITH Dados
  AS (SELECT Tabela = OBJECT_NAME(physical.object_id, DB_ID()),
             [IndexName] = I.name,
             physical.alloc_unit_type_desc,
             physical.page_count,
             physical.index_type_desc,
             physical.index_level,
             physical.avg_page_space_used_in_percent,
             physical.avg_fragmentation_in_percent,
             physical.record_count,
             TotalPaginas = SUM(physical.page_count) OVER (PARTITION BY I.object_id, I.index_id),
             TotalLinhas = SUM(physical.record_count) OVER (PARTITION BY I.object_id, I.index_id),
             TamanhoEmMB = FORMAT(
                               CAST(((CAST(SUM(physical.page_count) OVER (PARTITION BY I.object_id, I.index_id) AS DECIMAL(18, 2))
                                      * 8) / 1024) AS DECIMAL(18, 2)),
                               'N',
                               'pt-BR')
        FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'Detailed') AS physical
        JOIN sys.indexes AS I
          ON physical.object_id = I.object_id
         AND physical.index_id  = I.index_id
       WHERE physical.index_type_desc = 'CLUSTERED INDEX')
SELECT R.Tabela,
       R.IndexName,
       R.alloc_unit_type_desc,
       R.page_count,
       R.index_type_desc,
       R.index_level,
       R.avg_page_space_used_in_percent,
       R.avg_fragmentation_in_percent,
       R.record_count,
       R.TotalPaginas,
       R.TotalLinhas,
       R.TamanhoEmMB
  FROM Dados R
 WHERE R.page_count > 1000
 ORDER BY R.Tabela,
          R.IndexName;



