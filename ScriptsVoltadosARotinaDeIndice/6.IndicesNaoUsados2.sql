USE Lancamentos;
SELECT OBJECT_NAME(ix.object_id) AS ObjectName,
       ix.name,
       ix.type_desc
FROM sys.indexes AS ix
    INNER JOIN sys.objects AS o
        ON ix.object_id = o.object_id
WHERE ix.index_id NOT IN (
                             SELECT ixu.index_id
                             FROM sys.dm_db_index_usage_stats AS ixu
                             WHERE ixu.object_id = ix.object_id
                                   AND ixu.index_id = ix.index_id
                                   AND database_id = DB_ID()
                         )
      AND o.[type] = 'U'
      AND ix.type_desc NOT IN ( 'CLUSTERED', 'HEAP' )
ORDER BY OBJECT_NAME(ix.object_id) ASC;

