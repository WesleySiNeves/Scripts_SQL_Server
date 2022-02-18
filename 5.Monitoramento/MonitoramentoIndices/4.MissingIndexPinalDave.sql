
/* ==================================================================
--Data: 17/09/2018 
--Autor :Wesley Neves
--Observação: Missing Index adaptative
 
-- ==================================================================

*/


DECLARE @ImpactOnQuerys INT = 800;

WITH Dados
  AS (
     SELECT dm_mid.database_id AS DatabaseID,
            dm_migs.avg_user_impact,
            dm_migs.user_seeks,
            dm_migs.user_scans,
            dm_migs.avg_total_user_cost,
            dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) Avg_Estimated_Impact,
            dm_migs.avg_total_user_cost * dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) MediaMelhoria,
            dm_migs.last_user_seek AS Last_User_Seek,
            TableId = dm_mid.object_id,
            SchemaName = OBJECT_SCHEMA_NAME(dm_mid.object_id, dm_mid.database_id),
            OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) AS TableName,
            'CREATE INDEX [IDX_' + OBJECT_SCHEMA_NAME(dm_mid.object_id, dm_mid.database_id)
            + OBJECT_NAME(dm_mid.object_id, dm_mid.database_id)
            + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '')
            + CASE
                  WHEN dm_mid.equality_columns IS NOT NULL
                       AND dm_mid.inequality_columns IS NOT NULL THEN
                      '_'
                  ELSE
                      ''
              END + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns, ''), ', ', '_'), '[', ''), ']', '') + ']'
            + ' ON [' + OBJECT_SCHEMA_NAME(dm_mid.object_id, dm_mid.database_id) + '].['
            + OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) + ']
			  (' + ISNULL(dm_mid.equality_columns, '') + CASE
                                                             WHEN dm_mid.equality_columns IS NOT NULL
                                                                  AND dm_mid.inequality_columns IS NOT NULL THEN
                                                                 ','
                                                             ELSE
                                                                 ''
                                                         END + ISNULL(dm_mid.inequality_columns, '') + ')'
            + ISNULL(' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
     FROM sys.dm_db_missing_index_groups dm_mig
          INNER JOIN
          sys.dm_db_missing_index_group_stats dm_migs ON dm_migs.group_handle = dm_mig.index_group_handle
          INNER JOIN
          sys.dm_db_missing_index_details dm_mid ON dm_mig.index_handle = dm_mid.index_handle
     )
SELECT R.DatabaseID,
       R.avg_user_impact,
       R.user_seeks,
       R.user_scans,
       R.avg_total_user_cost,
       R.MediaMelhoria,
       R.Avg_Estimated_Impact,
       R.Last_User_Seek,
       R.SchemaName,
       R.TableName,
       R.Create_Statement
FROM Dados R
WHERE R.Avg_Estimated_Impact > @ImpactOnQuerys
      OR (R.avg_user_impact > 80  AND (R.user_seeks + R.user_scans) > 15)
ORDER BY
    R.Avg_Estimated_Impact DESC;
