/* ==================================================================
--Data: 05/09/2018 
--Autor :Wesley Neves
--Observação: amos em frente e executar a declaração. Este DMV retorna informações sobre os arquivos de log de transação. 
As informações incluem o modelo de recuperação do banco de dados.
 
-- ==================================================================
*/


	select 
	 dbs.name,
	 b2.recovery_model,
	 b2.current_vlf_size_mb,
	 b2.total_vlf_count,
	 b2.active_vlf_count,
	 b2.active_log_size_mb,
	 b2.log_truncation_holdup_reason,
	 b2.log_since_last_checkpoint_mb
  from 
  sys.databases AS dbs
  CROSS APPLY sys.dm_db_log_Stats(dbs.database_id) b2
  where dbs.database_id=b2.database_id
  ORDER BY dbs.database_id