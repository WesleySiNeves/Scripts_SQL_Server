SET TRAN ISOLATION LEVEL READ UNCOMMITTED

/* ==================================================================
--Data: 31/08/2018 
--Autor :Wesley Neves
--Observação: quantidade memoria usada no Buffer Pool
 
-- ==================================================================
*/
SELECT
    databases.name AS database_name,
    COUNT(*) * 8.0 / 1024 AS mb_used
FROM sys.dm_os_buffer_descriptors
INNER JOIN sys.databases
ON databases.database_id = dm_os_buffer_descriptors.database_id
WHERE databases.name =DB_NAME(DB_ID())
GROUP BY databases.name
ORDER BY COUNT(*) DESC;

 

 /*Quantidade de paginas qwue estão no buffer para cada tabela*/
 
 ;WITH Dados AS (
 SELECT DB_NAME(DB_ID()) DatabaseName,
       Result.ObjectName,
       COUNT(*) AS cached_pages_count,
       Result.index_id
FROM sys.dm_os_buffer_descriptors A
     INNER JOIN
     (
     SELECT OBJECT_NAME(B.object_id) AS ObjectName,
            A.allocation_unit_id,
            A.type_desc,
            B.index_id,
            B.rows
     FROM sys.allocation_units A,
          sys.partitions B
     WHERE A.container_id = B.hobt_id
           AND (
               A.type = 1
               OR A.type = 3
               )
     UNION ALL
     SELECT OBJECT_NAME(p.object_id) AS ObjectName,
            au.allocation_unit_id,
            au.type_desc,
            p.index_id,
            p.rows
     FROM sys.allocation_units AS au
          INNER JOIN
          sys.partitions AS p ON au.container_id = p.partition_id
                                 AND au.type = 2
     ) AS Result ON A.allocation_unit_id = Result.allocation_unit_id
WHERE database_id = DB_ID()
GROUP BY
    Result.ObjectName,
    Result.index_id
ORDER BY
    cached_pages_count DESC
	OFFSET 0 ROWS FETCH NEXT 10000 ROW ONLY 
 )
 SELECT R.DatabaseName,
        R.ObjectName,
        R.cached_pages_count,
		[TotalMB] =(cached_pages_count * 8.0) / 1024,
		[GrandTotal] =  ((SUM(cached_pages_count) OVER() * 8.0) / 1024 ),
        R.index_id FROM Dados R
		WHERE R.ObjectName NOT LIKE 'sys%'


