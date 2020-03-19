WITH Dados
    AS
    (
	

			SELECT DB_NAME(DB_ID()) AS DataBaseName,
				   file_id ,
				   name FileName,
				   type_desc,
				   ISNULL((SUM(S.size * 8192.) / 1024 / 1024 / 1024), 0) SizeInGB,
				   ISNULL(SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192.), 0) AS DatabaseSpaceUsedInBytes,
				   ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024), 0) AS DatabaseSpaceUsedInMB,
				   ISNULL((SUM(CAST(FILEPROPERTY(NAME, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 / 1024), 0) AS DatabaseSSpaceUsedInGB
			FROM sys.database_files S
			GROUP BY
				FILE_ID,
				NAME,
				type_desc
    )
SELECT (
           SELECT TOP 1 C.Valor
             FROM Sistema.Configuracoes AS C
            WHERE
               C.Configuracao = 'SiglaCliente'
       ) AS Cliente,
	   DA.name ,
	   D.file_id,
	   D.type_desc,
	   D.FileName,
	   D.SizeInGB,
       D.DatabaseSpaceUsedInBytes,
       CAST(D.DatabaseSpaceUsedInMB AS DECIMAL(18, 2)) AS DatabaseSpaceUsedInMB,
       CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) AS DatabaseSSpaceUsedInGB,
	   TargetPercent = CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) * 1.2,
	   Script = CONCAT('DBCC SHRINKFILE (', D.FileName,',', CAST(D.DatabaseSSpaceUsedInGB AS DECIMAL(18, 2)) * 1.2,')'),
	   DA.user_access_desc,
       DA.compatibility_level,
	   DA.collation_name,
	   DA.is_auto_close_on,
       DA.is_auto_shrink_on,
       DA.snapshot_isolation_state_desc,
       DA.recovery_model_desc,
       DA.page_verify_option_desc,
       DA.is_auto_create_stats_on,
       DA.is_auto_update_stats_on,
       DA.state_desc,
       DA.snapshot_isolation_state_desc,
       DA.is_read_committed_snapshot_on,
       DA.recovery_model_desc,
       DA.is_auto_create_stats_on,
       DA.is_auto_update_stats_on,
       DA.is_query_store_on,
       DA.catalog_collation_type_desc,
       DA.is_memory_optimized_enabled		
  FROM Dados D
       JOIN sys.databases DA ON D.DataBaseName = DA.name
 --WHERE
 --   type_desc = 'ROWS';


