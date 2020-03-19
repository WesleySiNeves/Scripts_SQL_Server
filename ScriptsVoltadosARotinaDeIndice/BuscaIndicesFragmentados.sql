
SELECT ixs.index_id AS idx_id,
       ix.name AS ObjectName,
       index_type_desc,
       page_count,
	   ixs.avg_record_size_in_bytes,
       avg_page_space_used_in_percent AS AvgPageSpacePct,
       fragment_count AS frag_ct,
       avg_fragmentation_in_percent AS AvgFragPct
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'Detailed') ixs
    INNER JOIN sys.indexes ix
        ON ixs.index_id = ix.index_id
           AND ixs.object_id = ix.object_id
ORDER BY avg_fragmentation_in_percent ;