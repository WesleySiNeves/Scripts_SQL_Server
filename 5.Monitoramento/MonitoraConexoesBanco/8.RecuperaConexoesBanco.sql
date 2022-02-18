SELECT Pro.dbid,
       COUNT(*)
FROM sys.sysprocesses Pro
WHERE Pro.dbid NOT IN ( 1, 2, 3, 4, 5 )
GROUP BY
    Pro.dbid
ORDER BY
    Pro.dbid;





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
 --Pro.dbid = 6 AND
 Pro.spid <> @@SPID
 AND 
 s_est.text NOT LIKE '%SERVERPROPERTY%'
 ORDER BY  Pro.physical_io

 