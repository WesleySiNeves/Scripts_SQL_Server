

SET TRAN ISOLATION LEVEL READ UNCOMMITTED
/* ==================================================================
--Data: 14/09/2018 
--Autor :Wesley Neves
--Observação: Query Pesada cerca de 30 segundos
 
-- ==================================================================
*/
;WITH Dados AS (
 SELECT DB_NAME(DB_ID()) DatabaseName,
		Result.object_id,
       Result.ObjectName,
       COUNT(*) AS cached_pages_count,
       Result.index_id
FROM sys.dm_os_buffer_descriptors A
     INNER JOIN
     (
     SELECT OBJECT_NAME(B.object_id) AS ObjectName,
			B.object_id,
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
			p.object_id,
            au.allocation_unit_id,
            au.type_desc,
            p.index_id,
            p.rows
     FROM sys.allocation_units AS au
          INNER JOIN
          sys.partitions AS p ON au.container_id = p.partition_id
                                 AND au.type = 2
     ) AS Result ON A.allocation_unit_id = Result.allocation_unit_id
--WHERE database_id = DB_ID()
AND Result.object_id > 100
GROUP BY
	Result.object_id,
    Result.ObjectName,
    Result.index_id
ORDER BY
    cached_pages_count DESC
	OFFSET 0 ROWS FETCH NEXT 10000 ROW ONLY 
 )
 SELECT R.DatabaseName,
		R.object_id,
        R.ObjectName,
        R.cached_pages_count,
		[TotalMB] =(cached_pages_count * 8.0) / 1024,
		[GrandTotal] =  CAST( ((SUM(cached_pages_count) OVER() * 8.0) / 1024 ) AS DECIMAL(18,2)),
        R.index_id,
		I.name AS IndexName FROM Dados R
		LEFT JOIN sys.indexes AS I ON R.object_id = I.object_id AND R.index_id = I.index_id
		ORDER BY R.cached_pages_count DESC


