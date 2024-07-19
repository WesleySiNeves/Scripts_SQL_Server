USE Implanta
/* ==================================================================
--Data: 15/10/2018 
--Autor :Wesley Neves
--Observação: Aqui temos as informações de sessões, algumas configurações utilizadas
-- tempo de querys
 
-- ==================================================================
*/

SELECT DB_NAME(S.database_id) AS DB,
       S.session_id,
       S.login_time,
       S.host_name,
       --S.program_name,
       --S.client_interface_name,
       --S.login_name,
       --S.nt_domain,
       S.nt_user_name,
       S.status,
       S.cpu_time,
       S.memory_usage,
       S.total_scheduled_time,
       S.total_elapsed_time,
       S.endpoint_id,
       DATEDIFF(MILLISECOND, S.last_request_start_time, S.last_request_end_time) AS TempMS,
       -- S.last_request_start_time,
       --S.last_request_end_time,
       S.reads,
       S.writes,
       S.logical_reads,
       --S.text_size,
       --S.language,
       --S.transaction_isolation_level,
       S.lock_timeout,
       S.row_count,
       S.open_transaction_count
FROM sys.dm_exec_sessions S
WHERE S.is_user_process = 1
    --  AND S.program_name = 'Microsoft SQL Server Management Studio - Query'
      AND S.session_id <> @@SPID
ORDER BY
    S.session_id DESC;

	


/* ==================================================================
--Data: 15/10/2018 
--Autor :Wesley Neves
--Observação: Aqui temos informacoes de sessoes e querys que foram executadas recentemente com o custo de cada uma
--  Mostre a diferença do separador de lote GO
 
-- ==================================================================
*/

SELECT DB_NAME(S.database_id) AS DB,
       S.session_id,
       DATEDIFF(MINUTE,S.login_time,GETDATE()) AS ConexaoAbertaMinutos,
       S.host_name,
       S.nt_user_name,
       S.status,
       S.cpu_time,
      -- S.memory_usage,
       S.total_scheduled_time,
       S.total_elapsed_time,
       S.reads,
       S.writes,
       S.logical_reads,
       S.lock_timeout,
       S.row_count,
       S.open_transaction_count,
	   DEC.net_transport,
	   DEC.protocol_type,
	   DEC.node_affinity,
	  UltimaQuery =  DEST.text
	
FROM sys.dm_exec_sessions S
JOIN sys.dm_exec_connections AS DEC ON S.session_id = DEC.session_id
JOIN sys.dm_exec_requests AS DER ON DEC.session_id = DER.session_id
OUTER APPLY sys.dm_exec_sql_text(DEC.most_recent_sql_handle) AS DEST


WHERE S.is_user_process = 1
   
      AND S.session_id <> @@SPID
ORDER BY
    S.session_id DESC;


SELECT DER.* FROM sys.dm_exec_requests AS DER

SELECT * FROM sys.dm_exec_query_stats AS DEQS


/* ==================================================================
--Data: 15/10/2018 
--Autor :Wesley Neves
--Observação: Aqui temos alguns  insides
 
-- ==================================================================
*/
SELECT DES.host_name AS Maquina,
       COUNT(DES.host_name) TotalConexaoPorMaquina
FROM sys.dm_exec_sessions AS DES
WHERE DES.session_id > 50
      AND DES.login_name <> 'sa'
GROUP BY
    DES.host_name;


SELECT DES.program_name AS Software,
       COUNT(DES.host_name) TotalConexaoPorSistema
FROM sys.dm_exec_sessions AS DES
WHERE DES.session_id > 50
      AND DES.login_name <> 'sa'
GROUP BY
    DES.program_name;



SELECT Des.status ,
       COUNT(*) AS TotaisSessoes
FROM sys.dm_exec_sessions Des
WHERE Des.session_id > 50
      AND Des.login_name <> 'sa'
GROUP BY
    Des.status;

	