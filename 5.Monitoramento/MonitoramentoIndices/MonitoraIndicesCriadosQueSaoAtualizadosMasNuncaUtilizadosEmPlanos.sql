SELECT 
--'[' + DB_NAME() + '].[' + su.name + '].[' + o.name + ']' AS [statement],
       i.name AS [index_name],
       ddius.user_seeks + ddius.user_scans + ddius.user_lookups AS [user_reads],
       ddius.user_updates AS [user_writes],
       SUM(SP.rows) AS [total_rows]
FROM sys.dm_db_index_usage_stats ddius
     INNER JOIN
     sys.indexes i ON ddius.object_id = i.object_id AND i.index_id = ddius.index_id
     INNER JOIN
     sys.partitions SP ON ddius.object_id = SP.object_id AND SP.index_id = ddius.index_id
     INNER JOIN sys.objects o ON ddius.object_id = o.object_id
    -- INNER JOIN
   --  sys.sysusers su ON o.schema_id = su.uid
WHERE

       OBJECTPROPERTY(ddius.object_id, 'IsUserTable') = 1
      AND ddius.index_id > 0
GROUP BY
   -- su.name,
    o.name,
    i.name,
    ddius.user_seeks + ddius.user_scans + ddius.user_lookups,
    ddius.user_updates
HAVING ddius.user_seeks + ddius.user_scans + ddius.user_lookups = 0
ORDER BY
    ddius.user_updates DESC,
   -- su.name,
    o.name,
    i.[name ];