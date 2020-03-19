WITH Dados
  AS (SELECT indexes.name AS index_name,
             objects.name AS object_name,
             objects.type_desc AS object_type_description,
             COUNT(*) AS buffer_cache_pages,
             COUNT(*) * 8 / 1024 AS buffer_cache_used_MB
        FROM sys.dm_os_buffer_descriptors
       INNER JOIN sys.allocation_units
          ON allocation_units.allocation_unit_id   = dm_os_buffer_descriptors.allocation_unit_id
       INNER JOIN sys.partitions
          ON (   (   allocation_units.container_id = partitions.hobt_id
               AND   type IN ( 1, 3 ))
            OR   (   allocation_units.container_id = partitions.partition_id
               AND   type IN ( 2 )))
       INNER JOIN sys.objects
          ON partitions.object_id                  = objects.object_id
       INNER JOIN sys.indexes
          ON objects.object_id                     = indexes.object_id
         AND partitions.index_id                   = indexes.index_id
       WHERE allocation_units.type IN ( 1, 2, 3 )
         AND objects.is_ms_shipped                = 0
         AND dm_os_buffer_descriptors.database_id = DB_ID()
       GROUP BY indexes.name,
                objects.name,
                objects.type_desc)
SELECT Indice = R.index_name,
       Tabela = R.object_name,
       object_type_description = R.object_type_description,
       R.buffer_cache_pages,
       R.buffer_cache_used_MB,
	   [TotalAlocado MB] = SUM(R.buffer_cache_used_MB) OVER()
  FROM Dados R
 ORDER BY R.buffer_cache_used_MB DESC;


 