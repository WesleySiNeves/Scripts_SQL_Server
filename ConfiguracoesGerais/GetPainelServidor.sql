DECLARE @jobcount BIGINT;
DECLARE @processorcount INT;


USE msdb;
SELECT @jobcount = COUNT(DISTINCT sysjobs.job_id)
FROM dbo.sysjobs;

USE master;
SELECT @processorcount = COUNT(*)
FROM sys.dm_os_schedulers
WHERE dm_os_schedulers.is_online = 1
      AND dm_os_schedulers.scheduler_id < 255;
WITH Dados
  AS (SELECT 'Server' AS Titulo,
			 'Server Start time' AS Descricao,
             CONVERT(VARCHAR(20), sysprocesses.login_time) AS Valor,
             1 AS Grupo,
             1 AS Posicao
      FROM sys.sysprocesses
      WHERE sysprocesses.spid = 1
      UNION
      SELECT 'Server' AS Titulo,
			 'Server Instance Name' AS Descricao,
             @@SERVERNAME AS Valor,
             1 AS Grupo,
             2 AS Posicao
      UNION
      SELECT 'Server' AS Titulo, 
			'Product Version' AS Descricao,
             CONVERT(sysname, SERVERPROPERTY('ProductVersion')) AS Valor,
             1 AS Grupo,
             3 AS Posicao
      UNION
      SELECT 'Server' AS Titulo,
			 'Edição' AS Descricao,
             CONVERT(sysname, SERVERPROPERTY('edition')) AS Valor,
             1 AS Grupo,
             4 AS Posicao
      UNION
      SELECT  'Server' AS Titulo,
			 'Schelds Jobs' AS Descricao,
             CONVERT(NVARCHAR(20), @jobcount) AS Valor,
             1 AS Grupo,
             5 AS Posicao
      UNION
      SELECT 'Configurações' AS Titulo,
			'Collation' AS Descricao,
             CONVERT(sysname, SERVERPROPERTY('collation')) AS Valor,
             2 AS Grupo,
             1 AS Posicao
      FROM sys.sysprocesses
      WHERE sysprocesses.spid = 1
      UNION
      SELECT 'Configurações' AS Titulo, 
		    'IsClustered' AS Descricao,
             CASE
                 WHEN CONVERT(sysname, SERVERPROPERTY('IsClustered')) = '0' THEN
                     'No'
                 ELSE
                     'Yes'
             END AS Valor,
             2 AS Grupo,
             2 AS Posicao
      UNION
      SELECT 'Configurações' AS Titulo, 
			'FullTextInstalled' AS Descricao,
             CASE
                 WHEN CONVERT(sysname, SERVERPROPERTY('IsFullTextInstalled')) = '0' THEN
                     'No'
                 ELSE
                     'Yes'
             END AS Valor,
             2 AS Grupo,
             3 AS Posicao
      UNION
      SELECT 'Configurações' AS Titulo, 
			'IsIntegratedSecurityOnly' AS Descricao,
             CASE
                 WHEN CONVERT(sysname, SERVERPROPERTY('IsIntegratedSecurityOnly')) = '0' THEN
                     'No'
                 ELSE
                     'Yes'
             END AS Valor,
             2 AS Grupo,
             4 AS Posicao
      UNION
      SELECT 'Configurações' AS Titulo,
			 'processor count' AS Descricao,
             CONVERT(NVARCHAR(20), @processorcount) AS Valor,
             2 AS Grupo,
             5 AS Posicao
UNION
SELECT 
'Atividade' AS Titulo,
'Active Session' AS  Descricao,
      CONVERT( VARCHAR(5), COUNT(1)) AS Valor,
	   Grupo  =3,
	   Posicao  =1
FROM sys.dm_exec_sessions s
WHERE s.is_user_process = 1
      AND s.status = 'running'
UNION
SELECT 
'Atividade' AS Titulo,
'Clients Transactions Open',
      CONVERT( VARCHAR(5), COUNT(1)) AS Valor,
	   Grupo  =3,
	   Posicao  =2
FROM sys.sysprocesses AS S
WHERE S.open_tran = 1
UNION
SELECT
'Atividade' AS Titulo,
 'Active Databases',
       CONVERT( VARCHAR(5),COUNT(1)) AS Valor,
	   Grupo  =3,
	   Posicao  =3
FROM sys.databases
WHERE databases.state = 0
UNION
SELECT 
'Atividade' AS Titulo,
'Sessions in Idle',
      CONVERT( VARCHAR(5), COUNT(1)) AS Valor,
	   Grupo  =3,
	   Posicao  =4
FROM sys.dm_exec_sessions
WHERE dm_exec_sessions.is_user_process = 1
      AND dm_exec_sessions.status = 'sleeping'
     )
SELECT *
FROM Dados R
ORDER BY
    R.Grupo,
    R.Posicao;


