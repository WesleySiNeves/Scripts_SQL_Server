
/* Retorna informações sobre cada solicitação sendo executada no SQL Server.*/

SELECT DER.session_id,
       DER.start_time,
       DER.status,
       DER.command,
       DER.sql_handle,
       DER.statement_start_offset,
       DER.statement_end_offset,
       DER.plan_handle,
       DER.database_id,
       DER.wait_type,
       DER.wait_time
FROM sys.dm_exec_requests AS DER
WHERE DER.session_id > 50;


/*Retorna uma linha para cada tarefa que está ativa na instância do SQL Server.*/
SELECT DOT.session_id ,* FROM sys.dm_os_tasks AS DOT
WHERE DOT.session_id IS NOT NULL
AND DOT.session_id >50
ORDER BY DOT.session_id


/*Retorna uma linha por agendador no SQL Server, onde cada agendador é mapeado para um processador individual. Use esta exibição para monitorar a condição de um agendador ou para identificar tarefas sem controle*/
SELECT * FROM sys.dm_os_schedulers AS DOS

WHERE DOS.scheduler_id IN (0,1,2)


/* : Retorna informações sobre a fila de espera de tarefas que estão esperando algum recurso.*/
SELECT * FROM  sys.dm_os_waiting_tasks AS DOWT



