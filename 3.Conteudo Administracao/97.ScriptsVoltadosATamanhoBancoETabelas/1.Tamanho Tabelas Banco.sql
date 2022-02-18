SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

USE Implanta;

WITH DadosBrutos AS (

SELECT sc.name + '.' + t.name AS TableName,
       p.rows,
       (SUM(a.total_pages) * 8) / 1024.0 AS [TotalReservedSpace MB], -- Number of total pages * 8KB size of each page in SQL Server  
       (SUM(a.used_pages) * 8) / 1024.0 AS [UsedDataSpace MB],
       (SUM(a.data_pages) * 8) / 1024.0 AS [FreeUnusedSpace MB]
  FROM sys.tables t
 INNER JOIN sys.schemas sc
    ON sc.schema_id   = t.schema_id
 INNER JOIN sys.indexes i
    ON t.object_id    = i.object_id
 INNER JOIN sys.partitions p
    ON i.object_id    = p.object_id
   AND i.index_id     = p.index_id
 INNER JOIN sys.allocation_units a
    ON p.partition_id = a.container_id
 WHERE t.type_desc = 'USER_TABLE'
   AND i.index_id  <= 1 --- Heap\ CLUSTERED
 -- AND t.NAME='MYTableName' -- Replace with valid table name
 GROUP BY sc.name + '.' + t.name,
          i.object_id,
          i.index_id,
          i.name,
          p.rows
)
SELECT R.TableName,
       [Rows] = FORMAT(R.rows,'N','pt-Br') ,
       R.[TotalReservedSpace MB],
	   [Tamanho GB] =CAST((R.[TotalReservedSpace MB] /1024.0) AS NUMERIC(12,4)),
       R.[UsedDataSpace MB],
       R.[FreeUnusedSpace MB]
	    FROM DadosBrutos R
ORDER BY R.[TotalReservedSpace MB] DESC




--Erro ao salvar associação do Pagamento com o Registro.   --Status 2
