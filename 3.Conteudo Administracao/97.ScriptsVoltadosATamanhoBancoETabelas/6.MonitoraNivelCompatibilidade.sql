 
/*
O SQL Server 2014 inclui melhorias significativas no componente criado por ele e planos de consulta otimizados. 
Esse novo recurso do otimizador de consulta depende do uso do nível de compatibilidade de banco de dados 120.
 Novos aplicativos de banco de dados devem ser desenvolvidos usando o nível de compatibilidade de banco de dados 120
  para tirar proveito dessas melhorias. Os aplicativos migrados de versões anteriores do SQL Server
   devem ser cuidadosamente testados para confirmar que o bom desempenho será mantido ou melhorado. 
   Se o desempenho diminuir, você poderá definir o nível de compatibilidade de banco de dados como 110 ou menos,
    a fim de usar a metodologia de otimizador de consulta mais antiga.
*/
--Leia isso antes
--https://technet.microsoft.com/en-us/library/bb510680(v=sql.110).aspx


/*

AQUI VC VAI VER A IMAGEM DE CADA NUMERO
--https://msdn.microsoft.com/pt-br/library/bb510680.aspx
*/

/*
ALTER DATABASE database_name   
SET COMPATIBILITY_LEVEL = { 140 | 130 | 120 | 110 | 100 | 90 }  
*/
SELECT compatibility_level
    FROM sys.databases
    WHERE name = 'Implanta';
  --110

SELECT D.database_id ,
        D.name ,
        CONVERT(VARCHAR(10), D.create_date, 103) AS [Data de Criação] ,
        D.compatibility_level ,
        [Compativel com ] = ( CASE WHEN D.compatibility_level = 80
                                   THEN 'SQL Server 2000'
                                   WHEN D.compatibility_level = 90
                                   THEN 'SQL Server 2005'
                                   WHEN D.compatibility_level = 100
                                   THEN 'SQL Server 2008'
                                   WHEN D.compatibility_level = 105
                                   THEN 'SQL Server 2008 R2'
                                   WHEN D.compatibility_level = 110
                                   THEN 'SQL Server 2012'
                                   WHEN D.compatibility_level = 120
                                   THEN 'SQL Server 2014 - Banco de Dados SQL'
                                   WHEN D.compatibility_level = 130
                                   THEN 'SQL Server 2016'
                                   WHEN D.compatibility_level = 140
                                   THEN 'SQL Server vNext'
                              END ) ,
        D.page_verify_option_desc ,
        D.recovery_model_desc ,
        D.collation_name ,
        D.user_access_desc ,
        D.is_read_only ,
        D.is_auto_close_on ,
        D.is_auto_shrink_on ,
        D.state_desc ,
        D.snapshot_isolation_state_desc ,
        D.is_read_committed_snapshot_on ,
        D.is_auto_create_stats_on ,
        D.is_auto_update_stats_on ,
        D.is_auto_update_stats_async_on ,
        D.is_ansi_null_default_on ,
        D.is_ansi_nulls_on ,
        D.is_ansi_padding_on ,
        D.is_ansi_warnings_on ,
        D.is_arithabort_on ,
        D.is_concat_null_yields_null_on ,
        D.is_numeric_roundabort_on ,
        D.is_quoted_identifier_on ,
        D.is_recursive_triggers_on ,
        D.is_cursor_close_on_commit_on ,
        D.is_local_cursor_default ,
        D.is_fulltext_enabled ,
        D.is_trustworthy_on ,
        D.is_db_chaining_on ,
        D.is_parameterization_forced ,
        D.is_master_key_encrypted_by_server ,
        D.is_published ,
        D.is_subscribed ,
        D.is_merge_published ,
        D.is_distributor ,
        D.is_sync_with_backup ,
        D.log_reuse_wait ,
        D.log_reuse_wait_desc ,
        D.is_date_correlation_on ,
        D.is_cdc_enabled ,
        D.is_encrypted ,
        D.is_honor_broker_priority_on ,
        D.containment ,
        D.containment_desc ,
        D.target_recovery_time_in_seconds
    FROM sys.databases AS D
    WHERE D.name LIKE '%Implanta%';

--ALTER DATABASE TSQL2012 SET COMPATIBILITY_LEVEL =100

--UPDATE STATISTICS Despesa.RelacoesCreditosSaidas WITH FULLSCAN;