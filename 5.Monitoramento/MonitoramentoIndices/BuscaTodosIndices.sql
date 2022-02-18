DECLARE @type VARCHAR(30) = 'NONCLUSTERED';
DECLARE @SomenteUsado BIT = 1;

WITH Dados
  AS (SELECT sch.name + '.' + tbl.name AS [Table Name],
			ind.object_id,
             ind.name AS [Index Name],
             ind.index_id AS [Index_id],
             ind.type_desc,
             ISNULL(ius.user_seeks + ius.user_scans + ius.user_lookups, 0) AS [Total Reads],
             ISNULL(ius.user_updates, 0) AS [Total Writes],
             ius.last_user_seek,
             ius.last_user_scan,
             ius.last_user_lookup,
             (ps.reserved_page_count * 8.0) / 1024 AS [SpaceUsed_MB]
      FROM sys.indexes AS ind
           FULL OUTER JOIN
           sys.dm_db_index_usage_stats AS ius ON ius.object_id = ind.object_id
                                                 AND ius.index_id = ind.index_id
                                                 AND ius.database_id = DB_ID()
                                                 AND OBJECTPROPERTY(ius.object_id, 'IsUserTable') = 1
           INNER JOIN
           sys.tables AS tbl ON ind.object_id = tbl.object_id
           INNER JOIN
           sys.schemas AS sch ON tbl.schema_id = sch.schema_id
           LEFT OUTER JOIN
           sys.dm_db_partition_stats AS ps ON ind.index_id = ps.index_id
                                              AND ind.object_id = ps.object_id
      --WHERE ius.object_id = OBJECT_ID('sales.SalesOrderHeader')
      WHERE ind.type_desc = @type
     )
SELECT *
FROM Dados R
WHERE @SomenteUsado = 1
      AND R.[Total Reads] > 0
      OR @SomenteUsado = 0
ORDER BY
    R.[Table Name],
    R.[Index Name];