/* ==================================================================
--Data: 06/05/2019 
--Autor :Wesley Neves
--Observação: Querys sendo rodas agora
 
-- ==================================================================
*/


SELECT [DB] = DB_NAME(Pro.dbid),
       Pro.spid,
	   [s_est].text,
       [Processo Bloqueado] = IIF(Pro.blocked =0,'Não','Sim'),
       Pro.waittime,
       Pro.lastwaittype,
       Pro.cpu,
       Pro.physical_io,
       Pro.memusage,
       Pro.login_time,
       [Ultima Execução] = Pro.last_batch,
       [Transação Aberta] = Pro.open_tran,
       [Status Sessao] = Pro.status,
       Pro.hostname,
       Pro.hostprocess,
       Pro.cmd,
       Pro.loginame,
       Pro.stmt_start,
       Pro.stmt_end
  FROM sys.sysprocesses Pro
   OUTER APPLY sys.dm_exec_sql_text(Pro.sql_handle) AS [s_est]
 WHERE
 Pro.dbid = DB_ID() AND
 Pro.spid <> @@SPID
 AND 
 s_est.text NOT LIKE '%SERVERPROPERTY%'
 ORDER BY  s_est.text



 
