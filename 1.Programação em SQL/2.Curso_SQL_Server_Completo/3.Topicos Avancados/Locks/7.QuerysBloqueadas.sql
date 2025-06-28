

DECLARE @programName VARCHAR(50) = 'SISCONT';

SET TRAN ISOLATION LEVEL READ UNCOMMITTED

SELECT [Banco] = DB_NAME(Bloqueado.database_id),
       'Informação do Bloqueio' AS Bloqueado,
       [Sessão Bloqueada] = DOWT.session_id,
       [Duracao Bloqueio] = CONVERT(TIME, DATEADD(ms, Bloqueado.total_elapsed_time, 0)),
       [Descrição do Lock] = DOWT.resource_description,
       Bloqueado.status,
       [Tipo Comando Bloqueado] = Bloqueado.command,
       [Query Bloqueada] = Q.text,
       [Plano Bloqueado] = PlanoBloqueado.query_plan,
       'Informação de quem esta bloqueando' AS Bloqueando,
       [Sessão Bloqueando] = DOWT.blocking_session_id,
       [Wait_type] = DOWT.wait_type,
       Bloqueado.transaction_id,
       [Tipo de transacao] = CASE
                                  WHEN trBloqueando.transaction_type = 1 THEN 'Transação de leitura/gravação'
                                  WHEN trBloqueando.transaction_type = 2 THEN 'Transação somente leitura'
                                  WHEN trBloqueando.transaction_type = 3 THEN 'Transação de sistema'
                                  WHEN trBloqueando.transaction_type = 4 THEN 'Transação distribuída' END,
       [Nome transacao] = trBloqueando.name,
       [Status Transacao] = CASE
                                 WHEN trBloqueando.transaction_state = 0 THEN
                                     'A transação não foi completamente inicializada ainda.'
                                 WHEN trBloqueando.transaction_state = 1 THEN
                                     'A transação foi inicializada mas não foi iniciada.'
                                 WHEN trBloqueando.transaction_state = 2 THEN 'A transação está ativa'
                                 WHEN trBloqueando.transaction_state = 3 THEN
                                     'A transação foi encerrada. Isso é usado para transações somente leitura.'
                                 WHEN trBloqueando.transaction_state = 4 THEN
                                     'O processo de confirmação foi iniciado na transação distribuída. Destina-se somente a transações distribuídas. A transação distribuída ainda está ativa, mas não poderá mais ser realizado o processamento.'
                                 WHEN trBloqueando.transaction_state = 5 THEN
                                     'A transação está em um estado preparado e aguardando resolução.'
                                 WHEN trBloqueando.transaction_state = 6 THEN 'a transação foi confirmada.'
                                 WHEN trBloqueando.transaction_state = 7 THEN 'A transação está sendo revertida.'
                                 WHEN trBloqueando.transaction_state = 7 THEN 'A transação foi revertida.' END,
       InfBloqueando.hostname,
       InfBloqueando.program_name,
       InfBloqueando.cmd,
       InfBloqueando.nt_username,
       InfBloqueando.loginame,
       InfBloqueando.text,
       Bloqueado.language,
       Bloqueado.arithabort,
       Bloqueado.lock_timeout,
       Bloqueado.statement_sql_handle
  FROM sys.dm_os_waiting_tasks AS DOWT
  JOIN sys.dm_exec_requests AS Bloqueado
    ON DOWT.session_id = Bloqueado.session_id
  JOIN sys.dm_tran_active_transactions trBloqueando
    ON trBloqueando.transaction_id = Bloqueado.transaction_id
  JOIN (   SELECT [Sessao Bloqueando] = S.spid,
                  [Banco] = S.dbid,
                  S.open_tran,
                  S.hostname,
                  S.program_name,
                  S.cmd,
                  S.nt_username,
                  S.loginame,
                  Q.text
             FROM sys.sysprocesses AS S
            CROSS APPLY sys.dm_exec_sql_text(S.sql_handle) Q
            WHERE S.dbid = DB_ID()
              AND Q.dbid =  DB_ID()) AS InfBloqueando
    ON InfBloqueando.Banco = Bloqueado.database_id
   AND InfBloqueando.[Sessao Bloqueando] = Bloqueado.blocking_session_id
 CROSS APPLY sys.dm_exec_sql_text(Bloqueado.sql_handle) Q
 CROSS APPLY sys.dm_exec_query_plan(Bloqueado.plan_handle) AS PlanoBloqueado
 WHERE DOWT.blocking_session_id > 0;


