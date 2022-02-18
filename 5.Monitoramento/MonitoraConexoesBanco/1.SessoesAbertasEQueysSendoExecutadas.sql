
 
;WITH ConnectionsSessions AS
(
SELECT C.session_id,
        C.connect_time,
        S.login_time,
        S.login_name,
        C.net_transport,
        C.num_reads,
        C.last_read,
        C.num_writes,
        C.last_write,
        C.client_net_address,
        C.most_recent_sql_handle,
        S.status,
        CASE WHEN S.status = 'Running' THEN 'Executando Uma ou Mais Requisições'
                WHEN S.status = 'Sleeping' THEN 'Executando Sem Requisições'
                WHEN S.status = 'Dormant' THEN 'Reiniciada pelo Pool de Conexões' ELSE S.status END ASTipoStatus,
        S.cpu_time,
        S.memory_usage,
        S.reads,
        S.logical_reads,
        S.writes,
        CASE WHEN S.transaction_isolation_level = 0 THEN 'Não Especificado'
                WHEN S.transaction_isolation_level = 1 THEN 'Read Uncomitted'
                WHEN S.transaction_isolation_level = 2 THEN 'Read Committed'
                WHEN S.transaction_isolation_level = 3 THEN 'Repeatable'
                WHEN S.transaction_isolation_level = 4 THEN 'Serializable'
                WHEN S.transaction_isolation_level = 5 THEN 'Snapshot' END AS TipoIsolationLevel,
        S.last_request_start_time,
        S.last_request_end_time,
        program_name
FROM sys.dm_exec_connections AS C
INNER JOIN sys.dm_exec_sessions AS S
ON C.session_id = S.session_id

)
SELECT C.session_id ,
       C.connect_time ,
	   C.logical_reads ,
       C.login_time ,
       C.login_name ,
	 [Query Mais Recente] =  Query.text,
       C.net_transport ,
       C.num_reads ,
       C.last_read ,
       C.num_writes ,
       C.last_write ,
       C.client_net_address ,
       --C.most_recent_sql_handle ,
       C.status ,
       C.ASTipoStatus ,
       C.cpu_time ,
       C.memory_usage ,
       C.reads ,
       
       C.writes ,
       C.TipoIsolationLevel ,
       C.last_request_start_time ,
       C.last_request_end_time ,
       C.program_name
FROM ConnectionsSessions C

CROSS APPLY (
SELECT Qu.dbid ,
       Qu.objectid ,
       Qu.number ,
       Qu.encrypted ,
       Qu.text
FROM sys.dm_exec_sql_text(c.most_recent_sql_handle) Qu
WHERE Qu.text NOT LIKE '%EDITION%'
) AS Query
WHERE C.program_name ='crea-sp.implanta.net.br'
AND Query.text NOT LIKE '%HangFire%'
ORDER BY [Query Mais Recente] DESC


SELECT U.*,P.NomeRazaoSocial FROM  Cadastro.Pessoas AS P
JOIN  Acesso.Usuarios AS U ON P.IdPessoa = U.IdPessoa
WHERE U.IdPessoa ='00000000-0000-0000-0000-000000000001'
ORDER BY P.IdPessoa DESC


SELECT L.*,P.NomeRazaoSocial FROM  Log.Logs AS L
JOIN Cadastro.Pessoas AS P ON L.IdPessoa = P.IdPessoa
WHERE CAST(L.Data AS DATE) = CAST(GETDATE() AS DATE)
AND L.Entidade  ='Contabilidade.ArquivosIntegracao'
 

SELECT * FROM Acesso.Usuarios AS U
WHERE U.IdUsuario ='00000000-0000-0000-0000-000000000001'


