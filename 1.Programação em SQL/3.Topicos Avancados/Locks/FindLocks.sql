SELECT DB_NAME(LOCK.rsc_dbid) AS 'DATABASE_NAME',
       CASE LOCK.rsc_type WHEN 1 THEN 'null'
       WHEN 2 THEN 'DATABASE'
       WHEN 3 THEN 'FILE'
       WHEN 4 THEN 'INDEX'
       WHEN 5 THEN 'TABLE'
       WHEN 6 THEN 'PAGE'
       WHEN 7 THEN 'KEY'
       WHEN 8 THEN 'EXTEND'
       WHEN 9 THEN 'RID ( ROW ID)'
       WHEN 10 THEN 'APPLICATION' END AS 'REQUEST_TYPE',
       CASE LOCK.req_ownertype WHEN 1 THEN 'TRANSACTION'
       WHEN 2 THEN 'CURSOR'
       WHEN 3 THEN 'SESSION'
       WHEN 4 THEN 'ExSESSION' END AS 'REQUEST_OWNERTYPE',
       OBJECT_NAME(LOCK.rsc_objid, LOCK.rsc_dbid) AS 'OBJECT_NAME',
       PROCESS.hostname,
       PROCESS.program_name,
       PROCESS.nt_domain,
       PROCESS.nt_username,
       PROCESS.program_name,
       SQLTEXT.text
  FROM sys.syslockinfo LOCK
       JOIN sys.sysprocesses PROCESS ON LOCK.req_spid = PROCESS.spid
       CROSS APPLY sys.dm_exec_sql_text(PROCESS.sql_handle) SQLTEXT

 -- WHERE OBJECT_NAME(LOCK.rsc_objid, LOCK.rsc_dbid) IS NOT NULL
 WHERE
    SQLTEXT.text NOT LIKE '%HangFire%';
