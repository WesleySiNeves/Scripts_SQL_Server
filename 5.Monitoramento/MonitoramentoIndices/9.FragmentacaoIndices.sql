
SET TRAN ISOLATION LEVEL READ UNCOMMITTED ;
SELECT a.*,
       b.AverageFragmentation,
       b.page_count
	   
  FROM (   SELECT tbl.name AS [Table_Name],
                  tbl.object_id,
                  i.name AS [Name],
                  i.index_id,
				  
                  CAST(CASE i.index_id
                            WHEN 1 THEN 1
                            ELSE 0 END AS BIT) AS [IsClustered],
                  CAST(CASE
                            WHEN i.type = 3 THEN 1
                            ELSE 0 END AS BIT) AS [IsXmlIndex],
                  CAST(CASE
                            WHEN i.type = 4 THEN 1
                            ELSE 0 END AS BIT) AS [IsSpatialIndex]
             FROM sys.tables AS tbl
            INNER JOIN sys.indexes AS i
               ON (   i.index_id        > 0
                AND   i.is_hypothetical = 0)
              AND (i.object_id          = tbl.object_id)) a
 INNER JOIN (   SELECT tbl.object_id,
                       i.index_id,
                       fi.avg_fragmentation_in_percent AS [AverageFragmentation],
                       fi.page_count,
                       fi.avg_page_space_used_in_percent
                  FROM sys.tables AS tbl
                 INNER JOIN sys.indexes AS i
                    ON (   i.index_id        > 0
                     AND   i.is_hypothetical = 0)
                   AND (i.object_id          = tbl.object_id)
                 INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS fi
                    ON fi.object_id          = CAST(i.object_id AS INT)
                   AND fi.index_id           = CAST(i.index_id AS INT)) b
    ON a.object_id            = b.object_id
   AND a.index_id             = b.index_id
   AND b.AverageFragmentation > 15
   AND b.page_count >50
 ORDER BY b.AverageFragmentation DESC;

 