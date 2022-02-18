SELECT op.actual_state_desc AS AtualEstado,
       op.current_storage_size_mb AS [TamanhoAtual(MB)],
       op.max_storage_size_mb AS [TamanhoMaximo(MB)],
       op.interval_length_minutes AS [Intervalo de Coleta de Estatísticas(min)],
	   op.stale_query_threshold_days AS [Limite de Consulta Obsoleto(days)],
	   op.size_based_cleanup_mode_desc AS [Modo Auto Lipeza],
	   op.query_capture_mode_desc AS [ModoCaptura],
       IIF(op.readonly_reason = 1, 'SIM', 'NÂO') AS SomenteLeitura
  FROM sys.database_query_store_options op;

/*Se o tamanho maximo estiver chegando perto , vc tem que fazer um flush ou aumentar o tamanho*/



--  ALTER DATABASE [QueryStoreDB]  
--SET QUERY_STORE (MAX_STORAGE_SIZE_MB = 1024);  

/*Se precisar aumentar ou diminuir o intervalo de coleta */
--ALTER DATABASE [cra-sp-hml.implantadev.net.br] SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 30);  