SELECT DQSO.actual_state_desc AS ModoAtual,
      readonly_reason = CASE DQSO.readonly_reason WHEN 1 THEN 'o banco de dados está no modo somente leitura'
       WHEN 2 THEN 'o banco de dados está no modo de usuário único'
       WHEN 4 THEN 'o banco de dados está no modo de emergência'
       WHEN 8 THEN 'o banco de dados é uma réplica secundária (aplica-se a Always on e Banco de Dados SQL do Azure replicação geográfica)'
       WHEN 65536 THEN 'o repositório de consultas atingiu o limite de tamanho definido pela MAX_STORAGE_SIZE_MB'
       WHEN 131072 THEN 'o número de instruções diferentes em repositório de consultas atingiu o limite de memória interna' END,
	   
       DQSO.current_storage_size_mb AS TamanhoAtual,
       DQSO.max_storage_size_mb AS TamanhoMaximo,
       flush_interval_Minutos = DQSO.flush_interval_seconds / 60,
       DQSO.interval_length_minutes [Intervalo de Coleta de Estatísticas],
       DQSO.stale_query_threshold_days [Limite de Consulta Obsoleta (Dias)],
	   
       DQSO.size_based_cleanup_mode_desc,
	   DQSO.capture_policy_stale_threshold_hours
  FROM sys.database_query_store_options AS DQSO;
