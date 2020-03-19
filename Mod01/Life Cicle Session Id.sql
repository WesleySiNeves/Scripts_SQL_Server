

/*master : Conexão estabelecida: sys.dm_exec_connections*/
SELECT 'Conexão',
       *
FROM sys.dm_exec_connections AS DEC
WHERE DEC.session_id = @@SPID;

/*master : ID da sessão atribuída: sys.dm_exec_sessions*/
SELECT * FROM sys.dm_exec_sessions AS DES
WHERE DES.session_id = @@SPID


/*master : Solicitação criada: sys.dm_exec_requests */

SELECT * FROM sys.dm_exec_requests AS DER
WHERE DER.session_id = @@SPID


/*master : Tarefa (s) criada (s): sys.dm_os_tasks*/
SELECT 'Task',
       *
FROM sys.dm_os_tasks AS DOT
WHERE DOT.session_id = @@SPID;



/*master : Tarefa atribuída ao trabalhador: sys.dm_os_workers*/
SELECT 'workers',
       *
FROM sys.dm_os_workers AS DOW
WHERE DOW.worker_address = (
                           SELECT DOT.worker_address
                           FROM sys.dm_os_tasks AS DOT
                           WHERE DOT.session_id = @@SPID
                           );


/*master : Trabalhador é executado no encadeamento do sistema operacional: sys.dm_os_threads*/
SELECT  'threads',*
FROM sys.dm_os_threads AS DOT
WHERE DOT.worker_address = (
                           SELECT DOW.worker_address
                           FROM sys.dm_os_workers AS DOW
                           WHERE DOW.worker_address = (
                                                      SELECT DOT.worker_address
                                                      FROM sys.dm_os_tasks AS DOT
                                                      WHERE DOT.session_id = @@SPID
                                                      )
                           );


/*master :  O Scheduler gerencia a atividade da tarefa: sys.dm_os_schedulers*/
SELECT *
FROM sys.dm_os_schedulers AS DOS
WHERE DOS.active_worker_address = (
                                  SELECT DOW.worker_address
                                  FROM sys.dm_os_workers AS DOW
                                  WHERE DOW.worker_address = (
                                                             SELECT DOT.worker_address
                                                             FROM sys.dm_os_tasks AS DOT
                                                             WHERE DOT.session_id = @@SPID
                                                             )
                                  );