SELECT  
        
        i.[name] AS 'index_name' ,
        ddios.[partition_number] ,
        ddios.[row_lock_count] ,
        ddios.[row_lock_wait_count] ,
        CAST (100.0 * ddios.[row_lock_wait_count]
        / ( ddios.[row_lock_count] ) AS DECIMAL(5, 2)) AS [%_times_blocked] ,
        ddios.[row_lock_wait_in_ms] ,
        CAST (1.0 * ddios.[row_lock_wait_in_ms]
        / ddios.[row_lock_wait_count] AS DECIMAL(15, 2))
             AS [avg_row_lock_wait_in_ms]
FROM    sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) ddios
        INNER JOIN sys.indexes i ON ddios.[object_id] = i.[object_id]
                                     AND i.[index_id] = ddios.[index_id]
        INNER JOIN sys.objects o ON ddios.[object_id] = o.[object_id]
WHERE   ddios.row_lock_wait_count > 0
        AND OBJECTPROPERTY(ddios.[object_id], 'IsUserTable') = 1
        AND i.[index_id] > 0
ORDER BY ddios.[row_lock_wait_count] DESC ,
        
        o.[name] ,
        i.[name ]