
		
                        
WITH    Dados
          AS ( SELECT 
		        
					[Banco de Dados] = DB_NAME(ST.dbid) ,
					SUBSTRING(ST.text, ( QS.statement_start_offset / 2 ) + 1,
                              ( ( CASE QS.statement_end_offset
                                    WHEN -1 THEN DATALENGTH(ST.text)
                                    ELSE QS.statement_end_offset
                                  END - QS.statement_start_offset ) / 2 ) + 1) AS Request ,
                    [execution_count] = QS.execution_count ,
					 [Inicio] = QS.creation_time,
					 St.objectid,
                    [elapsed_time] = total_elapsed_time ,
                    [AVG TIME] = ( QS.total_elapsed_time / QS.execution_count ) ,
                    [AVG CPU] = ( QS.total_worker_time / QS.execution_count ) ,
					[AVG READ] = ( QS.total_logical_reads / QS.execution_count ) ,
					[AVG WHITE] = ( QS.total_logical_writes / QS.execution_count ),
                    [total_logical_reads] = total_logical_reads ,
                    [total_writes] = total_logical_writes ,
					QS.last_logical_reads,
					QS.last_elapsed_time,
                    [Objeto] = OBJECT_NAME(QP.objectid) ,
                    
                    [Plano Execução] = QP.query_plan
                FROM sys.dm_exec_query_stats AS QS
                CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
                CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) AS QP
                WHERE DB_NAME(ST.dbid) = DB_NAME(DB_ID())
             ),
        Projecao
          AS ( SELECT R.[Banco de Dados] ,
				R.Request ,
                    [Quantidade Execucao] = R.execution_count ,
					R.objectid,
                    [Tempo decorrido Em MiliSegundos] = R.elapsed_time ,
                    [Tempo Total Execucao/Seg] = CAST(( CAST(R.elapsed_time AS DECIMAL(18,
                                                              6))
                                                         / CAST(1000000 AS DECIMAL(18,
                                                              6)) ) AS DECIMAL(18,
                                                              6)) ,
					[Tempo CPU/Seg] = CAST(( CAST(R.[AVG CPU]  AS DECIMAL(18,
                                                              6))
                                                         / CAST(1000000 AS DECIMAL(18,
                                                              6)) ) AS DECIMAL(18,
                                                              6)) ,
					[Media Tempo/Seg] = CAST(( CAST(R.[AVG TIME]  AS DECIMAL(18,
                                                              6))
                                                         / CAST(1000000 AS DECIMAL(18,
                                                              6)) ) AS DECIMAL(18,
                                                              6)) ,
                    [Total Paginas Lidas] = R.total_logical_reads ,
                    [Total MB ((total_logical_reads * 8) / 1024)] = CONCAT(( ( R.total_logical_reads* 8 ) / 1024 ),' MB') ,
					[Total Paginas Lidas em GB] = CONCAT(  CAST(( ( (R.total_logical_reads * 8 ) /  CAST(1024 AS DECIMAL(18,4))) / CAST(1024  AS DECIMAL(18,4))) AS DECIMAL(18,4)),' GB') ,
                    R.[AVG READ] ,
                    R.[AVG WHITE] ,
                    R.Objeto ,
                  
                    R.[Plano Execução]
                FROM Dados R
             )
    SELECT  R.[Banco de Dados] ,
			--	[Ordem] = ROW_NUMBER() OVER(ORDER BY R.Inicio),
			R.Objeto ,
            R.Request ,
			
            R.[Quantidade Execucao] ,
            R.[Tempo Total Execucao/Seg] ,
            R.[Tempo CPU/Seg] ,
            R.[Media Tempo/Seg] ,
            R.[Total Paginas Lidas] ,
            R.[Total MB ((total_logical_reads * 8) / 1024)] ,
            R.[Total Paginas Lidas em GB] ,
            
            R.[Plano Execução]			
        FROM Projecao R
   ORDER BY R.[Media Tempo/Seg] DESC

