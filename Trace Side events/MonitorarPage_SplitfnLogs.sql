

SET STATISTICS IO ON 
SELECT
    [AllocUnitName] AS N'Index',
    (CASE [Context]
        WHEN N'LCX_INDEX_LEAF' THEN N'Nonclustered'
        WHEN N'LCX_CLUSTERED' THEN N'Clustered'
        ELSE N'Non-Leaf'
    END) AS [SplitType],
    COUNT (1) AS [SplitCount]
FROM
    fn_dblog (NULL, NULL)
WHERE
    [Operation] = N'LOP_DELETE_SPLIT'
	AND fn_dblog.AllocUnitName NOT LIKE '%plan_persist%'
GROUP BY [AllocUnitName], [Context]
ORDER BY  [SplitCount] DESC

GO


SELECT
OBJECT_SCHEMA_NAME(ios.object_id) + '.' + OBJECT_NAME(ios.object_id) as table_name
,i.name as index_name
,leaf_allocation_count
,nonleaf_allocation_count
--into #dm_db_index_operational_stats2
FROM sys.dm_db_index_operational_stats(DB_ID(), null,NULL, NULL) ios
INNER JOIN sys.indexes i ON i.object_id = ios.object_id AND i.index_id = ios.index_id
WHERE ios.leaf_allocation_count > 0
AND i.name NOT LIKE '%plan_persist%'
ORDER BY leaf_allocation_count DESC


SET STATISTICS IO OFF