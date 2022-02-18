

-- Ensure a USE <databasename> statement has been executed first.

;WITH Dados
  AS (SELECT S3.name AS SchemaName,
             T.name AS TableName,
             i.name AS IndexName,
             (SUM(s.used_page_count) * 8) AS IndexSizeKB,
             CAST(((SUM(s.used_page_count) * 8.0) / 1024) AS DECIMAL(18, 3)) AS IndexSizeMB
        FROM sys.dm_db_partition_stats AS s
       INNER JOIN sys.indexes AS i
        JOIN      sys.tables AS T
          ON i.object_id = T.object_id
        JOIN      sys.schemas AS S3
          ON T.schema_id = S3.schema_id
       INNER JOIN sys.sysindexes AS S2
          ON S2.id = i.object_id
         AND S2.indid = 1
          ON s.object_id = i.object_id
         AND s.index_id  = i.index_id
       WHERE S2.rows > 0
       GROUP BY S3.name,
                T.name,
                i.name)
SELECT ObjectName = CONCAT(R.SchemaName, '.', R.TableName),
       R.IndexName,
       R.IndexSizeKB,
       R.IndexSizeMB

  FROM Dados R
  

