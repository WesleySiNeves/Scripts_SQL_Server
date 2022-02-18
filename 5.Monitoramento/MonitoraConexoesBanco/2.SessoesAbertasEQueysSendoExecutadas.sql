

/* ==================================================================
--Data: 10/09/2018 
--Autor :Wesley Neves
--Observação: Ultimos Scripts Executados no banco V1
 
-- ==================================================================
*/

SELECT  client_net_address AS [IP do cliente] ,
        p.hostname AS [Nome da máquina do cliente] ,
        [text] AS [Texto da consulta] ,
        DB_NAME(p.dbid) AS [Nome do BD no qual foi executada a query] ,
        p.[program_name] AS [Programa solicitante],
		p.login_time as [Data Login],
		p.nt_domain as [Dominio]
		
FROM    sys.dm_exec_connections c
        INNER JOIN sys.sysprocesses p ON c.session_id = p.spid
        CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST
		WHERE p.program_name ='crea-sp.implanta.net.br'
		AND ST.text NOT LIKE '%HangFire%'
