SELECT dm_mid.object_id,
            s = OBJECT_SCHEMA_NAME(dm_mid.object_id),
            o = OBJECT_NAME(dm_mid.object_id),
            dm_mid.equality_columns,
            dm_mid.inequality_columns,
            dm_mid.included_columns,
            dm_migs.unique_compiles,
			 dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans) Avg_Estimated_Impact,
            magic_benefit_number = dm_migs.avg_total_user_cost * dm_migs.avg_user_impact
                                   * (dm_migs.user_seeks + dm_migs.user_scans),
            dm_migs.user_seeks,
            dm_migs.last_user_seek,
            dm_migs.user_scans,
            dm_migs.last_user_scan,
            NomeIndex = 'IDX_' + OBJECT_SCHEMA_NAME(dm_mid.object_id, dm_mid.database_id)
                        + OBJECT_NAME(dm_mid.object_id, dm_mid.database_id)
                        + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '')
                        + CASE
                              WHEN dm_mid.equality_columns IS NOT NULL
                                   AND dm_mid.inequality_columns IS NOT NULL THEN
                                  '_'
                              ELSE
                                  ''
                          END
                        + REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns, ''), ', ', '_'), '[', ''), ']', '')
           
     FROM sys.dm_db_missing_index_details AS dm_mid
          INNER JOIN
          sys.dm_db_missing_index_groups AS dm_mig ON dm_mid.index_handle = dm_mig.index_handle
          INNER JOIN
          sys.dm_db_missing_index_group_stats AS dm_migs ON dm_mig.index_group_handle = dm_migs.group_handle
     WHERE dm_mid.database_id = DB_ID()
	 ORDER BY OBJECT_SCHEMA_NAME(dm_mid.object_id),OBJECT_NAME(dm_mid.object_id)


