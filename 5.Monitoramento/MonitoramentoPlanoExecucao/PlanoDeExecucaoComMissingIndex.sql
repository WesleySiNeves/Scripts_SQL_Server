

DROP TABLE IF EXISTS #candidates;

IF ( OBJECT_ID('TEMPDB..#candidates') IS NOT NULL )
    DROP TABLE #candidates;	

DROP TABLE IF EXISTS #planops;


CREATE TABLE #candidates (
                        [object_id]          INT,
                        [s]                  NVARCHAR(128),
                        [o]                  NVARCHAR(128),
                        [equality_columns]   NVARCHAR(4000),
                        [inequality_columns] NVARCHAR(4000),
                        [included_columns]   NVARCHAR(4000),
                        [unique_compiles]    BIGINT,
                        [user_seeks]         BIGINT,
                        [last_user_seek]     DATETIME,
                        [user_scans]         BIGINT,
                        [last_user_scan]     DATETIME
                        );




INSERT INTO #candidates 
SELECT d.object_id,
       s = OBJECT_SCHEMA_NAME(d.object_id),
       o = OBJECT_NAME(d.object_id),
       d.equality_columns,
       d.inequality_columns,
       d.included_columns,
       s.unique_compiles,
       s.user_seeks,
       s.last_user_seek,
       s.user_scans,
       s.last_user_scan
FROM sys.dm_db_missing_index_details AS d
     INNER JOIN
     sys.dm_db_missing_index_groups AS g ON d.index_handle = g.index_handle
     INNER JOIN
     sys.dm_db_missing_index_group_stats AS s ON g.index_group_handle = s.group_handle
WHERE d.database_id = DB_ID()
      AND OBJECTPROPERTY(d.object_id, 'IsMsShipped') = 0;



WITH XMLNAMESPACES (
                   DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
                   )
SELECT T.o,
       T.i,
       T.h,
       T.uc,
       T.Scan_Ops,
       T.Seek_Ops,
       T.Update_Ops
INTO #planops
FROM (
     SELECT o = i.object_id,
            i = i.index_id,
            h = pl.plan_handle,
            uc = pl.usecounts,
            Scan_Ops = p.query_plan.value(
                                             'count(//RelOp[@LogicalOp 
	     = ("Index Scan", "Clustered Index Scan")]/*/Object[@Index = sql:column("i2.name")])',
                                             'int'
                                         ),
            Seek_Ops = p.query_plan.value(
                                             'count(//RelOp[@LogicalOp 
	     = ("Index Seek", "Clustered Index Seek")]/*/Object[@Index = sql:column("i2.name")])',
                                             'int'
                                         ),
            Update_Ops = p.query_plan.value('count(//Update/Object[@Index = sql:column("i2.name")])', 'int')
     FROM sys.indexes AS i
          CROSS APPLY (
                      SELECT QUOTENAME(i.name) AS name
                      ) AS i2
          CROSS APPLY sys.dm_exec_cached_plans AS pl
          CROSS APPLY sys.dm_exec_query_plan(pl.plan_handle) AS p
     WHERE EXISTS (
                  SELECT 1
                  FROM #candidates AS c
                  WHERE c.object_id = i.object_id
                  )
           AND p.query_plan.exist('//Object[@Index = sql:column("i2.name")]') = 1
           AND p.dbid = DB_ID()
           AND i.index_id > 0
     ) AS T
WHERE T.Scan_Ops + T.Seek_Ops + T.Update_Ops > 0;




SELECT OBJECT_SCHEMA_NAME(po.o),
       OBJECT_NAME(po.o),
       po.uc,
       po.Scan_Ops,
       po.Seek_Ops,
       po.Update_Ops,
       p.query_plan
FROM #planops AS po
     CROSS APPLY sys.dm_exec_query_plan(po.h) AS p;