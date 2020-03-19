

WITH Dados
  AS (SELECT 
            Tabela = CONCAT('[',SCHEMA_NAME(o.schema_id),']','.','[',OBJECT_NAME(stats.object_id),']'),
             stats.name AS Statistica,
			 par.rows,
             STATS_DATE(stats.object_id, stats.stats_id) AS UpdateDate
        FROM sys.stats
        JOIN sys.objects o
          ON stats.object_id = o.object_id
		  JOIN
     sys.partitions par ON par.object_id = o.object_id
       WHERE stats.object_id IN ( SELECT objects.object_id FROM sys.objects WHERE objects.type = 'U' )
	   AND par.rows > 1000
	   )
	   
SELECT R.Tabela,
		R.rows,
       R.Statistica,
       R.UpdateDate
  FROM Dados R
  WHERE R.UpdateDate < DATEADD(MONTH,-1,GETDATE())

  OR R.UpdateDate IS NULL

  


 
--   AND STATS_DATE(stats.object_id, stats.stats_id) IS NULL;
