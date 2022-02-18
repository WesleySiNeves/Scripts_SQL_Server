
WITH    Dados
          AS ( SELECT   statement_start_offset,
						 last_execution_time,
						creation_time,
                        total_worker_time / execution_count AS Avg_CPU_Time ,
                        execution_count ,
                        total_elapsed_time / execution_count AS AVG_Run_Time ,
                        ( SELECT    SUBSTRING(text, statement_start_offset / 2,
                                              ( CASE WHEN statement_end_offset = -1
                                                     THEN LEN(CONVERT(NVARCHAR(MAX), text))
                                                          * 2
                                                     ELSE statement_end_offset
                                                END - statement_start_offset )
                                              / 2)
                          FROM      sys.dm_exec_sql_text(sql_handle)
                        ) AS query_text
               FROM     sys.dm_exec_query_stats
             )

			 SELECT Dados.statement_start_offset ,
                    Dados.last_execution_time ,
                    Dados.creation_time ,
                    Dados.Avg_CPU_Time ,
                    Dados.execution_count ,
                    Dados.AVG_Run_Time ,
                    Dados.query_text FROM Dados
					--WHERE Dados.query_text LIKE N'%TipoMovimento%'
			 
	


	
	