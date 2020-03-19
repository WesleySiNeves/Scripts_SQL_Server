DROP TABLE IF EXISTS #candidates;

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
--INTO #candidates
FROM sys.dm_db_missing_index_details AS d
     INNER JOIN
     sys.dm_db_missing_index_groups AS g ON d.index_handle = g.index_handle
     INNER JOIN
     sys.dm_db_missing_index_group_stats AS s ON g.index_group_handle = s.group_handle;

--SELECT *
--FROM #candidates AS C;



DROP TABLE IF EXISTS #planops;

CREATE TABLE #planops (
                      o          INT,
                      i          INT,
                      h          VARBINARY(64),
                      uc         INT,
                      Scan_Ops   INT,
                      Seek_Ops   INT,
                      Update_Ops INT
                      );

;WITH XMLNAMESPACES (
                    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
                    )
INSERT #planops
SELECT T.o,
       T.i,
       T.h,
       T.uc,
       T.Scan_Ops,
       T.Seek_Ops,
       T.Update_Ops
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


DROP TABLE IF EXISTS #indexusage;

CREATE TABLE #indexusage (
                         [object_id]    INT,
                         [index_id]     INT,
                         [user_seeks]   BIGINT,
                         [user_scans]   BIGINT,
                         [user_lookups] BIGINT,
                         [user_updates] BIGINT
                         );

INSERT INTO #indexusage
SELECT s.object_id,
       s.index_id,
       s.user_seeks,
       s.user_scans,
       s.user_lookups,
       s.user_updates
FROM sys.dm_db_index_usage_stats AS s
WHERE s.database_id = DB_ID()
      AND EXISTS (
                 SELECT 1
                 FROM #candidates
                 WHERE #candidates.object_id = s.object_id
                 );

;WITH x
   AS (
      SELECT c.object_id,
             potential_read_ops = SUM(c.user_seeks + c.user_scans),
             [write_ops] = SUM(iu.user_updates),
             [read_ops] = SUM(iu.user_scans + iu.user_seeks + iu.user_lookups),
             [write:read ratio] = CONVERT(
                                             DECIMAL(18, 2),
                                             SUM(iu.user_updates) * 1.0
                                             / SUM(iu.user_scans + iu.user_seeks + iu.user_lookups)
                                         ),
             current_plan_count = po.h,
             current_plan_use_count = po.uc
      FROM #candidates AS c
           LEFT OUTER JOIN
           #indexusage AS iu ON c.object_id = iu.object_id
           LEFT OUTER JOIN
           (
           SELECT #planops.o,
                  h = COUNT(#planops.h),
                  uc = SUM(#planops.uc)
           FROM #planops
           GROUP BY
               #planops.o
           ) AS po ON c.object_id = po.o
      GROUP BY
          c.object_id,
          po.h,
          po.uc
      )
SELECT [object] = QUOTENAME(c.s) + '.' + QUOTENAME(c.o),
       c.equality_columns,
       c.inequality_columns,
       c.included_columns,
       x.potential_read_ops,
	   Media = SUM(x.potential_read_ops) OVER() / COUNT(c.object_id) OVER(),
       x.write_ops,
       x.read_ops,
       x.[write:read ratio],
	   BadIndex = IIF(x.[write:read ratio] > 1 OR x.potential_read_ops < 50,'SIM' ,'NÂO'),
       x.current_plan_count,
       x.current_plan_use_count
FROM #candidates AS c
     INNER JOIN
     x ON c.object_id = x.object_id
	 WHERE QUOTENAME(c.s) + '.' + QUOTENAME(c.o) = '[Orcamento].[Dotacoes]'
ORDER BY
    x.[write:read ratio];	


	