-- Unused Index Script
-- Original Author: Pinal Dave 
/*
https://blog.sqlauthority.com/2011/01/04/sql-server-2008-unused-index-script-download/
*/

WITH Dados
  AS (
     SELECT dm_ius.database_id,
            s.name AS SchemaName,
            o.name AS ObjectName,
            i.name AS IndexName,
            o.create_date,
            TotalDiasBanco = DATEDIFF(DAY, o.create_date, GETDATE()),
            i.index_id AS IndexID,
            dm_ius.user_seeks AS UserSeek,
            dm_ius.user_scans AS UserScans,
            dm_ius.user_lookups AS UserLookups,
            dm_ius.user_updates AS UserUpdates,
            TotalRead = (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups),
            p.TableRows,
            'DROP INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(s.name) + '.'
            + QUOTENAME(OBJECT_NAME(dm_ius.object_id)) AS 'drop statement'
     FROM sys.dm_db_index_usage_stats dm_ius
          INNER JOIN
          sys.indexes i ON i.index_id = dm_ius.index_id
                           AND dm_ius.object_id = i.object_id
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
           AND i.type_desc = 'nonclustered'
           AND i.is_primary_key = 0
           AND i.is_unique_constraint = 0
           AND s.name NOT IN ( 'HangFire' )
     )
SELECT *
FROM Dados R
WHERE R.TotalRead = 0;




