;WITH Dados
    AS
    (
        SELECT DB_NAME(DB_ID()) AS DataBaseName,
               file_id,
               name FileName,
               type_desc,
               ISNULL((SUM(S.size * 8192.) / 1024 / 1024 / 1024), 0) SizeInGB,
               ISNULL((SUM(S.max_size * 8192.) / 1024 / 1024 / 1024), 0) MaxSizeInGB,
               ISNULL((SUM(S.growth * 8192.) / 1024 / 1024), 0) GrowthInMB,
               ISNULL(SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192.), 0) AS DatabaseSpaceUsedInBytes,
               ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024), 0) AS DatabaseSpaceUsedInMB,
               ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 / 1024), 0) AS DatabaseSSpaceUsedInGB
          FROM sys.database_files S
         GROUP BY
            FILE_ID,
            NAME,
            type_desc
    ),
      Detalhes
    AS
    (
        SELECT (
                   SELECT TOP 1 C.Valor
                     FROM Sistema.Configuracoes AS C
                    WHERE
                       C.Configuracao = 'SiglaCliente'
               ) AS Cliente,
               DA.name,
               D.file_id,
               D.type_desc,
               D.FileName,
               CAST(D.SizeInGB AS DECIMAL(18, 2)) SizeInGB,
			   CAST(D.MaxSizeInGB AS DECIMAL(18, 2)) MaxSizeInGB,
			   [% PorcentagemDadosPreenchidos] =  CAST((CAST(D.SizeInGB AS DECIMAL(18, 2)) /CAST(D.MaxSizeInGB AS DECIMAL(18, 2)))  *100 AS DECIMAL(18,2)) ,
               CAST(D.GrowthInMB AS DECIMAL(18, 2)) GrowthInMB,
               CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) AS DatabaseSpaceUsedInGB,
               DatabaseSpaceNonUsedInGB = CAST((ROUND((D.SizeInGB - CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2))), 2)) AS DECIMAL(18, 2)),
			   
               Script = CONCAT('DBCC SHRINKFILE (', D.FileName, ',', CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) * 1.2, ')'),
               TargetPercent = CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) * 1.2,
               DA.user_access_desc,
               DA.compatibility_level,
               DA.collation_name,
               CAST(D.DatabaseSpaceUsedInMB AS DECIMAL(18, 2)) AS DatabaseSpaceUsedInMB,
               D.DatabaseSpaceUsedInBytes,
               DA.is_auto_close_on,
               DA.is_auto_shrink_on,
               DA.snapshot_isolation_state_desc,
               DA.recovery_model_desc,
               DA.page_verify_option_desc,
               DA.state_desc,
               DA.is_read_committed_snapshot_on,
               DA.is_auto_create_stats_on,
               DA.is_auto_update_stats_on,
               DA.is_query_store_on,
               DA.catalog_collation_type_desc,
               DA.is_memory_optimized_enabled
          FROM Dados D
               JOIN sys.databases DA ON D.DataBaseName = DA.name
    )
SELECT R.* FROM Detalhes R WHERE type_desc IN ('ROWS', 'LOG');
