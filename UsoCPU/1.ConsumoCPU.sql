DECLARE @ms_ticks_now BIGINT

SELECT @ms_ticks_now = ms_ticks
FROM sys.dm_os_sys_info;

/* ==================================================================
--Data: 12/09/2018 
--Autor :Wesley Neves
--Observação: Os gargalos da CPU são causados ??por recursos de hardware insuficientes. 
  A solução de problemas começa com a identificação dos maiores usuários de recursos da CPU. 
  Picos ocasionais no uso do processador podem ser ignorados, 
  mas se o processador estiver constantemente sob pressão, a investigação é necessária.
 

 2) 
 Adicionar processadores adicionais ou usar um processador mais poderoso pode não resolver o problema,
  pois processos mal projetados sempre podem usar todo o tempo da CPU. O ajuste de consulta, 
 a melhoria dos planos de execução e a reconfiguração do sistema podem ajudar

 3)Para evitar afunilamentos, é recomendável ter um servidor dedicado que execute somente o SQL Server 
 e remova todos os outros softwares para outra máquina
 https://logicalread.com/troubleshoot-high-cpu-sql-server-pd01/#.W4aMQOhKhPY
https://blogs.msdn.microsoft.com/docast/2017/07/30/sql-high-cpu-troubleshooting-checklist/
-- ==================================================================
*/

-- ==================================================================
;WITH Dados AS (
SELECT TOP 60 record_id
	,dateadd(ms, - 1 * (@ms_ticks_now - [timestamp]), GetDate()) AS EventTime
	,SQLProcessUtilization
	,SystemIdle
	,100 - SystemIdle - SQLProcessUtilization AS OtherProcessUtilization
FROM (
	SELECT record.value('(./Record/@id)[1]', 'int') AS record_id
		,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle
		,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilization
		,TIMESTAMP
	FROM (
		SELECT TIMESTAMP
			,convert(XML, record) AS record
		FROM sys.dm_os_ring_buffers
		WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
			AND record LIKE '%<SystemHealth>%'
		) AS x
	) AS y
)
SELECT R.record_id,
       R.EventTime,
       R.SQLProcessUtilization,
       R.SystemIdle,
       R.OtherProcessUtilization
	   --[% Outros Proc] =  ( R.OtherProcessUtilization / 100.0 ) *100.0 
	    FROM Dados R
ORDER BY R.EventTime DESC


--(((R.Preco / R.[Total Geral dos Preços]) * 100)