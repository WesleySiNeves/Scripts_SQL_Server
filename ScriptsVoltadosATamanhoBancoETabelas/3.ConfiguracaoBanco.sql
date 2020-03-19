

DECLARE @ExibirNiveisCompatilidade BIT = 0;


IF (OBJECT_ID('TEMPDB..#NiveisCompatibilidade') IS NOT NULL)
    DROP TABLE #NiveisCompatibilidade;

CREATE TABLE #NiveisCompatibilidade
(
    Id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
    Product VARCHAR(100) NOT NULL,
    VersaoMecanismoBancoDados VARCHAR(5) NOT NULL,
    NivelCompatibilidade INT NOT NULL,
    ValoresNívelCompatibilidade VARCHAR(100) NOT NULL,
);

INSERT INTO #NiveisCompatibilidade
(
    Product,
    VersaoMecanismoBancoDados,
    NivelCompatibilidade,
    ValoresNívelCompatibilidade
)
VALUES
('SQL Server 2017 (14.x)', '14', 140, '140, 130, 120, 110, 100'),
('Servidor lógico SQL do Azure', '12', 130, '140, 130, 120, 110, 100'),
('SQL do Azure Instância gerenciada', '12', 130, '140, 130, 120, 110, 100'),
('SQL Server 2016 (13.x)', '13', 130, '130, 120, 110, 100'),
('SQL Server 2014 (12.x)', '12', 120, '120, 110, 100'),
('SQL Server 2012 (11.x)', '11', 110, '110, 100, 90'),
('SQL Server 2008 R2', '10.5', 100, '100, 90, 80'),
('SQL Server 2008', '10', 100, '100, 90, 80'),
('SQL Server 2005', '9', 90, '90, 80'),
('SQL Server 2000', '8', 90, '80, 80');



IF (@ExibirNiveisCompatilidade = 1)
BEGIN

    SELECT *
    FROM #NiveisCompatibilidade AS NC;
END;





--[Data Criacao] = CONVERT(VARCHAR(11), D.create_date, 103),
SELECT 
       @@VERSION AS InstanceInstaller,
		[DataBaseName] =D.name,
       D.database_id,
       --D.owner_sid,
       [Data Criacao] = CONVERT(VARCHAR(11), D.create_date, 103),
	   
       [compatibility_level] = D.compatibility_level,
	   NC.Versoes,
       D.collation_name,
       D.user_access_desc,
       D.is_read_only,
       --D.is_auto_close_on,
       D.is_auto_shrink_on,
       D.state_desc,
       D.snapshot_isolation_state_desc,
       D.is_read_committed_snapshot_on,
       D.recovery_model_desc,
       D.page_verify_option_desc,
       D.is_auto_create_stats_on,
       D.is_auto_create_stats_incremental_on,
       D.is_auto_update_stats_on,
       D.is_auto_update_stats_async_on,
       D.is_ansi_null_default_on,
       D.is_ansi_nulls_on,
       D.is_ansi_warnings_on,
       D.is_arithabort_on,
       D.is_concat_null_yields_null_on,
       D.is_numeric_roundabort_on,
       D.is_quoted_identifier_on,
       D.is_fulltext_enabled,
       D.is_trustworthy_on,
       D.is_query_store_on,
       D.is_sync_with_backup,
       D.log_reuse_wait_desc,
       D.is_date_correlation_on,
       D.is_cdc_enabled,
       D.containment_desc,
       D.is_mixed_page_allocation_on,
       D.is_temporal_history_retention_enabled
FROM sys.databases AS D
 LEFT JOIN 
(

SELECT NC.NivelCompatibilidade,
       
	   STRING_AGG(NC.Product, '/')  Versoes
FROM #NiveisCompatibilidade AS NC 
GROUP BY NC.NivelCompatibilidade
) AS NC ON D.compatibility_level = NC.NivelCompatibilidade
 
ORDER BY D.database_id;

