WITH Dados AS (
SELECT 
       o.object_id,
       s.name AS SchemaName,
       o.name AS ObjectName,
       i.name AS IndexName,
       i.index_id AS IndexID,
       i.type, --0 =HEAP / 1 =CLUSTERED / 2= NONCLUSTERED
       dm_ius.user_seeks AS UserSeek,
       dm_ius.user_scans AS UserScans,
	   dm_ius.user_lookups AS UserLookups,
       LeituraNoIndice = (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups),
	   [LeituraNaTabela] = CAST(SUM(dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) OVER (PARTITION BY dm_ius.object_id) AS BIGINT),
	   IOS.leaf_insert_count AS insert_count,
	   IOS.leaf_delete_count AS delete_count, 
	   IOS.leaf_update_count AS update_count,
	   [TotalEscritaNoIndice] =( IOS.leaf_insert_count +IOS.leaf_delete_count + IOS.leaf_update_count),
	   [TotalEscritaTabela] =CAST(SUM( IOS.leaf_insert_count +IOS.leaf_delete_count + IOS.leaf_update_count) OVER (PARTITION BY IOS.object_id) AS BIGINT),
       dm_ius.user_updates AS UserUpdates,
       IOS.leaf_allocation_count AS PAGE_SPLIT_FOR_INDEX,
       IOS.nonleaf_allocation_count PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT,
       p.TableRows,
      i.fill_factor

FROM sys.dm_db_index_usage_stats dm_ius
     INNER JOIN
     sys.indexes i ON i.index_id = dm_ius.index_id
                      AND dm_ius.object_id = i.object_id
    JOIN
     sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) IOS ON i.object_id = IOS.object_id
                                                                         AND i.index_id = IOS.index_id
     INNER JOIN
     sys.objects o ON dm_ius.object_id = o.object_id
     INNER JOIN
     sys.schemas s ON o.schema_id = s.schema_id
     INNER JOIN
     (
     SELECT SUM(p.rows) TableRows,
            p.index_id,
            p.object_id
     FROM sys.partitions p
     GROUP BY
         p.index_id,
         p.object_id
     ) p ON p.index_id = dm_ius.index_id
            AND dm_ius.object_id = p.object_id
WHERE OBJECTPROPERTY(dm_ius.object_id, 'IsUserTable') = 1
      AND dm_ius.database_id = DB_ID()
      AND s.name NOT IN ( 'HangFire' )
      AND i.type > 0
	  AND (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) > 0
      AND p.TableRows > 0
),
Taxas AS (
SELECT R.object_id,
       R.SchemaName,
       R.ObjectName,
       R.IndexName,
	   [% Aproveitamento] = CAST(((R.LeituraNoIndice * 1.0 / IIF(R.LeituraNaTabela = 0, 1, R.LeituraNaTabela)) * 100) AS DECIMAL(18, 2)),
       [write:Custo Medio] = CONVERT(DECIMAL(18, 2), R.TotalEscritaTabela * 1.0 / IIF(R.TotalEscritaTabela = 0, 1, R.TotalEscritaTabela)),
       R.IndexID,
       R.type,
       R.UserSeek,
       R.UserScans,
       R.UserLookups,
       R.LeituraNoIndice,
       R.LeituraNaTabela,
	   R.TotalEscritaTabela,
	   R.TotalEscritaNoIndice,
       R.UserUpdates,
       R.PAGE_SPLIT_FOR_INDEX,
       R.PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT,
       R.TableRows,
	   R.fill_factor FROM Dados R
)

SELECT T.object_id,
       T.SchemaName,
       T.ObjectName,
       T.IndexName,
       T.[% Aproveitamento],
       T.[write:Custo Medio],
	   
       T.IndexID,
       T.type,
       T.UserSeek,
       T.UserScans,
       T.UserLookups,
       T.LeituraNoIndice,
       T.LeituraNaTabela,
	   T.TotalEscritaTabela,
	    --[% Aproveitamento] = CAST(((IX.Reads * 1.0 / IIF(IX.TotalAcessoTabela = 0, 1, IX.TotalAcessoTabela)) * 100) AS DECIMAL(18, 2)),
	   [% MediaX] = CAST(((T.TotalEscritaNoIndice * 1.0 / IIF(T.LeituraNoIndice = 0, 1, T.LeituraNoIndice)) * 100) AS DECIMAL(18, 2)),
      
       T.PAGE_SPLIT_FOR_INDEX,
       T.PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT,
       T.TableRows,
       T.fill_factor FROM Taxas T
	   WHERE T.object_id =718625603
ORDER BY T.LeituraNaTabela DESC






--EXEC BaseLine.spAllIndex @typeIndex = NULL,              -- varchar(40)
--                         @SomenteUsado = NULL,         -- bit
--                         @TableIsEmpty = 0,         -- bit
--                         @ObjectName = NULL,             -- varchar(128)
--                         @BadIndex = NULL,             -- bit
--                         @percentualAproveitamento = 0 -- smallint
