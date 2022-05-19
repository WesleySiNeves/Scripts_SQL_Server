SELECT DB_NAME() databaseName,
       SUM(p.rows) totalRows,
       SUM(a.data_pages) numDataPages,
	   ((SUM(a.data_pages) * 8 ) / 1024.0) /1024.0 GB
FROM sys.objects o
    JOIN sys.indexes i
        ON o.object_id = i.object_id
    JOIN sys.partitions p
        ON i.object_id = p.object_id
           AND i.index_id = p.index_id
    JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
WHERE o.is_ms_shipped = 0
      AND o.type = 'U';