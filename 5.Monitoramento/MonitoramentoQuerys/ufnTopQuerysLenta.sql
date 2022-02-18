/* ==================================================================
--Data: 08/11/2018 
--Autor :Wesley Neves
--Observação: 
 
-- ==================================================================
*/

CREATE OR ALTER FUNCTION HealthCheck.[ufnTopQuerysLentas] (@Quantidade SMALLINT =10)
RETURNS TABLE
RETURN
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
					QS.last_elapsed_time,
					qs.last_execution_time,
                    QS.last_logical_reads,
					qs.last_worker_time,
					qs.last_grant_kb,
					qs.last_used_grant_kb,
					qs.last_ideal_grant_kb,
					qs.last_spills,
                    [AVG TIME] = ( QS.total_elapsed_time / QS.execution_count ) ,
                    [AVG CPU] = ( QS.total_worker_time / QS.execution_count ) ,
					[AVG READ] = ( QS.total_logical_reads / QS.execution_count ) ,
					[AVG WHITE] = ( QS.total_logical_writes / QS.execution_count ),
                    [total_logical_reads] = total_logical_reads ,
                    [total_writes] = total_logical_writes ,
					
                    [Objeto] = OBJECT_NAME(QP.objectid) ,
                    
                    [Plano Execução] = QP.query_plan
                FROM sys.dm_exec_query_stats AS QS
                CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
                CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) AS QP
                WHERE DB_NAME(ST.dbid) = DB_NAME(DB_ID())
             ),
        Projecao
          AS ( SELECT R.[Banco de Dados] ,
				R.Objeto ,
				 [Query] = R.Request ,
                    [Quantidade Execucao] = R.execution_count ,
					[Ultima Execucao] = R.last_execution_time,
                    R.last_logical_reads ,
					[last_logical_reads MB] = CONCAT(( ( R.last_logical_reads* 8 ) / 1024 ),' MB') ,
				    [Memoria Reservada] =	R.last_grant_kb,
					 [Memoria Utilizada] = R.last_used_grant_kb,
					 [Memoria Ideal] = R.last_ideal_grant_kb,
					
					[Tempo elapsed /Seg] = CAST(( CAST(R.last_elapsed_time AS DECIMAL(18,
                                                              6))
                                                         / CAST(1000000 AS DECIMAL(18,
                                                              6)) ) AS DECIMAL(18,
                                                              6)) ,
					
					[Media Tempo/Seg] = CAST(( CAST(R.[AVG TIME]  AS DECIMAL(18,
                                                              6))
                                                         / CAST(1000000 AS DECIMAL(18,
                                                              6)) ) AS DECIMAL(18,
                                                              6)) ,
					[Tempo CPU/Seg] = CAST(( CAST(R.[AVG CPU]  AS DECIMAL(18,
                                                              6))
                                                         / CAST(1000000 AS DECIMAL(18,
                                                              6)) ) AS DECIMAL(18,
                                                              6)) ,
					R.[AVG READ] ,
                    R.[AVG WHITE] ,
                    [Total Paginas Lidas] = R.total_logical_reads ,
                    [Total MB ((total_logical_reads * 8) / 1024)] = CONCAT(( ( R.total_logical_reads* 8 ) / 1024 ),' MB') ,
                    R.[Plano Execução]
                FROM Dados R
             )
    SELECT  R.[Banco de Dados],
            R.Objeto,
            R.Query,
            R.[Quantidade Execucao],
            R.[Ultima Execucao],
            R.last_logical_reads,
            R.[last_logical_reads MB],
            R.[Memoria Reservada],
            R.[Memoria Utilizada],
            R.[Memoria Ideal],
            R.[Tempo elapsed /Seg],
            R.[Media Tempo/Seg],
            R.[Tempo CPU/Seg],
            R.[AVG READ],
            R.[AVG WHITE],
            R.[Total Paginas Lidas],
            R.[Total MB ((total_logical_reads * 8) / 1024)],
            R.[Plano Execução]
			
        FROM Projecao R
   ORDER BY R.[Media Tempo/Seg] DESC OFFSET 0 ROW FETCH NEXT @Quantidade ROWS ONLY




   

