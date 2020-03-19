USE master;
GO

/* ==================================================================
--Data: 07/01/2020 
--Autor :Wesley Neves
--Observação: Para determinar o que está impedindo o truncamento de log, execute a consulta mostrada na Listagem
 
 analisar a coluna LOG_REUSE_WAIT_DESC
 Description of LOG_REUSE_WAIT_DESC column for [sys].[databases]
-- ==================================================================
*/
SELECT [database_id],
       [name] AS 'database_name',
       [state_desc],
       [recovery_model_desc],
       [log_reuse_wait_desc]
  FROM [sys].[databases];