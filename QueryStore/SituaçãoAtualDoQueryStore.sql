SELECT DQSO.actual_state_desc AS ModoAtual,
      readonly_reason = CASE DQSO.readonly_reason WHEN 1 THEN 'o banco de dados est� no modo somente leitura'
       WHEN 2 THEN 'o banco de dados est� no modo de usu�rio �nico'
       WHEN 4 THEN 'o banco de dados est� no modo de emerg�ncia'
       WHEN 8 THEN 'o banco de dados � uma r�plica secund�ria (aplica-se a Always on e Banco de Dados SQL do Azure replica��o geogr�fica)'
       WHEN 65536 THEN 'o reposit�rio de consultas atingiu o limite de tamanho definido pela MAX_STORAGE_SIZE_MB'
       WHEN 131072 THEN 'o n�mero de instru��es diferentes em reposit�rio de consultas atingiu o limite de mem�ria interna' END,
	   
       DQSO.current_storage_size_mb AS TamanhoAtual,
       DQSO.max_storage_size_mb AS TamanhoMaximo,
       flush_interval_Minutos = DQSO.flush_interval_seconds / 60,
       DQSO.interval_length_minutes [Intervalo de Coleta de Estat�sticas],
       DQSO.stale_query_threshold_days [Limite de Consulta Obsoleta (Dias)],
	   
       DQSO.size_based_cleanup_mode_desc,
	   DQSO.capture_policy_stale_threshold_hours
  FROM sys.database_query_store_options AS DQSO;
